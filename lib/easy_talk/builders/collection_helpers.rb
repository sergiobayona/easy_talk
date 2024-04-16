# frozen_string_literal: true

module EasyTalk
  module Builders
    # Base builder class for array-type properties.
    module CollectionHelpers
      def collection_type?
        true
      end
    end
  end
end
