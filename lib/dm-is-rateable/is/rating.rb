module DataMapper
  module Is
    module Rateable
      module Rating
        include DataMapper::Resource

        is :remixable

        property :id, Serial
      end
    end
  end
end
