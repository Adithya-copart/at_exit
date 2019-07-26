require 'concurrent'
require 'sinatra'

class AtExitApp < Sinatra::Base

  # Enabling this exit handler will not reproduce the problem.
  at_exit do
   trace = TracePoint.new do |tp|
      p [tp.path, tp.lineno, tp.method_id, tp.event]
    end

    trace.enable
  end

  # set :bind, '0.0.0.0'

  class TestJob

    $pool = Concurrent::ThreadPoolExecutor.new(min_threads: 2, max_threads: 2, auto_terminate: false)

    at_exit {p 'Shutting down the threadpool'; $pool.shutdown}

    def self.perform
      $pool << ->() {p 'Sleeping'; sleep}
    end
  end

  get '/' do
    2.times {TestJob.perform}
    'success'
  end

  Thread.new do
    sleep 1 # Wait for startup
    require 'net/http'
    Net::HTTP.get(URI 'http://0.0.0.0:4567/')

    # TERM works but INT doesn't kill the puma process.
    puts "Sending SIGINT.."
    Process.kill('INT', Process.pid) 
  end
end