class Tape

  BLANK = '#'

  attr_reader :head_position

  def initialize(options = {} )
    @head_position = options[:head_position].to_i
    @content       = (options[:content].to_s.empty?) ? [BLANK]: options[:content].split("")
  end

  def write(symbol)
    @content[@head_position] = symbol
  end

  def read
    @content[@head_position] || BLANK
  end

  def move_left
    raise StandardError, 'The machine moved off the left-hand of the tape!' if @head_position == 0
    @head_position -= 1
  end

  def move_right
    @head_position += 1
  end

  def reset
    @content = [BLANK]
    @head_position = 0
  end

  def dup
    Tape.new({head_position: @head_position, content: @content.dup.join})
  end
end
