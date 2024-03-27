module EasyTalk
  class CurrentContext < ActiveSupport::CurrentAttributes
    attribute :model
  end
end
