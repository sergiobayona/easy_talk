# frozen_string_literal: true

module EasyTalk
  class Error < StandardError; end
  class ConstraintError < Error; end
  class UnknownOptionError < Error; end
  class InvalidPropertyNameError < Error; end
end
