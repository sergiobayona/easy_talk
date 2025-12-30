# frozen_string_literal: true
# typed: true

module EasyTalk
  class Error < StandardError; end
  class ConstraintError < Error; end
  class UnknownOptionError < Error; end
  class UnknownTypeError < Error; end
  class InvalidInstructionsError < Error; end
  class InvalidPropertyNameError < Error; end
end
