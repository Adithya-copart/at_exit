# frozen_string_literal: true

require 'rack/lobster'
require 'concurrent'

existing_threads = Thread.list
$pool = Concurrent::ThreadPoolExecutor.new(min_threads: 2, max_threads: 2, auto_terminate: false)

# Add 10 second wait

deadline = Time.now + 10

# This is best I could mimic https://github.com/brandonhilkert/sucker_punch/blob/d06ba290be4d56fbbd45d37f73c47bd441ad0224/lib/sucker_punch/queue.rb#L74-L110
at_exit do
  p 'Requesting threadpool shutdown'
  $pool.shutdown
  p 'Waiting until deadline'
  while true
    break if (Thread.list - existing_threads == [])
    sleep 0.2
    if Time.now > deadline
      # This is never printed
      p 'Deadline is over. Killing the threadpool'
      $pool.kill && break
    end
  end

  # This is never printed
  p 'Done in at exit'
end

2.times do
  $pool << proc {loop { bool = true }}
end

use Rack::ShowExceptions
run Rack::Lobster.new
