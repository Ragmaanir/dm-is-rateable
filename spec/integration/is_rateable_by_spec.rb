
describe DataMapper::Is::Rateable do

	def unload_consts(*consts)
    consts.each do |c|
      c = "#{c}"
      Object.send(:remove_const, c) if Object.const_defined?(c)
    end
  end

	# --------------------------------------------------------------------------------------------------
	# SCENARIO
	# --------------------------------------------------------------------------------------------------
	before do
		class Account
      include DataMapper::Resource
      property :id, Serial
    end

    class Trip
      include DataMapper::Resource
      property :id, Serial

			is :rateable, :by => :accounts
    end

		[Trip,Account,TripRatingByAccount].each(&:auto_migrate!)
	end

	after do
		unload_consts(Trip,Account,TripRatingByAccount)
	end

	let(:rateable_model){ Trip }
	let(:rater_model)		{ Account }
	let(:rating_model)	{ TripRatingByAccount }

	# --------------------------------------------------------------------------------------------------
	# RATEABLE
	# --------------------------------------------------------------------------------------------------
	describe 'Rateable' do

		describe 'Model' do
			subject{ rateable_model }

			its(:rating_configs) { should == {
				'TripRatingByAccount' => {
					:by => {
						:name => :account,
						:key => :account_id,
						:model => 'Account',
						:type => Integer,
						:options => {:required => true, :min => 0}
					},
					:with => 0..5,
					:as => :ratings_by_accounts,
					:model => 'TripRatingByAccount',
					:timestamps => true
				}
			} }

			its(:relationships) { should be_named(:ratings_by_accounts) }
		end

		describe 'Instance' do
			let(:rateable)	{ rateable_model.create }

			subject{ rateable }

			context 'when no rating exists' do
				it{ rateable.average_rating_of(rater_model).should == nil }
				its(:average_rating_by_accounts) { should == nil }
			end

			context 'when one rating exists' do
				before{ rateable.rate(1,rater_model.create) }

				it{ rateable.average_rating_of(rater_model).should == 1 }
				its(:average_rating_by_accounts) { should == 1 }
			end

			context 'when multiple ratings exist' do
				let(:avg) { ratings.sum.to_f/ratings.length }
				let(:ratings) { 10.times.map{ (0..5).to_a.sample } }
				before{ ratings.each{ |r| rateable.rate(r,rater_model.create) } }

				it{ rateable.average_rating_of(rater_model).should == avg }
				its(:average_rating_by_accounts) { should == avg }
			end
		end
	end

	# --------------------------------------------------------------------------------------------------
	# RATER
	# --------------------------------------------------------------------------------------------------
	describe 'Rater' do
		
		describe 'Model' do
			subject{ rater_model }

			its(:relationships){ should be_named(:trip_account_ratings) }
		end

		describe 'Instance' do
			let(:rater) { rater_model.create }
			subject{ rater }
			
			its(:trip_ratings) { should be_empty }

			context 'when rated a rateable' do
				let(:rateable) { rateable_model.create }
				before{ rateable.rate(1,rater) }

				its(:trip_ratings) { should have(1).entry }
				its(:'trip_ratings.first.rating') { should == 1 }
			end

			context 'when rated multiple rateables' do
				let(:rateables) { 3.times.map{ rateable_model.create } }
				before{ rateables.each{ |r| r.rate(1,rater) } }

				its(:trip_ratings) { should have(rateables.length).entries }
				its(:'trip_ratings.first.rating') { should == 1 }
			end
		end
	end

	# --------------------------------------------------------------------------------------------------
	# RATING
	# --------------------------------------------------------------------------------------------------
	describe 'Rating' do

		describe 'Model' do
			subject{ rating_model }
			
			its(:properties) { should be_named(:trip_id) }
			its(:properties) { should be_named(:account_id) }
			its(:properties) { should be_named(:rating) }
			its(:properties) { should be_named(:created_at) }
			its(:properties) { should be_named(:updated_at) }

			its(:relationships) { should be_named(:account) }
			its(:relationships) { should be_named(:trip) }

			its(:instance_methods) { should include(:rater) }
			its(:instance_methods) { should include(:rateable) }
		end

		describe 'Instance' do
			let(:rateable){ rateable_model.create }
			let(:rater)		{ rater_model.create }
			let(:rating)	{ rateable.rating_of(rater) }
			before { rateable.rate(1,rater) }
			subject{ rating }

			its(:rating)	{ should == 1 }
			its(:rateable){ should == rateable }
			its(:rater)		{ should == rater }
		end

	end

end

