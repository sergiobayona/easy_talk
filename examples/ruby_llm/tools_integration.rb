# frozen_string_literal: true

require 'bundler/setup'
require 'ruby_llm'
require 'easy_talk'
require 'faraday'

# Example: Tools Integration
# Demonstrates using EasyTalk models as Tools for RubyLLM.
RubyLLM.configure do |config|
  config.openai_api_key = ENV['OPENAI_API_KEY']
end

# 1. Define the Tool using EasyTalk
# Note: RubyLLM looks for a Tool class with an 'execute' method.

class Weather
  include EasyTalk::Model

  define_schema do
    description "Gets current weather for a location"
    property :latitude, String, description: "Latitude (e.g., 52.5200)"
    property :longitude, String, description: "Longitude (e.g., 13.4050)"
  end

  # Implement the execute method expected by RubyLLM
  # Arguments are passed as keyword arguments matching the schema properties
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

puts "--- Tools Integration Example ---"

# 2. Use the EasyTalk model as a tool using our new compatibility layer
chat = RubyLLM.chat.with_tool(Weather)

puts "User: What is the weather in Berlin (Lat: 52.52, Long: 13.405)?"
response = chat.ask "What is the weather in Berlin (Lat: 52.52, Long: 13.405)?"

puts "Assistant: #{response.content}"
