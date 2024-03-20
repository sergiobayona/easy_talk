module T
  class AllOf < Types::FixedArray
    def initialize(*args)
      super(args)
    end

    def self.name
      'AllOf'
    end

    def name
      'AllOf'
    end

    def self.[](*args)
      new(*args)
    end
  end
end
