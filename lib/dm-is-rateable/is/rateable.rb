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
      
      module Rating

        def self.included(base)
          base.extend ClassMethods
        end

        include DataMapper::Resource

        is :remixable

        property :id, Serial
  
        module ClassMethods

          # total rating for all rateable instances of this type
          def total_rating
            rating_sum = self.sum(:rating).to_f
            rating_count = self.count.to_f
            rating_count > 0 ? rating_sum / rating_count : 0
          end

        end
      end

      def is_rateable(options = {})
        
        extend  ClassMethods
        include InstanceMethods
        
        options = {
          :allowed_ratings => (0..5),
          :timestamps => true,
          :as => nil,
          :model => "#{self}Rating"
        }.merge(options)
        
        #@allowed_ratings = options[:allowed_ratings]        
        #class_inheritable_accessor :allowed_ratings
        
        #@rateable_model = options[:model]
        #class_inheritable_accessor :rateable_model
        
        #@rateable_key = @rateable_model.snake_case.to_sym
        #class_inheritable_accessor :rateable_key

        class_attribute :allowed_ratings
        self.allowed_ratings = options[:allowed_ratings]        
        
        class_attribute :rateable_model
        self.rateable_model = options[:model]
        
        class_attribute :rateable_key
        self.rateable_key = rateable_model.underscore.to_sym
        
        remix n, Rating, :as => options[:as], :model => options[:model]
        
        #@remixed_rating = remixables[:rating]
        #class_inheritable_reader :remixed_rating

        class_attribute :remixed_rating
        self.remixed_rating = remixables[:rating]
        
        if remixed_rating[:reader] != :ratings
          self.class_eval(<<-EOS, __FILE__, __LINE__ + 1)
            alias :ratings :#{remixed_rating[rateable_key][:reader]}
          EOS
        end

        # determine property type based on supplied values
        rating_type = case options[:allowed_ratings]
          when Range then
            options[:allowed_ratings].first.is_a?(Integer) ? Integer : String
          when Enum  then
            require 'dm-types'
            DataMapper::Types::Enum
          else
            msg = "#{options[:allowed_ratings].class} is no supported rating type" 
            raise ImpossibleRatingType, msg
        end


        # prepare rating enhancements

        def rater_fk(name)
          name ? DataMapper::Inflector.foreign_key(name.to_s.singularize).to_sym : :user_id
        end

        tmp_rater_fk = if options[:rater]
          rater_opts = options[:rater]
          rater_name = rater_opts.is_a?(Hash) ? (rater_opts.delete(:name) || :user_id) : rater_fk(rater_opts)
          rater_type = rater_opts.is_a?(Hash) ? (rater_opts.delete(:type) || Integer)  : Integer
          #rater_property_opts = rater_opts.is_a?(Hash) ? rater_opts : { :required => true }
          rater_property_opts = rater_opts.is_a?(Hash) ? rater_opts : { :required => false }
          rater_property_opts.merge!(:min => 0) if rater_type == Integer # Match referenced column type
          rater_association = rater_name.to_s.gsub(/_id/, '').to_sym

          rater_name
        else
          nil # no rater association established
        end

        #class_inheritable_reader :rater_fk
        class_attribute :rater_fk
        self.rater_fk = tmp_rater_fk

        # close on this because enhance will class_eval in remixable model scope 
        parent_key = self.rateable_fk

        enhance :rating, rateable_model do

          property :rating, rating_type, :required => true #, :nullable => false
          property :rating, rating_type, :required => true

          if options[:rater]
            property rater_name, rater_type, rater_property_opts # rater
            belongs_to rater_association

            parent_assocation = parent_key.to_s.gsub(/_id/, '').to_sym
            validates_uniqueness_of rater_name, :when => :testing_association, :scope => [parent_assocation]
            validates_uniqueness_of rater_name, :when => :testing_property, :scope => [parent_key]
          end

          if options[:timestamps]
            #property :created_at, DateTime
            #property :updated_at, DateTime
            timestamps :at
          end

        end

      end

      module ClassMethods
        
        def rating_togglable?
          self.properties.named? :rating_enabled
        end
                
        def anonymous_rating_togglable?
          self.properties.named? :anonymous_rating_enabled
        end
        
        def total_rating
          remixables[:rating][rateable_key][:model].total_rating
        end
        
        def rateable_fk
          demodulized_name = DataMapper::Inflector.demodulize(self.name)
          DataMapper::Inflector.foreign_key(demodulized_name).to_sym
        end

      end
  
      module InstanceMethods
        
        def rating_togglable?
          self.class.rating_togglable?
        end
                
        def anonymous_rating_togglable?
          self.class.anonymous_rating_togglable?
        end
        
        
        def rating_enabled?
          self.rating_togglable? ? attribute_get(:rating_enabled) : true
        end
        
        def anonymous_rating_enabled?
          self.anonymous_rating_togglable? ? attribute_get(:anonymous_rating_enabled) : false
        end
        
        # convenience method
        def rating_disabled?
          !self.rating_enabled?
        end
        
        # convenience method
        def anonymous_rating_disabled?
          !self.anonymous_rating_enabled?
        end
        
        
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
        
        
        def rater
          self.class.rater_fk.to_s.gsub(/_id/, '').to_sym
        end
        
        def rating
          scope = { self.class.rateable_fk => self.id }
          model_class =  self.class.remixables[:rating][rateable_key][:model]
          rating_sum = model_class.sum(:rating, scope).to_f
          rating_count = model_class.count(scope).to_f
          rating_count > 0 ? rating_sum / rating_count : 0
        end
        
        def rate(rating, user = nil)
          if self.rating_enabled?
            if self.class.allowed_ratings.include?(rating)
              if user
                if r = self.user_rating(user)
                  if r.rating != rating
                    r.update(:rating => rating) or raise
                  end
                else
                  # FIXME: save or raise
                  res = self.ratings.create(self.rater => user, :rating => rating)
                  raise(res.errors.inspect) unless res.saved?
                  res
                end
              else
                if self.anonymous_rating_enabled?
                  # FIXME: save or raise
                  res = self.ratings.create(:rating => rating)
                  raise(res.errors.inspect) unless res.saved?
                  res
                else
                  msg = "Anonymous ratings are not enabled for #{self}"
                  raise AnonymousRatingDisabled, msg                  
                end
              end
            else
              msg = "Rating (#{rating}) must be in #{allowed_ratings.inspect}"
              raise ImpossibleRatingValue, msg
            end
          else
            msg = "Ratings are not enabled for #{self}"
            raise RatingDisabled, msg
          end
        end

        def user_rating(user, conditions = {})
          self.ratings(conditions.merge(self.class.rater_fk => user.id)).first
        end
        
      end
      
    end
  end
end
