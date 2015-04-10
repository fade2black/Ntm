require 'spec_helper'

describe Configuration do

  let(:empty_config) {Configuration.new}
  let(:config) { Configuration.new(tape: Tape.new(head_position:1, content:"110101"), state: 2) }

  it "has tape" do
    expect(subject).to respond_to(:tape)
  end

  it "has state" do
    expect(subject).to respond_to(:state)
  end



  describe "to_s method" do

    it "has to_s method" do
      expect(subject).to respond_to(:to_s)
    end

    it "converts configuration to a string" do
      expect(empty_config.to_s).to eq("[q0]#{Tape::BLANK}")
    end

    it "converts configuration to a string" do
      expect(config.to_s).to eq("1[q2]10101")
    end


  end

end
