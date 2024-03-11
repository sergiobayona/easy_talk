module SorbetExtension
  def nilable?
    types.any? do |type|
      type.respond_to?(:raw_type) && type.raw_type == NilClass
    end
  end
end

T::Types::Union.include SorbetExtension
