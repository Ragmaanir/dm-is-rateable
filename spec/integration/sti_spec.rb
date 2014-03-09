describe DataMapper::Is::Rateable do

  def unload_consts(*consts)
    consts.each do |c|
      c = "#{c}"
      Object.send(:remove_const, c) if Object.const_defined?(c)
    end
  end

  before do
    class Account
      include DataMapper::Resource

      property :id, Serial
    end

    class Trip
      include DataMapper::Resource

      property :id, Serial

      is :rateable, by: :accounts, with: 0..5
    end

    class CampingTrip < Trip
    end

    class RaftingTrip < Trip
    end

    [rateable_model,rater_model,rating_model].each(&:auto_migrate!)
  end

  after do
    unload_consts(rateable_model,rater_model,rating_model,CampingTrip,RaftingTrip)
  end

  let(:rateable_model){ Trip }
  let(:rater_model)   { Account }
  let(:rating_model)  { AccountTripRating }

  # --------------------------------------------------------------------------------------------------
  # RATEABLE
  # --------------------------------------------------------------------------------------------------
  describe 'Rateable' do

    describe 'Model' do
      subject{ CampingTrip }

      its(:rating_configs) { should == [
        {
          :by => {
            :name => :account,
            :key => :account_id,
            :model => 'Account',
            :type => Integer,
            :options => {:required => true, :min => 0}
          },
          :with => 0..5,
          :as => :account_ratings,
          :model => 'AccountTripRating',
          :timestamps => true,
          :rating_name => 'Rating'
        }
      ] }

      its(:relationships) { should be_named(:account_ratings) }

      it_behaves_like :rateable_model
    end

    describe 'Instance' do
      let(:rateable)  { rateable_model.create }

      subject{ rateable }

      context 'when no rating exists' do
        it{ rateable.average_rating_of(rater_model).should == nil }
        its(:average_account_rating) { should == nil }
      end

      context 'when one rating exists' do
        let(:rater) { rater_model.create }
        before{ rateable.rate(1,rater) }

        it{ rateable.average_rating_of(rater_model).should == 1 }
        its(:average_account_rating) { should == 1 }
        it{ rateable.rating_of(rater,:quality).rating.should == 1 }
        it{ rateable.rating_of(rater).rating.should == 1 }
      end

      context 'when multiple ratings exist' do
        let(:avg) { ratings.sum.to_f/ratings.length }
        let(:ratings) { 10.times.map{ (0..5).to_a.sample } }
        before{ ratings.each{ |r| rateable.rate(r,rater_model.create) } }

        it{ rateable.average_rating_of(rater_model).should == avg }
        its(:average_account_rating) { should == avg }
      end
    end
  end

end
