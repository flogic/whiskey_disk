require 'rinda/tuplespace'

class Barrier
  attr_reader :name, :ts
  def initialize(ts, number_of_clients, name=nil)
    @ts = ts
    @name = name || self
    start(number_of_clients)
  end

  def start(number_of_clients)
    return unless ts.read_all([name, nil]).empty?
    puts "start: writing [#{@name}, #{number_of_clients}]"
    @ts.write([@name, number_of_clients])
  end

  def sync
    puts "sync: taking [#{name}, nil]..."
    tmp, val = ts.take([name, nil])
    puts "sync: received value [#{tmp}, #{val}]"
    puts "sync: writing [#{name}, #{val - 1}]..."
    ts.write([name, val - 1])
    puts "sync: reading [#{name}, 0]..."
    ts.read([name, 0])
  end
end

def server?
  !! @server
end

if server?
  puts "Starting DRb server..."
  @ts = Rinda::TupleSpace.new
  DRb.start_service('druby://localhost:12345', @ts)
  puts DRb.uri
  DRb.thread.join
else
  puts "Connecting to DRb server..."
  DRb.start_service
  @ts = DRbObject.new_with_uri('druby://localhost:12345')
end

def wait_for(symbol, &block)
  barrier = Barrier.new(@ts, 2, symbol.to_s)
  yield
  barrier.sync
end
