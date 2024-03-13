# frozen_string_literal: true

module EasyTalk
  KEYWORDS = %i[
    description
    type
    title
    all_of
    any_of
    one_of
    not
    property
    required
    items
    additional_items
    pattern_properties
    additional_properties
    dependencies
    dependent_required
    format
    content_media_type
    content_encoding
    enum
    const
    default
    examples
    max_length
    min_length
    pattern
    maximum
    exclusive_maximum
    minimum
    exclusive_minimum
    multiple_of
    max_items
    min_items
    unique_items
    max_properties
    min_properties
  ].freeze
end
