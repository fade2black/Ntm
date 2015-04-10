require "ntm/version"
require 'ntm/tape'
require 'ntm/configuration'

class Ntm

  DEFAULT_MAX_DEPTH = 10
  #attr_reader :current_state
  attr_reader :instructions

  def initialize(options={}, &block)
    tape =  Tape.new(content: options[:tape_content], head_position: options[:head_position].to_i)
    @initial_state = options[:initial_state] || 0
    @initial_config = Configuration.new(state: @initial_state, tape: tape)
    #puts "initial state: #{initial_state}"
    @config_queue =  [@initial_config]
    @instructions =  {}
    @result_of_computation = []

    @input = nil

    instance_eval(&block) if block_given?
  end


  def transition(options)
    raise StandardError, 'Missing output state of the transition function!' unless options[:state]
    raise StandardError, 'Missing write-symbol of the transition function!' unless options[:symbol]
    raise StandardError, 'Missing head-move direction (right/left) of the transition function!' unless options[:move]

    add_instruction(@input, {state:options[:state], symbol:options[:symbol], move:options[:move]})
  end

  def given(options, &block)
    raise StandardError, 'Missing input state of the transition function!' unless options[:state]
    raise StandardError, 'Missing input symbol of the transition function!' unless options[:symbol]

    @input = { state:options[:state], symbol: options[:symbol] }
    instance_eval(&block)
  end



  def reset
    @config_queue = [@initial_config]
    @result_of_computation = []
  end


  # add a single instruction to the instructions set
  # instructions must be in the following format:
  #
  #    given is a hash       {state:1, symbol: '0'}
  #    transition is a hash  {state:2, symbol: '1', move: :right}
  #
  def add_instruction(given, transition)
    if instructions[given]
      instructions[given] << transition
    else
      instructions[given] = [transition]
    end
  end


  def instructions_count
    count = 0
    instructions.each_value { |instrs| count += instrs.size }
    count
  end


  def run(options = {})

    max_depth = options[:max_depth] || DEFAULT_MAX_DEPTH
    max_depth = max_depth.to_i
    accept_states = options[:accept_states] || []

    raise StandardError, 'Maximum depth must be a positive number!' unless max_depth > 0


    if  options[:tape_content] || options[:head_position]
      tape_content = options[:tape_content] || @initial_config.tape.content
      head_position = options[:head_position] || @initial_config.tape.head_position
      tape = Tape.new(content: tape_content, head_position: head_position.to_i)
      @config_queue =  [Configuration.new(state: @initial_state, tape: tape)]
    end

    loop do
      break if @config_queue.empty?

      config = deque_configuration

      if accept_states.include?(config.state)
        @result_of_computation << config.dup
        next
      end

      instrs = instructions[{state: config.state, symbol: config.tape.read}]
      if instrs == nil
        @result_of_computation << config.dup
        next
      end

      instrs.each do |instr|
        new_config = run_instruction(instr, config)
        # increase the depth
        new_config.depth = config.depth + 1
        # add the path
        new_config.path = config.path.dup << {instr:instr, config:config.to_s}
        #puts "#{new_config.depth} = #{new_config.to_s}"
        if new_config.depth >= max_depth
          @result_of_computation << new_config.dup
        else
          enque_configuration(new_config)
        end
      end
    end

    @result_of_computation.dup
  end




  def enque_configuration(config)
    @config_queue.push(config.dup)
  end


  def deque_configuration
    raise StandardError, 'Empty queue!' if @config_queue.size == 0
    @config_queue.delete_at(0)
  end

  # runs the instruction in context of the given configuration
  # generates a new configuration
  def run_instruction(instr, config)
    conf = config.dup
    # write a symbol to the tape
    conf.tape.write(instr[:symbol])
    # go to a new state
    conf.state = instr[:state]
    # move the tape-head
    if instr[:move] == :left
      conf.tape.move_left
    elsif instr[:move] == :right
      conf.tape.move_right
    else
      raise StandardError, 'Tape-head may move only Right or Left!'
    end

    conf
  end


  private :run_instruction, :enque_configuration, :deque_configuration
end
