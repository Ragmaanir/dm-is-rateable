module DataMapper
  module Is
    module Rateable
      
      class DmIsRateableException < Exception; end
      
      class RatingDisabled < DmIsRateableException; end
      class AnonymousRatingDisabled < DmIsRateableException; end
      class TogglableRatingDisabled < DmIsRateableException; end
      class TogglableAnonymousRatingDisabled < DmIsRateableException; end
      class ImpossibleRatingType < DmIsRateableException; end
      class ImpossibleRatingValue < DmIsRateableException; end

      Inflector = DataMapper::Inflector

      module Helper
        def self.deduce_rating_type(allowed_ratings)
          case allowed_ratings
            when Range then
              allowed_ratings.first.is_a?(Integer) ? Integer : String
            when Enum  then
              require 'dm-types'
              DataMapper::Types::Enum
            else
              raise ImpossibleRatingType, "#{allowed_ratings.class} is no supported rating type" 
          end
        end
        
        def self.infer_rater(by_option)
          case by_option
            when Symbol
              name = by_option.to_s.singularize
              {
                :name => name.to_sym,
                :model => name.classify,
                :key => Inflector.foreign_key(name).to_sym,
                :type => Integer,
                :options => { :required => true, :min => 0 } # FIXME only merge :min when type is integer
              }
            when Hash
              by_option.assert_valid_keys(:name,:key,:type,:model,:options)
							name = by_option[:name].to_s
							key = by_option[:key] || Inflector.foreign_key(name).to_sym
							model = key.to_s.gsub(/_id/,'').classify
							{
								:model => model,
								:key => key,
								:type => Integer,
								:options => { :required => true, :min => 0 } # FIXME only merge :min when type is integer
							}.merge(by_option)
						when DataMapper::Model
							name = by_option.name.downcase
              {
                :name => name.to_sym,
                :model => by_option.name,
                :key => Inflector.foreign_key(name).to_sym,
                :type => Integer,
                :options => { :required => true, :min => 0 } # FIXME only merge :min when type is integer
              }
            when nil then raise ":by option missing"
            else raise "invalid value for :by: #{by_option}"
          end
        end
      end
      
      module Rating

#        def self.included(base)
#          base.extend ClassMethods
#        end

        include DataMapper::Resource

        is :remixable

        property :id, Serial
  
#        module ClassMethods
#
#          # total rating for all rateable instances of this type
#          def total_rating
#            rating_sum = self.sum(:rating).to_f
#            rating_count = self.count.to_f
#            rating_count > 0 ? rating_sum / rating_count : 0
#          end
#
#        end
      end

      # is :rateable, :by => :users, :with => 0..5, :as => :user_ratings, :model => 'SpecialUserRating' do
      #   def xyz; true; end
      # end
      #
      # is :rateable, :by => {:name => :user, :key => :user_id, :model => 'User'}
      def is_rateable(options = {},&enhancer)
        
        extend  ClassMethods
        include InstanceMethods

        rater = Helper.infer_rater(options[:by])

				aspect = (options[:concerning] || '').camelize
				rating_name = "#{aspect}Rating"
				rateable_name = self.name

				model = options[:model] || "#{rateable_name}#{rating_name}By#{rater[:model]}"
				#as = model.underscore.pluralize.gsub("#{self.name.underscore}_",'').to_sym
				as = if options[:model]
					model.underscore.pluralize.gsub("#{rateable_name.underscore}_",'').to_sym
				else
					"ratings_by_#{rater[:name].to_s.pluralize}".to_sym
				end
        
        options = {
          :with => 0..5,
          :by => rater,
          #:as => "#{rater[:name]}_ratings".to_sym,
					:as => as,
          :timestamps => true,
          :model => model
        }.merge(options)

        if self.respond_to?(:rating_configs)
          raise("duplicate is :rateable, :by => #{rater[:model]}") if rating_configs.find{ |model,config|
            config[:by][:model] == rater[:model]
          }
        else
          class_attribute :rating_configs
          self.rating_configs = {}
        end

        # add rating config
        self.rating_configs.merge!(options[:model] => options.merge(:by => rater))

        remix n, Rating, :as => options[:as], :model => options[:model], :for => rater[:model]

        class_attribute :remixed_rating # FIXME remove

        remix_name = options[:model].underscore.to_sym

        #self.remixed_rating = remixables[:rating]
        self.remixed_rating = remixables[:rating][remix_name] # TODO remix_name or fk_name?

        # determine property type based on supplied values
        rating_type = Helper.deduce_rating_type(options[:with])

        # close on this because enhance will class_eval in remixable model scope 
        rateable_key = self.rateable_fk
				rateable_model = options[:model].constantize
				rateable_name = self.name.underscore
				parent_assocation = rateable_key.to_s.gsub(/_id/, '').to_sym

        # enhance the rating model
        enhance :rating, options[:model] do

          property :rating, rating_type, :required => true

          #belongs_to options[:as], model_name # XXX

          if rater
            property rater[:key], rater[:type], rater[:options]
            belongs_to rater[:name], rater[:model]

            validates_uniqueness_of rater[:key], :when => :testing_association, :scope => [parent_assocation]
            validates_uniqueness_of rater[:key], :when => :testing_property, :scope => [rateable_key]
          end
          
          timestamps(:at) if options[:timestamps]
          
          class_eval(&enhancer) if enhancer
        end

				# add :rater and :rateable relationships to rating model
				rateable_model.class_eval do
					define_method :rater do
						send(rater[:name])
					end

					define_method :rateable do
						send(rateable_name)
					end
				end

#        # create average method for the ratings, e.g. for users: average_user_rating
#        #singular_reader = remixed_rating[:reader].to_s.singularize
#        singular_name = options[:as].to_s.singularize
#
#        define_method("average_#{singular_name}") do
#          average_rating_of(rater[:name].to_s.pluralize.to_sym)
#        end

				singular_name = options[:as].to_s.singularize

        define_method("average_#{rating_name.underscore}_by_#{rater[:name].to_s.pluralize}") do
          average_rating_of(rater[:name].to_s.pluralize.to_sym)
        end

      end

      module ClassMethods
        
        def rating_togglable?
          self.properties.named? :rating_enabled
        end
                
#        def anonymous_rating_togglable?
#          self.properties.named? :anonymous_rating_enabled
#        end
        
        #def total_rating
        #  remixables[:rating][rateable_key][:model].total_rating
        #end
        
        def rateable_fk
          demodulized_name = DataMapper::Inflector.demodulize(self.name)
          DataMapper::Inflector.foreign_key(demodulized_name).to_sym
        end

        # Rateable.rating_config_for(:users)  #=> { :name => :user, :model => 'Account', ... }
        # Rateable.rating_config_for(User)    #=> { :model => 'User', :name => :author, ...  }
        def rating_config_for(raters_or_model)
          case raters_or_model
            when Symbol
              rating_configs.find{ |model,conf| conf[:by][:name] == raters_or_model.to_s.singularize.to_sym }.last
            when DataMapper::Model
              rating_configs.find{ |model,conf| conf[:by][:model] == raters_or_model.to_s }.last
            else raise("invalid value: #{raters_or_model.inspect}")
          end
        end

        # rating_model_for(:authors)  #=> RateableUserRating
        # rating_model_for(User)      #=> RateableUserRating
        def rating_model_for(raters_or_model)
          cfg = rating_config_for(raters_or_model)
					cfg[:model].constantize
        end

      end
  
      module InstanceMethods
        
        def rating_togglable?
          self.class.rating_togglable?
        end
                
#        def anonymous_rating_togglable?
#          self.class.anonymous_rating_togglable?
#        end
        
        
        def rating_enabled?
          self.rating_togglable? ? attribute_get(:rating_enabled) : true
        end
        
#        def anonymous_rating_enabled?
#          self.anonymous_rating_togglable? ? attribute_get(:anonymous_rating_enabled) : false
#        end
        
        # convenience method
        def rating_disabled?
          !self.rating_enabled?
        end
        
#        # convenience method
#        def anonymous_rating_disabled?
#          !self.anonymous_rating_enabled?
#        end
        
        
        def disable_rating!
          if self.rating_togglable?
            if self.rating_enabled?
              self.rating_enabled = false
              self.save
            end
          else
            raise TogglableRatingDisabled, "Ratings cannot be toggled for #{self}"
          end
        end
        
        def enable_rating!
          if self.rating_togglable?
            unless self.rating_enabled?
              self.rating_enabled = true
              self.save
            end
          else
            raise TogglableRatingDisabled, "Ratings cannot be toggled for #{self}"
          end
        end
        
=begin
        def disable_anonymous_rating!
          if self.anonymous_rating_togglable?
            if self.anonymous_rating_enabled?
              self.update(:anonymous_rating_enabled => false)
            end
          else
            raise TogglableAnonymousRatingDisabled, "Anonymous Ratings cannot be toggled for #{self}"
          end
        end
        
        def enable_anonymous_rating!
          if self.anonymous_rating_togglable?
            unless self.anonymous_rating_enabled?
              self.update(:anonymous_rating_enabled => true)
            end
          else
            raise TogglableAnonymousRatingDisabled, "Anonymous Ratings cannot be toggled for #{self}"
          end
        end
=end
				
        def rate(rating, rater)
          unless self.rating_enabled?
            raise(RatingDisabled, "Ratings are not enabled for #{self}")
          end

          config  = self.class.rating_config_for(rater.class)

          unless config[:with].include?(rating)
            raise(ImpossibleRatingValue, "Rating (#{rating}) must be in #{config[:with].inspect}")
          end

          #if r = self.user_rating(rater)
          #if r = self.rating_association_for(rating_model)(rater)
          if r = self.rating_of(rater)
            if r.rating != rating
              r.update(:rating => rating) or raise
            end
          else
            # FIXME: save or raise
            res = rating_assoc_for(rater).create(config[:by][:key] => rater.id, :rating => rating)
            #res = rating_model.create(rater_name => rater, rateable_name => self, :rating => rating)
            #res = self.ratings.create(self.rater => user, :rating => rating)
            raise(res.errors.inspect) unless res.saved?
            res
          end

        end

        # average_rating_of(:users) => nil
        # average_rating_of(Account) => 3.76
        def average_rating_of(raters_or_model)
          rating_model = self.class.rating_model_for(raters_or_model)
          conditions = {self.class.rateable_fk => self.id}
          c = rating_model.count(conditions)
          c > 0 ? rating_model.sum(:rating, conditions).to_f / c : nil
        end

        def rating_assoc_for(rater)
          config = self.class.rating_config_for(rater.class)
          self.send(config[:as])
        end

				# FIXME rating_for or rating_of???
				
        def rating_of(rater)
          raise unless rater.is_a? DataMapper::Resource
          config = self.class.rating_config_for(rater.class)
          rating_assoc_for(rater).first(config[:by][:key] => rater.id)
        end

				#alias_method :rating_for, :rating_of
        
      end
      
    end
  end
end
