module EasyTalk
  class Error < StandardError; end
  class ConstraintError < Error; end
  class TypeMismatchError < Error; end
  class UnknownOptionError < Error; end
  class InvalidPropertyNameError < Error; end
end
