# frozen_string_literal: true

require 'rack/test'
require_relative '../keep_alive'
require 'dotenv/load'

RSpec.describe KeepAlive do
  include Rack::Test::Methods

  def app
    KeepAlive
  end

  it 'responds to GET / with alive message' do
    get '/' 
    expect(last_response).to be_ok
    expect(last_response.body).to eq("I'm alive!")
  end
end
