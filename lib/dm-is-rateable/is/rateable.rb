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
              name = by_option.to_s.singularize.to_sym
              {
                :name => name,
                :model => name.to_s.camelize,
                :key => Inflector.foreign_key(name.to_s).to_sym,
                :type => Integer,
                :options => { :required => true, :min => 0 } # FIXME only merge :min when type is integer
              }
            when Hash
              by_option.assert_valid_keys(:name,:key,:type,:model,:options)
              by_option
            when nil then raise ":by option missing"
            else raise "invalid value for :by: #{by_option}"
          end
        end
      end
      
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

      # is :rateable, :by => :users, :with => 0..5, :as => :user_ratings, :model => 'SpecialUserRating' do
      #   def xyz; true; end
      # end
      #
      # is :rateable, :by => {:name => :user, :fk => :user_id, :model => 'User'}
      def is_rateable(options = {},&enhancer)
        
        extend  ClassMethods
        include InstanceMethods

        rater = Helper.infer_rater(options[:by])

        raise(NotImplementedError,':model options not supported yet') if options[:model]
        
        options = {
          :with => 0..5,
          :by => rater,
          :as => "#{rater[:name]}_ratings".to_sym,
          :timestamps => true,
          :model => "#{self.name}#{rater[:model]}Rating"
        }.merge(options)

        # FIXME remove class attributes that assume only one rating
        #class_attribute :allowed_ratings
        #self.allowed_ratings = options[:with]
        #
        #class_attribute :rateable_model
        #self.rateable_model = options[:model]
        #
        #class_attribute :rateable_key
        ##self.rateable_key = rateable_model.underscore.to_sym
        #self.rateable_key = rateable_model.underscore.to_sym

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

        remix n, Rating, :as => options[:as], :model => options[:model], :for => rater[:name]

        class_attribute :remixed_rating

        remix_name = options[:model].underscore.to_sym

        #self.remixed_rating = remixables[:rating]
        self.remixed_rating = remixables[:rating][remix_name] # TODO remix_name or fk_name?

        # determine property type based on supplied values
        rating_type = Helper.deduce_rating_type(options[:with])

        #class_attribute :rater_fk
        ##self.rater_fk = rater_opts.try(:[],:fk) # tmp_rater_fk
        #self.rater_fk = rater[:key] #rater[:key]

        # close on this because enhance will class_eval in remixable model scope 
        rateable_key = self.rateable_fk

        # enhance the rating model
        enhance :rating, options[:model] do

          property :rating, rating_type, :required => true
          #property :rating, rating_type, :required => true

          # XXX
          #p "-"*10
          #p options[:as]
          #belongs_to options[:as], model_name

          #if options[:rater]
          #  property rater_name, rater_type, rater_property_opts # rater
          #  belongs_to rater_association
          #
          #  parent_assocation = parent_key.to_s.gsub(/_id/, '').to_sym
          #  validates_uniqueness_of rater_name, :when => :testing_association, :scope => [parent_assocation]
          #  validates_uniqueness_of rater_name, :when => :testing_property, :scope => [parent_key]
          #end

          if rater
            property rater[:key], rater[:type], rater[:options]
            belongs_to rater[:name] # FIXME key

            parent_assocation = rateable_key.to_s.gsub(/_id/, '').to_sym
            validates_uniqueness_of rater[:key], :when => :testing_association, :scope => [parent_assocation]
            validates_uniqueness_of rater[:key], :when => :testing_property, :scope => [rateable_key]
          end
          
          timestamps(:at) if options[:timestamps]
          
          class_eval(&enhancer) if enhancer
        end

        # create average method for the ratings, e.g. for users: average_user_rating
        #singular_reader = remixed_rating[:reader].to_s.singularize
        singular_name = options[:as].to_s.singularize

        define_method("average_#{singular_name}") do
          average_rating_of(rater[:name].to_s.pluralize.to_sym)
        end

=begin
        self.class_eval(<<-EOS, __FILE__, __LINE__ + 1)
          def average_#{singular_reader}
            scope = { self.class.rateable_fk => self.id }
            model_class =  self.class.remixables[:rating][rateable_key][:model]
            rating_sum = model_class.sum(:rating, scope).to_f
            rating_count = model_class.count(scope).to_f
            rating_count > 0 ? rating_sum / rating_count : 0
          end
        EOS
=end

      end

      module ClassMethods
        
        def rating_togglable?
          self.properties.named? :rating_enabled
        end
                
        def anonymous_rating_togglable?
          self.properties.named? :anonymous_rating_enabled
        end
        
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
          Kernel.const_get(cfg[:model])
        end

        #def average_rating_for(rateable,rater_model)
        #  raise unless rater_model.is_a? DataMapper::Model
        #  cfg = rating_config_for(rater_model)
        #  rateable.send("average_#{cfg[:as].to_s.singularize}")
        #end

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
        
        
        #def rater
        #  self.class.rater_fk.to_s.gsub(/_id/, '').to_sym
        #end

        # derpecated
        #def rating
        #  puts 'deprecated: use average_xyz_rating'
        #  scope = { self.class.rateable_fk => self.id }
        #  model_class =  self.class.remixables[:rating][rateable_key][:model]
        #  rating_sum = model_class.sum(:rating, scope).to_f
        #  rating_count = model_class.count(scope).to_f
        #  rating_count > 0 ? rating_sum / rating_count : 0
        #end

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
          if r = self.rating_for(rater)
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

        #def rating_config_for(rater_cls)
        #  self.class.rating_configs.find{ |model,conf| conf[:by][:model] == rater_cls.to_s }
        #end

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

        def rating_for(rater)
          raise unless rater.is_a? DataMapper::Resource
          config = self.class.rating_config_for(rater.class)
          rating_assoc_for(rater).first(config[:by][:key] => rater.id)
        end
        
#        def rate(rating, rater = nil)
#          unless self.rating_enabled?
#            raise(RatingDisabled, "Ratings are not enabled for #{self}")
#          end
#
#          unless self.class.allowed_ratings.include?(rating)
#            raise(ImpossibleRatingValue, "Rating (#{rating}) must be in #{allowed_ratings.inspect}")
#          end
#
#          if rater
#            if r = self.user_rating(rater)
#              if r.rating != rating
#                r.update(:rating => rating) or raise
#              end
#            else
#              # FIXME: save or raise
#              rater_type = rater.class.name
#              rater_name = rater_type.underscore.to_sym
#              rateable_name = self.class.name.underscore.to_sym
#              rating_model = Kernel.const_get("#{self.class.name}#{rater_type}Rating") # FIXME get model name
#              res = rating_model.create(rater_name => rater, rateable_name => self, :rating => rating)
#              #res = self.ratings.create(self.rater => user, :rating => rating)
#              raise(res.errors.inspect) unless res.saved?
#              res
#            end
#          else
#            unless self.anonymous_rating_enabled?
#              raise(AnonymousRatingDisabled, "Anonymous ratings are not enabled for #{self}")
#            end
#
#            # FIXME: save or raise
#            res = self.ratings.create(:rating => rating)
#            #rating_model = Kernel.const_get("#{self.class.name}#{rater_type}Rating") # FIXME get model name
#            #res = rating_model.create(rater_name => user, rateable_name => self, :rating => rating)
#            raise(res.errors.inspect) unless res.saved?
#            res
#          end
#
#        end

        #def user_rating(user, conditions = {})
        #  self.ratings(conditions.merge(self.class.rater_fk => user.id)).first
        #end
        
      end

=begin
      # FIXME is :rateable, :by => :user
      def is_rateable(options = {})

        extend  ClassMethods
        include InstanceMethods

        options = {
          :allowed_ratings => (0..5),
          :timestamps => true,
          :as => nil,
          :model => "#{self}Rating"
        }.merge(options)

        class_attribute :allowed_ratings
        self.allowed_ratings = options[:allowed_ratings]

        class_attribute :rateable_model
        self.rateable_model = options[:model]

        class_attribute :rateable_key
        self.rateable_key = rateable_model.underscore.to_sym

        #def rater_fk_name(name)
        #  name ? DataMapper::Inflector.foreign_key(name.to_s).to_sym : :user_id
        #end

        def rater_fk_name(name)
          DataMapper::Inflector.foreign_key((name || :user).to_s).to_sym
        end

        rater_o = options[:rater]
        rater_n = if rater_o
          rater_o.is_a?(Hash) ? (rater_o[:name] || :user) : rater_o
        end

        #remix n, Rating, :as => options[:as], :model => options[:model], :for => rater_n

        # FIXME TripUserRating not UserTripRating?
        model_name = "#{self}#{rater_n.to_s.camelize}Rating" if rater_n
        model_name ||= options[:model]

        remix n, Rating, :as => options[:as], :model => model_name, :for => rater_n

        remix_name = model_name.underscore.to_sym

        puts "model name: #{model_name}"
        puts "rater name: #{rater_n}"
        puts "remix_name: #{remix_name.inspect}"
        puts "remixables: #{remixables}"
        puts "rateable_key: #{rateable_key.inspect}"

        class_attribute :remixed_rating

        #self.remixed_rating = remixables[:rating]
        self.remixed_rating = remixables[:rating][remix_name]

        if remixed_rating[:reader] != :ratings
          p "creating alias for :ratings : :#{remixed_rating[:reader]}"
          self.class_eval(<<-EOS, __FILE__, __LINE__ + 1)
            alias :ratings :#{remixed_rating[:reader]}
          EOS
        end

        #if remixed_rating[:reader] != :ratings
        #  self.class_eval(<<-EOS, __FILE__, __LINE__ + 1)
        #    alias :ratings :#{remixed_rating[rateable_key][:reader]}
        #  EOS
        #end

        # determine property type based on supplied values
        rating_type = Helper.deduce_rating_type(options[:allowed_ratings])
        #rating_type = case options[:allowed_ratings]
        #  when Range then
        #    options[:allowed_ratings].first.is_a?(Integer) ? Integer : String
        #  when Enum  then
        #    require 'dm-types'
        #    DataMapper::Types::Enum
        #  else
        #    msg = "#{options[:allowed_ratings].class} is no supported rating type"
        #    raise ImpossibleRatingType, msg
        #end


        # prepare rating enhancements

        #def rater_fk(name)
        #  name ? DataMapper::Inflector.foreign_key(name.to_s.singularize).to_sym : :user_id
        #end


        #tmp_rater_fk = if options[:rater]
        #  rater_opts = options[:rater]
        #  rater_name = rater_opts.is_a?(Hash) ? (rater_opts.delete(:name) || :user_id) : rater_fk_name(rater_opts)
        #  rater_type = rater_opts.is_a?(Hash) ? (rater_opts.delete(:type) || Integer)  : Integer
        #  #rater_property_opts = rater_opts.is_a?(Hash) ? rater_opts : { :required => true }
        #  rater_property_opts = rater_opts.is_a?(Hash) ? rater_opts : { :required => false }
        #  rater_property_opts.merge!(:min => 0) if rater_type == Integer # Match referenced column type
        #  rater_association = rater_name.to_s.gsub(/_id/, '').to_sym
        #
        #  rater_name
        #else
        #  nil # no rater association established
        #end

        # dm-rateable:
        # options[:rater] can be
        # - hash: {:name, :type} + dm-property-opts
        # - string/sym like :user
        rater_opts = if options[:rater]
          opts = options[:rater]
          r_name = (opts.is_a?(Hash) ? (opts[:name] || :user) : opts).to_sym
          r_fk = DataMapper::Inflector.foreign_key(r_name)
          #r_type = opts.is_a?(Hash) ? (opts[:type] || Integer) : Integer
          r_type = opts[:type] if opts.is_a?(Hash)
          r_type ||= Integer
          r_property = opts.is_a?(Hash) ? opts.except(:name,:type) : {:required => false}
          r_property.merge!(:min => 0) if r_type == Integer

          {:name => r_name, :fk => r_fk, :type => r_type, :property => r_property}
        else
          nil
        end

        #class_inheritable_reader :rater_fk
        class_attribute :rater_fk
        self.rater_fk = rater_opts.try(:[],:fk) # tmp_rater_fk

        # close on this because enhance will class_eval in remixable model scope
        parent_key = self.rateable_fk

        #enhance :rating, rateable_model do
        enhance :rating, model_name do

          property :rating, rating_type, :required => true
          property :rating, rating_type, :required => true

          # XXX
          #p "-"*10
          #p options[:as]
          #belongs_to options[:as], model_name

          #if options[:rater]
          #  property rater_name, rater_type, rater_property_opts # rater
          #  belongs_to rater_association
          #
          #  parent_assocation = parent_key.to_s.gsub(/_id/, '').to_sym
          #  validates_uniqueness_of rater_name, :when => :testing_association, :scope => [parent_assocation]
          #  validates_uniqueness_of rater_name, :when => :testing_property, :scope => [parent_key]
          #end

          if rater_opts
            property rater_opts[:fk], rater_opts[:type], rater_opts[:property]
            belongs_to rater_opts[:name]

            parent_assocation = parent_key.to_s.gsub(/_id/, '').to_sym
            validates_uniqueness_of rater_opts[:fk], :when => :testing_association, :scope => [parent_assocation]
            validates_uniqueness_of rater_opts[:fk], :when => :testing_property, :scope => [parent_key]
          end

          timestamps(:at) if options[:timestamps]

        end

      end
=end
      
    end
  end
end
