
describe DataMapper::Is::Rateable do

	describe '.infer_rater from' do
		subject{ DataMapper::Is::Rateable::Helper.infer_rater(by_options) }

		context ':users' do
			let(:by_options) { :users }

			it{ should be_a(Hash) }
			it{ should == {
				:name		=> :user,
				:model	=> 'User',
				:key		=> :user_id,
				:type		=> Integer,
				:options => { :required => true, :min => 0 }
			} }
		end

		context ":name => :user, :model => 'Account'" do
			let(:by_options) { {:name => :user, :model => 'Account'} }

			it{ should be_a(Hash) }
			it{ should == {
				:name		=> :user,
				:model	=> 'Account',
				:key		=> :user_id,
				:type		=> Integer,
				:options => { :required => true, :min => 0 }
			} }
		end

		context "User" do
			before do
				class User
					include DataMapper::Resource
					property :id, Serial
				end
			end
			let(:by_options) { User }

			it{ should be_a(Hash) }
			it{ should == {
				:name		=> :user,
				:model	=> 'User',
				:key		=> :user_id,
				:type		=> Integer,
				:options => { :required => true, :min => 0 }
			} }
		end

		context ":name => :author, :model => 'User', :key => :account_id" do
			before do
				class User
					include DataMapper::Resource
					property :id, Serial
				end
			end
			let(:by_options) { {:name => :author, :model => 'User', :key => :account_id} }

			it{ should be_a(Hash) }
			it{ should == {
				:name		=> :author,
				:model	=> 'User',
				:key		=> :account_id,
				:type		=> Integer,
				:options => { :required => true, :min => 0 }
			} }
		end

		pending 'My::Module::User'
	end

	describe '.complete_options' do
		let(:helper) { DataMapper::Is::Rateable::Helper }
		subject{ helper.complete_options(options,model) }

		context ':by => :users' do
			let(:options) { {:by => :users} }
			let(:model)		{ Xyz = Class.new }

			it{ should == {
				:with => 0..5,
				:by => :users,
				:as => :user_ratings,
				:timestamps => true,
				:model => 'UserXyzRating',
				:rating_name => 'Rating'
			} }
		end

		context ':by => :users, :as => :ratings' do
			let(:options) { {:by => :users, :as => :ratings} }
			let(:model)		{ Xyz = Class.new }

			it{ should == {
				:with => 0..5,
				:by => :users,
				:as => :ratings,
				:timestamps => true,
				:model => 'UserXyzRating',
				:rating_name => 'Rating'
			} }
		end

		context ':by => :users, :concerning => :quality' do
			let(:options) { {:by => :users, :concerning => :quality} }
			let(:model)		{ Xyz = Class.new }

			it{ should == {
				:with => 0..5,
				:by => :users,
				:as => :user_quality_ratings,
				:concerning => :quality,
				:timestamps => true,
				:model => 'UserXyzQualityRating',
				:rating_name => 'QualityRating'
			} }
		end

		context ':by => :users, :concerning => :quality, :as => :ratings' do
			let(:options) { {:by => :users, :concerning => :quality, :as => :ratings} }
			let(:model)		{ Xyz = Class.new }

			it{ expect{ subject }.to raise_error }
		end

		context ":by => :users, :model => 'SomeModel'" do
			let(:options) { {:by => :users, :model => 'SomeModel'} }
			let(:model)		{ Xyz = Class.new }

			it{ expect{ subject }.to raise_error }
		end

		context ":by => {:name => :user, :key => :legacy_user_id, :model => 'LegacyUser'}" do
			let(:by_options){ {:name => :user, :key => :legacy_user_id, :model => 'LegacyUser'} }
			let(:options) { {:by => by_options } }
			let(:model)		{ Xyz = Class.new }

			it{ should == {
				:with => 0..5,
				:by => by_options,
				:as => :user_ratings,
				:timestamps => true,
				:model => 'LegacyUserXyzRating',
				:rating_name => 'Rating'
			} }
		end

		context ":by => {:name => :user, :key => :legacy_user_id, :model => 'LegacyUser'}, :concerning => :quality" do
			let(:by_options){ {:name => :user, :key => :legacy_user_id, :model => 'LegacyUser'} }
			let(:options) { {:by => by_options, :concerning => :quality } }
			let(:model)		{ Xyz = Class.new }

			it{ should == {
				:with => 0..5,
				:by => by_options,
				:as => :user_quality_ratings,
				:concerning => :quality,
				:timestamps => true,
				:model => 'LegacyUserXyzQualityRating',
				:rating_name => 'QualityRating'
			} }
		end
	end#.complete_options

end

