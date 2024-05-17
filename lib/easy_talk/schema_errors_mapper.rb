# frozen_string_literal: true

module EasyTalk
  class SchemaErrorsMapper
    def initialize(errors)
      @errors = errors.to_a
    end

    def errors
      @errors.each_with_object({}) do |error, hash|
        if error['data_pointer'].present?
          key = error['data_pointer'].split('/').compact_blank.join('.')
          hash[key] = error['error']
        else
          error['details']['missing_keys'].each do |missing_key|
            message = "#{error['error'].split(':').first}: #{missing_key}"
            hash[missing_key] = message
          end
        end
      end
    end
  end
end
