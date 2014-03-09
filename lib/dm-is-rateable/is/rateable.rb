require 'dm-is-rateable/is/rating'
require 'dm-is-rateable/is/rateable_extensions'
require 'dm-is-rateable/is/helper'

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

      # is :rateable, :by => :users, :with => 0..5, :as => :user_ratings, :model => 'SpecialUserRating' do
      #   def xyz; true; end
      # end
      #
      # is :rateable, :by => {:name => :user, :key => :user_id, :model => 'User'}
      def is_rateable(options = {}, &customizer)

        extend  ClassMethods
        include InstanceMethods

        options = Helper.complete_options(options, self)

        initialize_and_store_configuration(options)

        # add rating config
        self.rating_configs << options

        rating_model = generate_rating_model(options[:model])
        configure_rating_model(rating_model, options, &customizer)
        configure_self(options)
        configure_rater_model(options[:by][:model].constantize, options)
      end

    private

      def initialize_and_store_configuration(config)
        if self.respond_to?(:rating_configs)
          existing_config = rating_configs.find{ |other|
            other[:by][:model] == config[:by][:model] &&
            other[:concerning] == config[:concerning]
          }
          raise("duplicate is :rateable, :by => #{rater[:model]}") if existing_config.present?
        else
          class_attribute :rating_configs
          self.rating_configs = []
        end
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
        rater = options[:by]
        rating_name = options[:rating_name]

        self.has n, options[:as], options[:model], :constraint => :destroy!

        define_method("average_#{rater[:name]}_#{rating_name.underscore}") do
          average_rating_of(rater[:model].constantize)
        end
      end

      #
      def configure_rating_model(model,options,&customizer)
        raise unless model.is_a? DataMapper::Model

        rateable_key = Helper.key_name_from(self.name)
        rater = options[:by]
        rating_type, rating_options = Helper.property_options_from_with_option(options[:with])

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

        model.class_eval(&customizer) if customizer
      end

      # make the ratings accessable from the rater model through setting up a has-n relationship.
      def configure_rater_model(rater_model,options)
        ratings_name = (self.name + options[:rating_name]).underscore.pluralize

        rater_model.has n, ratings_name, :model => options[:model]
      end


    end#Rateable
  end#Is
end#DataMapper
