# frozen_string_literal: true

require 'sinatra/base'

# Simple Sinatra app to keep the bot alive on platforms like Render.com
class KeepAlive < Sinatra::Base
  set :port, ENV['PORT'] || 4567
  set :bind, '0.0.0.0'

  get '/' do
    'Bot is alive! ✅'
  end
end

# Start the server in a separate thread
Thread.new do
  KeepAlive.run!
end

puts "🌐 KeepAlive server started on port #{ENV['PORT'] || 4567}"
