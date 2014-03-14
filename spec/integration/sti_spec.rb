
require 'integration/shared_examples'

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

    describe 'Instance of subclass' do
      let(:rateable)  { CampingTrip.create }
      let(:concern)   { :quality }

      it_should_behave_like :rateable_instance
    end

  end

end
