dm-is-rateable
=================

A DataMapper plugin that adds the ability to rate any model (the 5 clickable stars I see everywhere).

Dependencies
-------------

- dm-core (1.2.0)
- dm-validations (1.2.0)
- dm-aggregates (1.2.0)
- dm-timestamps (1.2.0)
- dm-types (1.2.0)

Example
--------

	class User
		include DataMapper::Resource
		property :id, Serial
	end

	class Trip

		include DataMapper::Resource
		property :id, Serial

		# will define:
		#
		# class TripRating
		#   include DataMapper::Resource
		#   property :id, Serial
		#   property :trip_id, Integer, :nullable => false
		#   property :user_id, Integer, :nullable => false
		#   property :rating,  Integer, :nullable => false
		#
		#   belongs_to :user
		# end
		#
		# Trip.user_ratings
		# User.trip_ratings
		#

		is :rateable, :by => :users

	end

More options
-------------

	is :rateable, :by => :accounts
	is :rateable, :by => {:name => :user, :key => :acc_id, :model => 'LegacyAcc'}
	is :rateable, :by => :users, :with => [:good,:bad]

	is :rateable, :by => :users, :as => :ratings # Trip.ratings instead of Trip.user_ratings

	# The following defines:
	#
	# UserTripQualityRating
	# Trip.user_quality_ratings
	# User.trip_quality_ratings
	is :rateable, :by => :users, :concerning => :quality


