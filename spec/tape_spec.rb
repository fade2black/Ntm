require 'spec_helper'

describe Tape do

  let(:default_tape) { Tape.new }

  describe "Initialization" do

    it "creates a tape with a single BLANK symbol" do
      expect(default_tape.instance_variable_get(:@content)).to eq([Tape::BLANK])
    end

    it "sets head position set to 0" do
      expect(default_tape.head_position).to eq(0)
    end

    context "with options" do
      let(:tape) { Tape.new(content: "011101", head_position: 2) }

      it "creates a tape with a non-BLANK content" do
        expect(tape.instance_variable_get(:@content).join).to eq("011101")
      end

      it "sets the head position to a certain position" do
        expect(tape.head_position).to eq(2)
      end

      it "creates a tape with a single BLANK symbol" do
        tape = Tape.new(content:"")
        expect(default_tape.instance_variable_get(:@content)).to eq([Tape::BLANK])
      end
    end

  end

  describe "write/read" do

    it "reads the BLANK symbol" do
      expect(default_tape.read).to eq(Tape::BLANK)
    end

    it "writes a symbol" do
      default_tape.write('0')
      expect(default_tape.read).to eq('0')
    end

  end



  describe "move-left" do

    it "raises exception when machine goes off the left-hand of the tape" do
      expect{default_tape.move_left}.to raise_error(StandardError, 'The machine moved off the left-hand of the tape!')
    end

    it "moves the tape-head left" do
      tape = Tape.new(head_position: 2)
      expect{tape.move_left}.to change{tape.instance_variable_get(:@head_position)}.by(-1)
    end

  end



  describe "move-right" do

    it "moves the tape-head right" do
      expect{default_tape.move_right}.to change{default_tape.instance_variable_get(:@head_position)}.by(1)
    end

  end



end
