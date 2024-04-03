module EasyTalk
  class CurrentContext < ActiveSupport::CurrentAttributes
    attribute :model, :schema_definitions
  end
end
