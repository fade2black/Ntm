#require "tape"

class Configuration
  attr_accessor :state, :tape, :depth, :path

  def initialize(options = {})
    @tape   = options[:tape] || Tape.new
    @state  = options[:state].to_i
    @depth = options[:depth].to_i || 1
    @path = []
  end

  def to_s
    conf = @tape.instance_variable_get(:@content).dup
    conf.insert(@tape.head_position, "[q#{@state}]").collect!{|e| e ? e : Tape::BLANK }.join
  end

  def dup
    conf = Configuration.new
    conf.state = @state
    conf.tape = @tape.dup
    conf.depth = @depth
    conf.path = @path.dup
    conf
  end
end
