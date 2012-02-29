require 'simplecov'
require './spec/mockcached'

SimpleCov.add_filter 'spec'
SimpleCov.add_filter 'config'
SimpleCov.start

$:.unshift(File.dirname(File.dirname(__FILE__)))

ENV["RACK_ENV"] = "test"
require 'config/environment'

require 'api/v1'

require 'rack/test'
require 'config/logging'
require 'timecop'

require 'vcr'
VCR.config do |c|
  c.cassette_library_dir = 'spec/fixtures/vcr_cassettes'
  c.stub_with :webmock 
end

set :environment, :test

# Run all examples in a transaction
RSpec.configure do |c|
  c.around(:each) do |example|
    clear_cookies if respond_to?(:clear_cookies)
    $memcached = Mockcached.new
    ActiveRecord::Base.connection.transaction do
      example.run 
      raise ActiveRecord::Rollback
    end
  end
end
