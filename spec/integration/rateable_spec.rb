
require 'pathname'
require Pathname(__FILE__).dirname.expand_path.parent + 'spec_helper'


describe DataMapper::Is::Rateable do
  
  unless HAS_SQLITE3 || HAS_MYSQL || HAS_POSTGRES
    fail 'need a database for testing (e.g. sqlite3)'
  end

  def unload_consts(*consts)
    consts.each do |c|
      c = "#{c}"
      Object.send(:remove_const, c) if Object.const_defined?(c)
    end
  end

  setup_rateable = ->(&code) {
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
      property :id, Serial
    end

    Trip.class_eval(&code)

    [Trip,Account,User].each(&:auto_migrate!)

    [Trip,Account,User]
  }

  after { unload_consts('User','Account','Trip','TripUserRating','TripAccountRating') }

  # --------------------------------------------------------------------------------------------------
  # --------------------------------------------------------------------------------------------------
  shared_examples :rateable_model do
    let(:rateable_model) { raise 'rateable model not set' }
    subject{ rateable_model }

    its(:rating_configs) { should include('TripUserRating') }
    its(:rateable_fk) { should == :trip_id }

    describe :rating_config do
      subject{ rateable_model.rating_configs['TripUserRating'] }

      its([:as]) { should == :user_ratings }
      its([:with]) { should == (0..5) }
      its([:by]) { should == {
          :name => :user,
          :model => 'User',
          :key => :user_id,
          :type => Integer,
          :options => {:required => true, :min => 0}
      }}
    end
  end

  # --------------------------------------------------------------------------------------------------
  # --------------------------------------------------------------------------------------------------
  shared_examples "every rating" do

    let(:rated_model)       { raise 'rated model not set' }
    let(:rating_model)      { raise 'rating model not set' }
    let(:rating_model_name) { raise 'rating model name not set' }

    let(:rateable) { raise 'rateable not set' }

    describe :rating_model do
      subject{ rating_model }

      it{ expect { subject.auto_migrate! }.to_not raise_error }

      its(:total_rating) { should == 0 }
    end

    describe :rated_model do
      subject{ rated_model }

      #its(:rateable_model)  { should == rating_model.name }
      #its(:rateable_key)    { should == :trip_user_rating } # FIXME
      #its(:rateable_fk)     { should == :trip_id } # FIXME
      #its(:total_rating)    { should == 0 } # FIXME total_user_rating
      
      [ :rating_togglable?,:anonymous_rating_togglable?,
        #:rater_fk,
        :rateable_fk].each do |method|
        it{ should respond_to(method) }
      end

      it 'has accessor :allowed_ratings' do
        pending
        subject.allowed_ratings = (-3..3)
        subject.allowed_ratings.should == (-3..3)
      end
    end

    describe :rateable do

      subject{ rateable }

      [ # :ratings, 
        :rating_togglable?, :anonymous_rating_togglable?,
        :rating_enabled?, :rating_disabled?, :anonymous_rating_enabled?,
        :anonymous_rating_disabled?#, :user_rating
      ].each do |method|
        it { should respond_to(method) }
      end

      #its(:average_user_rating) { should == 0 }
    end

  end

  # --------------------------------------------------------------------------------------------------
  # --------------------------------------------------------------------------------------------------
  shared_examples :timestamped_ratings do
    subject{ rating }
    let(:rating) { raise 'rating not set' }

    it { should respond_to(:created_at) }
    it { should respond_to(:updated_at) }
    #its(:created_at) { should_not be_nil }
    #its(:updated_at) { should_not be_nil }
  end

  # --------------------------------------------------------------------------------------------------
  # --------------------------------------------------------------------------------------------------
  shared_examples 'rateable with rating enabled' do
    subject{ rateable }
    let(:rateable)  { raise 'rateable not set' }
    let(:rater)     { raise 'rater not set' }

    describe 'can be rated' do
      it 'when rater passed' do
        pending
        rateable.rate(1,rater)
      end
    end
  end
  
  # --------------------------------------------------------------------------------------------------
  # --------------------------------------------------------------------------------------------------
  describe 'is :rateable, :by => :users' do
    before do
      setup_rateable.call do
        is :rateable, :by => :users
      end

      [TripUserRating].each(&:auto_migrate!)
    end

    it_behaves_like :rateable_model do
      let(:rateable_model) { Trip }
    end

    it_behaves_like 'every rating' do
      let(:rating_model) { TripUserRating }
      let(:rated_model) { Trip }
      let(:rateable) { Trip.create }
    end
  end

  # --------------------------------------------------------------------------------------------------
  # --------------------------------------------------------------------------------------------------
  describe 'is :rateable, :by => :users, :as => :ratings' do
    before do
      setup_rateable.call do
        is :rateable, :by => :users, :as => :ratings
      end

      [TripUserRating].each(&:auto_migrate!)
    end

    describe :rateable do
      subject{ Trip.create }
      it { should respond_to(:ratings) }
      it { should_not respond_to(:user_ratings) }
      
      it { should respond_to(:average_rating) }
      it { should_not respond_to(:average_user_rating) }

      context 'when no rating supplied' do
        its(:average_rating) { should be_nil }
      end

      context 'when rating supplied by rater' do
        let(:rater)   { User.create }
        let(:rating)  { 2 }
        before{ subject.rate(rating,rater) }

        its(:average_rating) { should == rating }
      end
    end
  end

  # --------------------------------------------------------------------------------------------------
  # --------------------------------------------------------------------------------------------------
  describe 'is :rateable, :by => :users and :accounts' do
    before do
      setup_rateable.call do
        is :rateable, :by => :users
        is :rateable, :by => :accounts
      end

      [TripUserRating,TripAccountRating].each(&:auto_migrate!)
    end

    #it_behaves_like 'every rating' do
    #  let(:rating_model) { TripUserRating }
    #  let(:rated_model) { Trip }
    #  let(:rateable) { Trip.create }
    #end

    it_behaves_like :rateable_model do
      let(:rateable_model) { Trip }
    end

    describe :rateable do
      let(:rateable) { Trip.create }
      subject{ rateable }
      
      it { should respond_to(:user_ratings) }
      it { should respond_to(:account_ratings) }
      it { should_not respond_to(:ratings) }

      it { should respond_to(:average_user_rating) }
      it { should respond_to(:average_account_rating) }
      it { should_not respond_to(:average_rating) }

      context 'when no rating supplied' do
        its(:average_user_rating) { should be_nil }
        its(:average_account_rating) { should be_nil }
      end

      context 'when rating supplied by user' do
        let(:rater)   { User.create }
        let(:rating)  { 2 }
        before{ subject.rate(rating,rater) }

        its(:average_user_rating) { should == rating }
        its(:average_account_rating) { should be_nil }
      end

      context 'when rating supplied by account' do
        let(:rater)   { Account.create }
        let(:rating)  { 2 }
        before{ subject.rate(rating,rater) }

        its(:average_account_rating) { should == rating }
        its(:average_user_rating) { should be_nil }
      end

    end
  end

  # --------------------------------------------------------------------------------------------------
  # --------------------------------------------------------------------------------------------------
  describe 'when rateable twice by same rater' do
    it 'raises error' do
      expect {
        setup_rateable.call do
          is :rateable, :by => :users, :as => :special_ratings
          is :rateable, :by => :users, :as => :regular_ratings
        end
      }.to raise_error
    end
  end

  # --------------------------------------------------------------------------------------------------
  # --------------------------------------------------------------------------------------------------
  describe 'is :rateable, :by => :users with enhancements' do
    before do
      setup_rateable.call do
        is :rateable, :by => :users do
          def extra_method; true; end
        end
      end

      [TripUserRating].each(&:auto_migrate!)
    end

    describe :rating do
      let(:rater) { User.create }
      let(:rateable) { Trip.create }
      let(:rating) { rateable.rate(1,rater) }

      subject{ rating }

      it { should respond_to(:extra_method) }
      its(:extra_method) { should be_true }
    end
  end

  # --------------------------------------------------------------------------------------------------
  # --------------------------------------------------------------------------------------------------
  describe 'is :rateable, :by => :users, :model => not implemented' do
#    before do
#      setup_rateable.call do
#        is :rateable, :by => :users, :model => 'AwkwardRating'
#      end
#
#      [AwkwardRating].each(&:auto_migrate!)
#    end
#
#    it_behaves_like :rateable_model do
#      let(:rateable_model) { Trip }
#    end

    it ':model option not implemented' do
      expect{ setup_rateable.call do
        is :rateable, :by => :users, :model => 'AwkwardRating'
      end }.to raise_error(NotImplementedError)
    end
  end

  # --------------------------------------------------------------------------------------------------
  # --------------------------------------------------------------------------------------------------
  describe 'rateable model' do
    before do
      setup_rateable.call do
        is :rateable, :by => :users
      end

      [TripUserRating].each(&:auto_migrate!)
    end

    let(:rateable_model){ Trip }
    let(:rater_model)   { User }
    let(:rating_model)  { TripUserRating }

    # #rating_config_for
    describe '#rating_config_for' do

      context 'when user model passed' do
        subject{ rateable_model.rating_config_for(rater_model) }

        it{ should be_a(Hash) }
        its([:by]){ should include(:model => rater_model.name) }
      end

      context 'when association name passed' do
        let(:assoc) { :users }
        subject{ rateable_model.rating_config_for(assoc) }

        it{ should be_a(Hash) }
        its([:by]) { should include(:name => assoc.to_s.singularize.to_sym) }
        its([:by]) { should include(:model => rater_model.name) }
      end
      
    end

    # #rating_model_for
    describe '#rating_model_for' do
      context 'when user model passed' do
        subject{ rateable_model.rating_model_for(rater_model) }

        it{ should == rating_model }
      end

      context 'when association name passed' do
        let(:assoc) { :users }
        subject{ rateable_model.rating_model_for(assoc) }

        it{ should == rating_model }
      end
    end

=begin
    # #average_rating_for
    describe '#average_rating_for' do
      let(:rateable) { rateable_model.create }
      subject{ rateable_model.average_rating_of(rateable,rater_model) }

      context 'when no ratings exist' do
        it{ should be_nil }
      end

      context 'when a rating exists' do
        let(:rater)   { rater_model.create }
        let(:value)   { 2 }
        let!(:rating) { rateable.rate(value, rater) }

        it{ should == value }
      end

      context 'when multiple ratings exist' do
        let(:raters)    { 3.times.map{ rater_model.create } }
        let(:value)     { rand(5) }
        let!(:ratings)  { raters.map{ |r| rateable.rate(value, r) } }

        it{ should == ratings.map(&:rating).sum.to_f / ratings.length }
      end
      
    end
=end
    
  end

  describe 'rateable' do
    before do
      setup_rateable.call do
        is :rateable, :by => :users
      end

      [TripUserRating].each(&:auto_migrate!)
    end

    let(:rateable_model){ Trip }
    let(:rater_model)   { User }

    let(:rateable) { Trip.create }

    # #average_rating_of(User)
    # #average_rating_of(:users)
    describe '#average_rating_of' do
      subject{ rateable.average_rating_of(param) }

      shared_examples 'average ratings' do
        let(:rater)   { User.create }
        
        context 'when no ratings present' do
          it { should be_nil }
        end

        context 'when one rating present' do
          let!(:rating) { rateable.rate(2, rater) }

          it{ should == rating.rating }
        end

        context 'when ratings of multiple users present' do
          let!(:ratings) { 4.times.map{ (0..5).to_a.sample } }
          before{ ratings.each{ |r| rateable.rate(r, User.create) } }

          it{ should == ratings.sum.to_f / ratings.length }
        end

        context 'when ratings on other rateables are present too' do
          let(:other_rateable) { rateable_model.create }
          let!(:ratings) { 4.times.map{ (0..5).to_a.sample } }
          before{
            ratings.each{ |r| rateable.rate(r, User.create) }
            4.times{ other_rateable.rate((0..5).to_a.sample, User.create) }
          }

          it{ should == ratings.sum.to_f / ratings.length }
        end
      end

      context 'when passing class' do
        let(:param) { rater.class }

        it_behaves_like 'average ratings'
      end

      context 'when passing :users' do
        let(:param) { :users }

        it_behaves_like 'average ratings'
      end
    end#average_rating_of

    
  end

end

