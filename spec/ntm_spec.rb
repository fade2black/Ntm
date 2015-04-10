require 'spec_helper'

describe Ntm do

  it 'has a version number' do
    expect(Ntm::VERSION).not_to be nil
  end


  let(:default_ntm){Ntm.new}

  it "has instructions" do
    expect(subject).to respond_to(:instructions)
  end


  describe "Initially with no options" do
    it "creates Ntm with a single configuration in the queue" do
      expect(default_ntm.instance_variable_get(:@config_queue).size).to eq(1)
    end

    it "create a Ntm with the default configuration - state is 0, empty tape content, head position is 0" do
      expect(default_ntm.send(:deque_configuration).to_s).to eq("[q0]#{Tape::BLANK}")
    end
  end



  describe "Initially with options" do

    let(:ntm){Ntm.new(initial_state: 1, tape_content: "011101")}

    it "create a Ntm with an initial configuration - state is 0, tape content: 011101, head position is 0" do
      expect(default_ntm.send(:deque_configuration).to_s).to eq("[q0]#{Tape::BLANK}")
    end
  end



  describe "Add an instruction" do

    let(:given) { {state: 0, symbol: '1'} }
    let(:transition) { {state: 1, symbol: '0', move: :left} }

    it "adds a single instruction" do
      expect { default_ntm.send(:add_instruction, given, transition) }.to change{default_ntm.instructions_count}.by(1)
    end

    it "adds three instructions" do
      expect { 3.times { default_ntm.send(:add_instruction, given, transition) }}.to change{default_ntm.instructions_count}.by(3)
    end

  end



  describe "Running a single instruction" do

    let(:instr){ {state:2, symbol:'1', move: :right} }
    let(:default_config) { Configuration.new }
    let(:config1) { Configuration.new(tape: Tape.new(head_position:0, content:"000101"), state: 1) }
    let(:config2) { Configuration.new(tape: Tape.new(head_position:4, content:"010"), state: 1) }

    it "runs instruction (q2, 1, R) on Ntm with BLANK tape content" do
      expect(default_ntm.send(:run_instruction, instr, default_config).to_s).to eq("1[q2]")
    end

    it "runs the instruction (q2, 1, R) with config [q1]00010" do
      expect(default_ntm.send(:run_instruction, instr, config1).to_s).to eq("1[q2]00101")
    end

    it "runs the instruction (q2, 1, R) with config 010#[q1]#" do
      expect(default_ntm.send(:run_instruction, instr, config2).to_s).to eq("010#1[q2]")
    end

  end



  describe "Running instructions 1 step" do

    describe "On default Ntm - state 0, BLANK tape content" do

      before(:example) do
        rule1 = { given:{state:0, symbol:Tape::BLANK}, instr:{state:2, symbol:'1', move: :right} }
        rule2 = { given:{state:0, symbol:Tape::BLANK}, instr:{state:0, symbol:Tape::BLANK, move: :right} }
        default_ntm.add_instruction(rule1[:given], rule1[:instr])
        default_ntm.add_instruction(rule2[:given], rule2[:instr])
      end

      it "has two configurations in the result array" do
        result = default_ntm.run({max_depth:1})
        expect(result[0].to_s + "  " + result[1].to_s).to eq("1[q2]  #{Tape::BLANK}[q0]")
      end
    end

  end



  describe "Writing 5 consecutive 1's" do
    before(:example) do
      rule = { given:{state:0, symbol:Tape::BLANK}, instr:{state:0, symbol:'1', move: :right} }
      default_ntm.add_instruction(rule[:given], rule[:instr])
    end

    it "has configuration 11111[q0] as a result" do
      result = default_ntm.run({max_depth:5})
      expect(result[0].to_s).to eq('11111[q0]')
    end
  end



  describe "Ntm generating 4 configurations" do

    ntm = Ntm.new(initial_state: 0)
    rules = [
      { given:{state:0, symbol:'0'}, instr:{state:1, symbol:'0', move: :right} },
      { given:{state:0, symbol:'0'}, instr:{state:1, symbol:'1', move: :right} },
      { given:{state:1, symbol:'1'}, instr:{state:2, symbol:'0', move: :right} },
      { given:{state:1, symbol:'1'}, instr:{state:2, symbol:'1', move: :right} } ]

    rules.each{ |rule| ntm.add_instruction(rule[:given], rule[:instr]) }
    result = ntm.run({max_depth:10, tape_content: "011" })

    it "has configuration 00[q2]1" do
      expect(result[0].to_s).to eq("00[q2]1")
    end

    it "has configuration 01[q2]1" do
      expect(result[1].to_s).to eq("01[q2]1")
    end

    it "has configuration 10[q2]1" do
      expect(result[2].to_s).to eq("10[q2]1")
    end

    it "has configuration 11[q2]1" do
      expect(result[3].to_s).to eq("11[q2]1")
    end

  end



  describe "Ntm (Dtm) accepting language {0^n1^n | n > 0 } - n 0's followed by n 1's" do

    ntm = Ntm.new(initial_state: 0)
    # accept state is 4
    rules = [
      { given:{state:0, symbol:'0'}, instr:{state:1, symbol:'X', move: :right} },
      { given:{state:0, symbol:'Y'}, instr:{state:3, symbol:'Y', move: :right} },

      { given:{state:1, symbol:'0'}, instr:{state:1, symbol:'0', move: :right} },
      { given:{state:1, symbol:'1'}, instr:{state:2, symbol:'Y', move: :left}  },
      { given:{state:1, symbol:'Y'}, instr:{state:1, symbol:'Y', move: :right}  },

      { given:{state:2, symbol:'0'}, instr:{state:2, symbol:'0', move: :left}  },
      { given:{state:2, symbol:'X'}, instr:{state:0, symbol:'X', move: :right}  },
      { given:{state:2, symbol:'Y'}, instr:{state:2, symbol:'Y', move: :left}  },

      { given:{state:3, symbol:'Y'}, instr:{state:3, symbol:'Y', move: :right}  },
      { given:{state:3, symbol:Tape::BLANK}, instr:{state:4, symbol:Tape::BLANK, move: :right}  }
      ]

      rules.each{ |rule| ntm.add_instruction(rule[:given], rule[:instr]) }

    it "accepts 0011" do
      result = ntm.run({max_depth:13, tape_content: "0011" })
      expect(result.first.to_s).to eq("XXYY#{Tape::BLANK}[q4]")
    end

    it "accepts 01" do
      ntm.reset
      result = ntm.run({max_depth:13, tape_content: "01" })
      expect(result.first.to_s).to eq("XY#{Tape::BLANK}[q4]")
    end

    it "does not accept 011" do
      ntm.reset
      result = ntm.run({max_depth:13, tape_content: "011" })
      expect(result.first.state).not_to eq(4)
    end

    it "does not accept 1100" do
      ntm.reset
      result = ntm.run({max_depth:13, tape_content: "1100" })
      expect(result.first.state).not_to eq(4)
    end

    it "does not accept 1" do
      ntm.reset
      result = ntm.run({max_depth:13, tape_content: "1" })
      expect(result.first.state).not_to eq(4)
    end

    it "does not accept 1" do
      ntm.reset
      result = ntm.run({max_depth:13, tape_content: "" })
      expect(result.first.state).not_to eq(4)
    end

    it "does not accept 1" do
      ntm.reset
      result = ntm.run({max_depth:13, tape_content: Tape::BLANK })
      expect(result.first.state).not_to eq(4)
    end
  end



  describe "Ntm (Dtm) accepting language {0^(2^n) | n >= 0 } " do

    ntm = Ntm.new(initial_state: 1)
    # accept state is 7, reject state is 6
    rules = [
      { given:{state:1, symbol:Tape::BLANK}, instr:{state:6, symbol:Tape::BLANK, move: :right} },
      { given:{state:1, symbol:'x'}, instr:{state:6, symbol:'x', move: :right} },
      { given:{state:1, symbol:'0'}, instr:{state:2, symbol:Tape::BLANK, move: :right} },

      { given:{state:2, symbol:'x'}, instr:{state:2, symbol:'x', move: :right} },
      { given:{state:2, symbol:Tape::BLANK}, instr:{state:7, symbol:Tape::BLANK, move: :right} },
      { given:{state:2, symbol:'0'}, instr:{state:3, symbol:'x', move: :right} },

      { given:{state:3, symbol:'0'}, instr:{state:4, symbol:'0', move: :right} },
      { given:{state:3, symbol:'x'}, instr:{state:3, symbol:'x', move: :right} },
      { given:{state:3, symbol:Tape::BLANK}, instr:{state:5, symbol:Tape::BLANK, move: :left} },

      { given:{state:4, symbol:'x'}, instr:{state:4, symbol:'x', move: :right} },
      { given:{state:4, symbol:'0'}, instr:{state:3, symbol:'x', move: :right} },
      { given:{state:4, symbol:Tape::BLANK}, instr:{state:6, symbol:Tape::BLANK, move: :right} },

      { given:{state:5, symbol:Tape::BLANK}, instr:{state:2, symbol:Tape::BLANK, move: :right} },
      { given:{state:5, symbol:'x'}, instr:{state:5, symbol:'x', move: :left} },
      { given:{state:5, symbol:'0'}, instr:{state:5, symbol:'0', move: :left} },
      ]

      rules.each{ |rule| ntm.add_instruction(rule[:given], rule[:instr]) }

      it "accepts 0000" do
        result = ntm.run({max_depth:50, tape_content: "0000" })
        expect(result.first.to_s).to eq("#{Tape::BLANK}xxx#{Tape::BLANK}[q7]")
      end

      it "does not accept 000" do
        ntm.reset
        result = ntm.run({max_depth:50, tape_content: "000" })
        expect(result.first.state).not_to eq(7)
      end

      it "accept 00" do
        ntm.reset
        result = ntm.run({max_depth:50, tape_content: "00" })
        expect(result.first.state).to eq(7)
      end

      it "accepts 0" do
        ntm.reset
        result = ntm.run({max_depth:50, tape_content: "0" })
        expect(result.first.state).to eq(7)
      end

      it "does not accept 0001" do
        ntm.reset
        result = ntm.run({max_depth:50, tape_content: "0001" })
        expect(result.first.state).not_to eq(7)
      end

      it "accepts 00000000" do
        ntm.reset
        result = ntm.run({max_depth:50, tape_content: "0" })
        expect(result.first.state).to eq(7)
      end
  end



  describe "Ntm with a single accept state 1" do

    ntm = Ntm.new(initial_state: 0)
    rules = [
      { given:{state:0, symbol:'0'}, instr:{state:1, symbol:'0', move: :right} },
      { given:{state:0, symbol:'0'}, instr:{state:1, symbol:'1', move: :right} },
      { given:{state:1, symbol:'1'}, instr:{state:2, symbol:'0', move: :right} },
      { given:{state:1, symbol:'1'}, instr:{state:2, symbol:'1', move: :right} } ]

    rules.each{ |rule| ntm.add_instruction(rule[:given], rule[:instr]) }
    result = ntm.run({max_depth:10, tape_content: "011", accept_states: [1] })

    it "has only two configurations" do
      expect(result.size).to be(2)
    end

    it "has configuration 0[q1]11" do
      expect(result[0].to_s).to eq("0[q1]11")
    end

    it "has configuration 1[q1]11" do
      expect(result[1].to_s).to eq("1[q1]11")
    end

  end


  describe "Adding instructions using DSL" do

    context "Ntm with a single accept state 1" do
      ntm = Ntm.new(initial_state: 0)

      ntm.given({state:0, symbol: '0'}) do
        transition(state:1, symbol:'0', move: :right)
        transition(state:1, symbol:'1', move: :right)
      end

      ntm.given({state:1, symbol: '1'}) do
        transition(state:2, symbol:'0', move: :right)
        transition(state:2, symbol:'1', move: :right)
      end

      result = ntm.run({max_depth:10, tape_content: "011", accept_states: [1] })

      it "has only two configurations" do
        expect(result.size).to be(2)
      end

      it "has configuration 0[q1]11" do
        expect(result[0].to_s).to eq("0[q1]11")
      end

      it "has configuration 1[q1]11" do
        expect(result[1].to_s).to eq("1[q1]11")
      end
    end

    context "Ntm (Dtm) accepting language {0^n1^n | n > 0 } - n 0's followed by n 1's" do

      ntm = Ntm.new(initial_state: 0)
      ntm.given({state:0, symbol:'0'}) { transition(state:1, symbol:'X', move: :right) }
      ntm.given({state:0, symbol:'Y'}) { transition(state:3, symbol:'Y', move: :right) }
      ntm.given({state:1, symbol:'0'}) { transition(state:1, symbol:'0', move: :right) }
      ntm.given({state:1, symbol:'1'}) { transition(state:2, symbol:'Y', move: :left)  }
      ntm.given({state:1, symbol:'Y'}) { transition(state:1, symbol:'Y', move: :right) }
      ntm.given({state:2, symbol:'0'}) { transition(state:2, symbol:'0', move: :left)  }
      ntm.given({state:2, symbol:'X'}) { transition(state:0, symbol:'X', move: :right) }
      ntm.given({state:2, symbol:'Y'}) { transition(state:2, symbol:'Y', move: :left)  }
      ntm.given({state:3, symbol:'Y'}) { transition(state:3, symbol:'Y', move: :right) }
      ntm.given({state:3, symbol:'#'}) { transition(state:4, symbol:'#', move: :right) }

      it "accepts 0011" do
        result = ntm.run({max_depth:13, tape_content: "0011" })
        expect(result.first.to_s).to eq("XXYY#{Tape::BLANK}[q4]")
      end

      it "accepts 01" do
        ntm.reset
        result = ntm.run({max_depth:13, tape_content: "01" })
        expect(result.first.to_s).to eq("XY#{Tape::BLANK}[q4]")
      end

      it "does not accept 011" do
        ntm.reset
        result = ntm.run({max_depth:13, tape_content: "011" })
        expect(result.first.state).not_to eq(4)
      end

      it "does not accept 1100" do
        ntm.reset
        result = ntm.run({max_depth:13, tape_content: "1100" })
        expect(result.first.state).not_to eq(4)
      end

      it "does not accept 1" do
        ntm.reset
        result = ntm.run({max_depth:13, tape_content: "1" })
        expect(result.first.state).not_to eq(4)
      end

      it "does not accept 1" do
        ntm.reset
        result = ntm.run({max_depth:13, tape_content: "" })
        expect(result.first.state).not_to eq(4)
      end

      it "does not accept 1" do
        ntm.reset
        result = ntm.run({max_depth:13, tape_content: Tape::BLANK })
        expect(result.first.state).not_to eq(4)
      end

    end
  end


  describe "Adding instructions on creating Ntm" do

    context "Ntm with a single accept state 1" do
      ntm = Ntm.new(initial_state: 0) do
        given({state:0, symbol: '0'}) do
          transition(state:1, symbol:'0', move: :right)
          transition(state:1, symbol:'1', move: :right)
        end

        given({state:1, symbol: '1'}) do
          transition(state:2, symbol:'0', move: :right)
          transition(state:2, symbol:'1', move: :right)
        end
      end

      result = ntm.run({max_depth:10, tape_content: "011", accept_states: [1] })

      it "has only two configurations" do
        expect(result.size).to be(2)
      end

      it "has configuration 0[q1]11" do
        expect(result[0].to_s).to eq("0[q1]11")
      end

      it "has configuration 1[q1]11" do
        expect(result[1].to_s).to eq("1[q1]11")
      end
    end

    context "Ntm (Dtm) accepting language {0^n1^n | n > 0 } - n 0's followed by n 1's" do

      ntm = Ntm.new(initial_state: 0) do
        given({state:0, symbol:'0'}) { transition(state:1, symbol:'X', move: :right) }
        given({state:0, symbol:'Y'}) { transition(state:3, symbol:'Y', move: :right) }
        given({state:1, symbol:'0'}) { transition(state:1, symbol:'0', move: :right) }
        given({state:1, symbol:'1'}) { transition(state:2, symbol:'Y', move: :left)  }
        given({state:1, symbol:'Y'}) { transition(state:1, symbol:'Y', move: :right) }
        given({state:2, symbol:'0'}) { transition(state:2, symbol:'0', move: :left)  }
        given({state:2, symbol:'X'}) { transition(state:0, symbol:'X', move: :right) }
        given({state:2, symbol:'Y'}) { transition(state:2, symbol:'Y', move: :left)  }
        given({state:3, symbol:'Y'}) { transition(state:3, symbol:'Y', move: :right) }
        given({state:3, symbol:'#'}) { transition(state:4, symbol:'#', move: :right) }
      end

      it "accepts 0011" do
        result = ntm.run({max_depth:13, tape_content: "0011" })
        expect(result.first.to_s).to eq("XXYY#{Tape::BLANK}[q4]")
      end

      it "accepts 01" do
        ntm.reset
        result = ntm.run({max_depth:13, tape_content: "01" })
        expect(result.first.to_s).to eq("XY#{Tape::BLANK}[q4]")
      end

      it "does not accept 011" do
        ntm.reset
        result = ntm.run({max_depth:13, tape_content: "011" })
        expect(result.first.state).not_to eq(4)
      end

      it "does not accept 1100" do
        ntm.reset
        result = ntm.run({max_depth:13, tape_content: "1100" })
        expect(result.first.state).not_to eq(4)
      end

      it "does not accept 1" do
        ntm.reset
        result = ntm.run({max_depth:13, tape_content: "1" })
        expect(result.first.state).not_to eq(4)
      end

      it "does not accept 1" do
        ntm.reset
        result = ntm.run({max_depth:13, tape_content: "" })
        expect(result.first.state).not_to eq(4)
      end

      it "does not accept 1" do
        ntm.reset
        result = ntm.run({max_depth:13, tape_content: Tape::BLANK })
        expect(result.first.state).not_to eq(4)
      end

    end


  end

end
