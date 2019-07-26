# frozen_string_literal: true
require 'rack/lobster'

java_import java.util.concurrent.ThreadPoolExecutor
java_import java.lang.Runnable

# From https://github.com/ruby-concurrency/concurrent-ruby/blob/d11b29c37b81320ca7126cc9cd85f4f3d17a78a3/lib/concurrent/executor/java_thread_pool_executor.rb#L111-L117
$pool = java.util.concurrent.ThreadPoolExecutor.new(
    2,
    2,
    60,
    java.util.concurrent.TimeUnit::SECONDS,
    java.util.concurrent.LinkedBlockingQueue.new,
    java.util.concurrent.ThreadPoolExecutor::AbortPolicy.new
  )

# From concurrent-ruby: https://github.com/ruby-concurrency/concurrent-ruby/blob/d11b29c37b81320ca7126cc9cd85f4f3d17a78a3/lib/concurrent/executor/java_executor_service.rb#L77-L87
class Job
  include Runnable
  def initialize(args, block)
    @args = args
    @block = block
  end

  def run
    @block.call(*@args)
  end
end

existing_threads = Thread.list

2.times do
  $pool.submit Job.new(nil, proc{loop { bool = true; sleep 0.5 }})
end

at_exit do
  # Add 5 second wait
  deadline = Time.now + 5

  p 'Requesting threadpool shutdown'
  $pool.shutdown
  p 'Waiting until deadline'
  while true
    break if (Thread.list - existing_threads == [])
    # sleep 0.2
    if Time.now > deadline
      # This is never printed
      p 'Deadline is over. Killing the threadpool'
      $pool.shutdownNow
      break
    end
  end
end

use Rack::ShowExceptions
run Rack::Lobster.new
