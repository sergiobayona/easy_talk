module T
  class OneOf < Types::FixedArray
    def initialize(*args)
      super(args)
    end

    def self.name
      'OneOf'
    end

    def name
      'OneOf'
    end

    def self.[](*args)
      new(*args)
    end
  end
end
