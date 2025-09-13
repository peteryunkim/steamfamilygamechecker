# frozen_string_literal: true

require 'sinatra/base'

# Simple Sinatra app to keep the bot alive on platforms like Render.com
class KeepAlive < Sinatra::Base
  set :allow_hosts, nil if ENV['RACK_ENV'] == 'test'
  get '/' do
    puts "[#{Time.now}] Ping received from #{request.ip}"
    "I'm alive!"
  end

  def self.start
    Thread.new do
      port = ENV['PORT'] || 4567
      KeepAlive.run! bind: '0.0.0.0', port: port
    end
  end
end
