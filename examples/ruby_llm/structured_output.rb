# frozen_string_literal: true

require 'bundler/setup'
require 'ruby_llm'
require 'easy_talk'

# Example: Structured Outputs
# Demonstrates using EasyTalk models to generate structured JSON responses.

RubyLLM.configure do |config|
  config.openai_api_key = ENV.fetch('OPENAI_API_KEY', nil)
end

# 1. Define the Schema using EasyTalk
class Recipe
  include EasyTalk::Model

  define_schema do
    description "A simple cooking recipe"
    property :name, String, description: "Name of the dish"
    property :ingredients, T::Array[String], description: "List of ingredients"
    property :prep_time_minutes, Integer, description: "Preparation time in minutes"
    property :steps, T::Array[String], description: "Step by step cooking instructions"
  end
end

puts "--- Structured Output Example ---"

# 2. Use the EasyTalk model as the output schema
# RubyLLM uses the schema to force the LLM to reply with a matching JSON structure.
# Our compatibility layer ensures 'Recipe' responds to to_json_schema as RubyLLM expects.
chat = RubyLLM.chat.with_schema(Recipe)

puts "User: Give me a simple spaghetti carbonara recipe."
response = chat.ask "Give me a simple spaghetti carbonara recipe."

# 3. Access the structured data
# RubyLLM returns parsed JSON as a Hash, so we instantiate the model with it
recipe = Recipe.new(response.content)

puts "\nGenerated Recipe:"
puts "Name: #{recipe.name}"
puts "Time: #{recipe.prep_time_minutes} mins"
puts "Ingredients:"
recipe.ingredients.each { |ing| puts "- #{ing}" }
puts "Steps:"
recipe.steps.each_with_index { |step, i| puts "#{i + 1}. #{step}" }
