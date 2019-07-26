# frozen_string_literal: true

require 'rack/lobster'
require 'concurrent'

$pool = Concurrent::ThreadPoolExecutor.new(min_threads: 2, max_threads: 2, auto_terminate: false)

at_exit {p 'Shutting down the threadpool'; $pool.shutdown}

2.times do
  $pool << proc {p 'Sleeping'; sleep}
end

use Rack::ShowExceptions
run Rack::Lobster.new
