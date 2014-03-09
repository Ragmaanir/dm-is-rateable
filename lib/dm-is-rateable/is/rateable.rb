require 'dm-is-rateable/is/rating'
require 'dm-is-rateable/is/rateable_extensions'

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

        def self.key_name_from(model_name)
          model_name.demodulize.underscore + '_id'
        end

        def self.deduce_rating_type(allowed_ratings)
          case allowed_ratings
            when Range then
              case allowed_ratings.first
                when Fixnum then [Integer, {:min => allowed_ratings.min, :max => allowed_ratings.max}]
                when Float then [Float, {:min => allowed_ratings.min, :max => allowed_ratings.max}]
                else String
              end
            when Array then
              require 'dm-types'
              DataMapper::Property::Enum[*allowed_ratings]
            else
              raise ImpossibleRatingType, "#{allowed_ratings.class} is no supported rating type"
          end
        end

        #
        #
        def self.infer_rater(by_option)
          result = case by_option
            when Symbol
              name = by_option.to_s.singularize
              {
                :name => name.to_sym,
                :model => name.classify,
                :key => Inflector.foreign_key(name).to_sym
              }
            when Hash
              by_option.assert_valid_keys(:name,:key,:type,:model,:options)
              name = by_option[:name].to_s
              key = by_option[:key] || Inflector.foreign_key(name).to_sym
              model = key.to_s.gsub(/_id/,'').classify
              {
                :model => model,
                :key => key
              }.merge(by_option)
            when DataMapper::Model
              name = by_option.name.downcase
              {
                :name => name.to_sym,
                :model => by_option.name,
                :key => Inflector.foreign_key(name).to_sym
              }
            when nil then raise ":by option missing"
            else raise "invalid value for :by: #{by_option}"
          end

          result = {:type => Integer}.merge(result)
          result = { :options => { :required => true, :min => 0 } }.merge(result) if result[:type] == Integer
          result
        end

        #
        # Fills in defaults and adds values based on values passed in the options hash.
        #
        def self.complete_options(options,clz)
          raise("model option not supported") if options[:model]
          raise 'options :as and :concerning are mutually exclusive' if options[:as] and options[:concerning]
          rater = Helper.infer_rater(options[:by])

          concern = options[:concerning].to_s || ''
          rating_name = "#{concern.camelize}Rating"
          rateable_name = clz.name

          model = options[:model] || "#{rater[:model]}#{rateable_name}#{rating_name}"
          as = options[:as]
          as ||= if options[:model]
              model.underscore.pluralize.gsub("#{rateable_name.underscore}_",'')
            else
              #"ratings_by_#{rater[:name].to_s.pluralize}".to_sym
              concern_part = concern.blank? ? '' : "_#{concern}"
              "#{rater[:name]}#{concern_part}_ratings"
            end.to_sym

          options = {
            :with => 0..5,
            :by => rater,
            :as => as,
            :timestamps => true,
            :model => model,
            :rating_name => rating_name
          }.merge(options)

          options.freeze
        end

      end#Helper

      # is :rateable, :by => :users, :with => 0..5, :as => :user_ratings, :model => 'SpecialUserRating' do
      #   def xyz; true; end
      # end
      #
      # is :rateable, :by => {:name => :user, :key => :user_id, :model => 'User'}
      def is_rateable(options = {},&enhancer)

        extend  ClassMethods
        include InstanceMethods

        options = Helper.complete_options(options, self)

        rater = Helper.infer_rater(options[:by])

        if self.respond_to?(:rating_configs)
          raise("duplicate is :rateable, :by => #{rater[:model]}") if rating_configs.find{ |config|
            config[:by][:model] == rater[:model] and config[:concerning] == options[:concerning]
          }
        else
          class_attribute :rating_configs
          self.rating_configs = []
        end

        # add rating config
        self.rating_configs << options.merge(:by => rater)

        rating_model = generate_rating_model(options[:model])
        configure_rating_model(rating_model, options, &enhancer)
        configure_self(options)
        configure_rater_model(rater[:model].constantize, options)

      end

      # Copied from dm-is-remixable
      def generate_rating_model(full_name)
        parts = full_name.split('::')
        name = parts.last
        namespace = (parts-[parts.last]).join('::').constantize

        rating_model = Model.new(name, namespace) do
          include Rating
        end

        if DataMapper.const_defined?('Validations')
          # Port over any other validation contexts to this model.  Skip the
          # default context since it has already been included above.
          Rating.validators.contexts.each do |context, validators|
            next if context == :default
            rating_model.validators.contexts[context] = validators
          end
        end

        # Port the properties over
        Rating.properties.each do |prop|
          rating_model.property(prop.name, prop.class, prop.options)
        end

        Rating.__send__(:copy_hooks, rating_model)

        # event name is by default :create, :destroy etc
        Rating.instance_hooks.each do |event_name, hooks|
          [:after, :before].each do |callback|
            hooks[callback].each do |hook|
              rating_model.send(callback, event_name, hook[:name])
            end
          end
        end

        rating_model
      end

      #
      def configure_self(options)
        rater = Helper.infer_rater(options[:by])
        rating_name = options[:rating_name]

        self.has n, options[:as], options[:model], :constraint => :destroy!

        define_method("average_#{rater[:name]}_#{rating_name.underscore}") do
          average_rating_of(rater[:model].constantize)
        end
      end

      #
      def configure_rating_model(model,options,&enhancer)
        raise unless model.is_a? DataMapper::Model

        rateable_key = Helper.key_name_from(self.name)
        rater = Helper.infer_rater(options[:by])
        rating_type, rating_options = Helper.deduce_rating_type(options[:with])

        model.property :rating, rating_type, {:required => true}.merge(rating_options||{})
        model.property rater[:key], rater[:type], rater[:options]
        model.property rateable_key, Integer, :required => true, :min => 0

        model.belongs_to rater[:name], rater[:model]
        model.belongs_to self.name.underscore, self.name

        if rater
          model.belongs_to rater[:name], rater[:model]

          # FIXME
          #model.validates_uniqueness_of rater[:key], :when => :testing_association, :scope => [parent_assocation]
          model.validates_uniqueness_of rater[:key], :when => :testing_property, :scope => [rateable_key]
        end

        model.timestamps(:at) if options[:timestamps] # TODO :timestamps => :on

        rateable_name = self.name.underscore

        # define aliases accessible on all ratings
        model.instance_eval do
          alias_method(:rater,rater[:name])
          alias_method(:rater=,"#{rater[:name]}=")
          alias_method(:rateable,rateable_name)
          alias_method(:rateable=,"#{rateable_name}=")

          alias_method(:rater_id,"#{rater[:name]}_id")
          alias_method(:rater_id=,"#{rater[:name]}_id=")
          alias_method(:rateable_id,"#{rateable_name}_id")
          alias_method(:rateable_id=,"#{rateable_name}_id=")
        end

        model.class_eval(&enhancer) if enhancer
      end

      # make the ratings accessable from the rater model through setting up a has-n relationship.
      def configure_rater_model(rater_model,options)
        ratings_name = (self.name + options[:rating_name]).underscore.pluralize

        rater_model.has n, ratings_name, :model => options[:model]
      end


    end#Rateable
  end#Is
end#DataMapper
