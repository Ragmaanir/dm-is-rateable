
describe DataMapper::Is::Rateable do
	# --------------------------------------------------------------------------------------------------
  describe 'is :rateable, :by => :users and :accounts' do
    before do
			class User
				include DataMapper::Resource
				property :id, Serial
			end
			class Account
				include DataMapper::Resource
				property :id, Serial
			end
      class Trip
				include DataMapper::Resource
        is :rateable, :by => :users
        is :rateable, :by => :accounts
      end
			
      [UserTripRating,AccounTriptRating].each(&:auto_migrate!)
    end
		
		after{ unload_consts(User,Trip,UserTripRating,AccounTriptRating) }

		pending
  end

  # --------------------------------------------------------------------------------------------------
  describe 'when rateable twice by same rater' do
    it 'raises error' do
      expect {
				class User
					include DataMapper::Resource
					property :id, Serial
				end
        class Trip
					include DataMapper::Resource
					property :id, Serial
          is :rateable, :by => :users, :as => :special_ratings
          is :rateable, :by => :users, :as => :regular_ratings
        end
      }.to raise_error
    end

		after { unload_consts(User,Trip,UserTripRating) }
  end

end