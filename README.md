# Ntm

Ntm simulates nondeterministic Turing machines. It may also be used to simulate deterministic Turing machines.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'ntm'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install ntm

## Ntm examples
#### Example 1
state|symbol|move
-----|------|--------
q<sub>0</sub>  |   0  |(q<sub>1</sub>,0,R), (q<sub>1</sub>,1,R) 
q<sub>1</sub>  |   1  |(q<sub>2</sub>,0,R), (q<sub>2</sub>,1,R)
```ruby
  require "ntm"
  
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

  configurations = ntm.run({max_depth:250, tape_content: "011" })

  configurations.each do |conf|
    conf.path.each do |p|
      instr = p[:instr]
      print p[:config] + " (#{instr[:state]},#{instr[:symbol]},#{instr[:move][0]}) => "
    end
    puts conf.to_s
  end
```
#### Output: four possible computations
 [q0]011 (1,0,r) => 0[q1]11 (2,0,r) => 00[q2]1
 
 [q0]011 (1,0,r) => 0[q1]11 (2,1,r) => 01[q2]1
 
 [q0]011 (1,1,r) => 1[q1]11 (2,0,r) => 10[q2]1
 
 [q0]011 (1,1,r) => 1[q1]11 (2,1,r) => 11[q2]1

#### Example 2: a deterministic TM accepting language the language {0<sup>n</sup>1<sup>n</sup> | n > 0 } - n 0s followed by n 1s
state|symbol|move
-----|------|--------
q<sub>0</sub>  |   0  |(q<sub>1</sub>,X,R)
q<sub>0</sub>  |   Y  |(q<sub>3</sub>,Y,R)
q<sub>1</sub>  |   0  |(q<sub>1</sub>,0,R)
q<sub>1</sub>  |   1  |(q<sub>2</sub>,Y,L)
q<sub>1</sub>  |   Y  |(q<sub>1</sub>,Y,R)
q<sub>2</sub>  |   0  |(q<sub>2</sub>,0,L)
q<sub>2</sub>  |   X  |(q<sub>0</sub>,X,R)
q<sub>2</sub>  |   Y  |(q<sub>2</sub>,Y,L)
q<sub>3</sub>  |   Y  |(q<sub>3</sub>,Y,R)
q<sub>3</sub>  |   #  |(q<sub>4</sub>,#,R)

Accept state: q<sub>4</sub>
```ruby
require "ntm"

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

configurations = ntm.run({max_depth:250, tape_content: "0011", accept_states:[4] })

configurations.each do |conf|
  conf.path.each do |p|
    instr = p[:instr]
    print p[:config] + " (#{instr[:state]},#{instr[:symbol]},#{instr[:move][0]}) => "
  end
  puts conf.to_s
end
```
#### Output
 [q0]0011 (1,X,r) => X[q1]011 (1,0,r) => X0[q1]11 (2,Y,l) => X[q2]0Y1 (2,0,l) => [q2]X0Y1 (0,X,r) => X[q0]0Y1 (1,X,r) => XX[q1]Y1 (1,Y,r) => XXY[q1]1 (2,Y,l) => XX[q2]YY (2,Y,l) => X[q2]XYY (0,X,r) => XX[q0]YY (3,Y,r) => XXY[q3]Y (3,Y,r) => XXYY[q3] (4,#,r) => XXYY#[q4]
## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release` to create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

1. Fork it ( https://github.com/[my-github-username]/ntm/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
