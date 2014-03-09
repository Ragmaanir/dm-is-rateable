module DataMapper
  module Is
    module Rateable

      #
      module ClassMethods

        def rating_togglable?
          self.properties.named? :rating_enabled
        end

        def rateable_fk
          demodulized_name = DataMapper::Inflector.demodulize(self.name)
          DataMapper::Inflector.foreign_key(demodulized_name).to_sym
        end

        # Rateable.rating_config_for(:users)  #=> { :name => :user, :model => 'Account', ... }
        # Rateable.rating_config_for(User)    #=> { :model => 'User', :name => :author, ...  }
        def rating_config_for(raters_or_model,concern=nil)
          matches = case raters_or_model
            when Symbol
              rating_configs.select{ |conf|
                conf[:by][:name] == raters_or_model.to_s.singularize.to_sym
              }
            when DataMapper::Model
              rating_configs.select{ |conf|
                conf[:by][:model] == raters_or_model.to_s
              }
            else raise("expected model or symbol but got: #{raters_or_model.inspect}")
          end

          if matches.length>1
            raise "concern required, was: #{concern.inspect}" unless concern.is_a? Symbol
            matches.find{|conf| conf[:concerning] == concern }
          else
            matches.first
          end
        end

        # rating_model_for(:authors)  #=> RateableUserRating
        # rating_model_for(User)      #=> RateableUserRating
        def rating_model_for(raters_or_model,concern=nil)
          cfg = rating_config_for(raters_or_model,concern)
          cfg[:model].constantize
        end

      end

      module InstanceMethods

        def rating_togglable?
          self.class.rating_togglable?
        end

        def rating_enabled?
          self.rating_togglable? ? attribute_get(:rating_enabled) : true
        end

        # convenience method
        def rating_disabled?
          !self.rating_enabled?
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

        def rate(rating, rater, concern=nil)
          unless self.rating_enabled?
            raise(RatingDisabled, "Ratings are not enabled for #{self}")
          end

          config  = self.class.rating_config_for(rater.class, concern)

          unless config[:with].include?(rating)
            raise(ImpossibleRatingValue, "Rating (#{rating}) must be in #{config[:with].inspect}")
          end

          if r = self.rating_of(rater)
            if r.rating != rating
              r.update(:rating => rating) or raise
            end
          else
            # FIXME: save or raise
            #res = rating_assoc_for(rater).create(config[:by][:key] => rater.id, :rating => rating)
            res = ratings_of(rater.class,concern).create(config[:by][:key] => rater.id, :rating => rating)
            raise(res.errors.inspect) unless res.saved?
            res
          end

        end

        # average_rating_of(:users) => nil
        # average_rating_of(Account) => 3.76
        def average_rating_of(raters_or_model,concern=nil)
          rating_model = self.class.rating_model_for(raters_or_model,concern)
          conditions = {self.class.rateable_fk => self.id}
          c,sum = rating_model.aggregate(:rating.count, :rating.sum, conditions)
          #c > 0 ? rating_model.sum(:rating, conditions).to_f / c : nil
          c > 0 ? sum.to_f / c : nil
        end

        def ratings_of(rater_model,concern=nil)
          raise unless rater_model.is_a? DataMapper::Model
          config = self.class.rating_config_for(rater_model,concern)
          self.send(config[:as])
        end

        def rating_of(rater,concern=nil)
          raise "rater is no DataMapper::Resource: #{rater.inspect}" unless rater.is_a? DataMapper::Resource
          config = self.class.rating_config_for(rater.class,concern)
          ratings_of(rater.class,concern).first(config[:by][:key] => rater.id)
        end

      end#InstanceMethods

    end#Rateable
  end#Is
end#DataMapper
