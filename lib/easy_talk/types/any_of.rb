module T
  class AnyOf < Types::FixedArray
    def initialize(*args)
      super(args)
    end

    def self.name
      'AnyOf'
    end

    def name
      'AnyOf'
    end

    def self.[](*args)
      new(*args)
    end
  end
end
