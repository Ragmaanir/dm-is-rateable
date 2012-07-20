
require 'integration/shared_examples'

describe DataMapper::Is::Rateable do

  def unload_consts(*consts)
    consts.each do |c|
      c = "#{c}"
      Object.send(:remove_const, c) if Object.const_defined?(c)
    end
  end
  
#  def define_models(&block)
#    @rateable_model = Class.new do
#      include DataMapper::Resource
#      property :id, Serial
#    end
#
#    @rater_model = Class.new do
#      include DataMapper::Resource
#      property :id, Serial
#    end
#    
#    @rating_model = 
#    
#    [rateable_model,rater_model,rating_model].each(&:auto_migrate!)
#  end

  context 'SCENARIO' do
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

        is :rateable, :by => :accounts, :with => [:good,:bad]
      end

      [rateable_model,rater_model,rating_model].each(&:auto_migrate!)
    end

    after do
      unload_consts(rateable_model,rater_model,rating_model)
    end

    let(:rateable_model){ Trip }
    let(:rater_model)   { Account }
    let(:rating_model)  { AccountTripRating }

    # --------------------------------------------------------------------------------------------------
    # RATEABLE
    # --------------------------------------------------------------------------------------------------
    describe 'Rateable' do

      describe 'Model' do
        subject{ rateable_model }

        its(:rating_configs) { should == [
          {
            :by => {
              :name => :account,
              :key => :account_id,
              :model => 'Account',
              :type => Integer,
              :options => {:required => true, :min => 0}
            },
            :with => [:good,:bad],
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

  #     context 'when no rating exists' do
  #       it{ rateable.average_rating_of(rater_model).should == nil }
  #       its(:average_account_rating) { should == nil }
  #     end
  #
  #     context 'when one rating exists' do
  #       before{ rateable.rate(1,rater_model.create) }
  #
  #       it{ rateable.average_rating_of(rater_model).should == 1 }
  #       its(:average_account_rating) { should == 1 }
  #     end
  #
  #     context 'when multiple ratings exist' do
  #       let(:avg) { ratings.sum.to_f/ratings.length }
  #       let(:ratings) { 10.times.map{ (0..5).to_a.sample } }
  #       before{ ratings.each{ |r| rateable.rate(r,rater_model.create) } }
  #
  #       it{ rateable.average_rating_of(rater_model).should == avg }
  #       its(:average_account_rating) { should == avg }
  #     end
      end
    end

    # --------------------------------------------------------------------------------------------------
    # RATER
    # --------------------------------------------------------------------------------------------------
    describe 'Rater' do

      describe 'Model' do
        subject{ rater_model }

        its(:relationships){ should be_named(:trip_ratings) }
      end

      describe 'Instance' do
        let(:rater) { rater_model.create }
        subject{ rater }

        its(:trip_ratings) { should be_empty }

        context 'when rated a rateable' do
          let(:rateable) { rateable_model.create }
          before{ rateable.rate(:good,rater) }

          its(:trip_ratings) { should have(1).entry }
          its(:'trip_ratings.first.rating') { should == :good }
        end

        context 'when rated multiple rateables' do
          let(:rateables) { 3.times.map{ rateable_model.create } }
          before{ rateables.each{ |r| r.rate(:good,rater) } }

          its(:trip_ratings) { should have(rateables.length).entries }
          its(:'trip_ratings.first.rating') { should == :good }
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
        
        it 'has :with constraints on rating property' do
          subject.properties[:rating].flag_map.values.should == [:good,:bad]
        end

        it_behaves_like :rating_model
      end

      describe 'Instance' do
        let(:rateable){ rateable_model.create }
        let(:rater)   { rater_model.create }
        let(:rating)  { rateable.rating_of(rater) }
        before { rateable.rate(:bad,rater) }
        subject{ rating }

        its(:rating)  { should == :bad }
        its(:rateable){ should == rateable }
        its(:rater)   { should == rater }
      end

    end
  end
  
  context 'BUGS' do
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

        is :rateable, :by => :accounts, :with => 1..5
      end

      [rateable_model,rater_model,rating_model].each(&:auto_migrate!)
    end

    after do
      unload_consts(rateable_model,rater_model,rating_model)
    end

    let(:rateable_model){ Trip }
    let(:rater_model)   { Account }
    let(:rating_model)  { AccountTripRating }
    
    describe 'Rating' do
      describe 'Model' do
        subject{ rating_model }
        it 'has :with constraints on rating property' do
          subject.properties[:rating].min.should == 1
          subject.properties[:rating].max.should == 5
        end
      end
    end
  end

end
