# frozen_string_literal: true

require 'bundler/setup'
require 'ruby_llm'
require 'easy_talk'
require 'faraday'

# Example: Tools Integration
# Demonstrates using EasyTalk models as Tools for RubyLLM.
#
# To create a tool, inherit from RubyLLM::Tool and include EasyTalk::Model.
# This gives you:
# - Full access to RubyLLM::Tool features like halt()
# - EasyTalk's schema DSL for defining parameters
# - Automatic integration with RubyLLM's with_tool method

RubyLLM.configure do |config|
  config.openai_api_key = ENV.fetch('OPENAI_API_KEY', nil)
end

class Weather < RubyLLM::Tool
  include EasyTalk::Model

  define_schema do
    description 'Gets current weather for a location'
    property :latitude, String, description: 'Latitude (e.g., 52.5200)'
    property :longitude, String, description: 'Longitude (e.g., 13.4050)'
  end

  def execute(latitude:, longitude:)
    puts "Executing Weather Tool for #{latitude}, #{longitude}"
    url = "https://api.open-meteo.com/v1/forecast?latitude=#{latitude}&longitude=#{longitude}&current=temperature_2m,wind_speed_10m"
    response = Faraday.get(url)
    data = JSON.parse(response.body)
    data.to_s
  rescue StandardError => e
    { error: e.message }
  end
end

puts '--- Tools Integration Example ---'
puts

chat = RubyLLM.chat.with_tool(Weather)

puts 'User: What is the weather in Berlin (Lat: 52.52, Long: 13.405)?'
response = chat.ask 'What is the weather in Berlin (Lat: 52.52, Long: 13.405)?'

puts "Assistant: #{response.content}"
