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

        create_rating_model(options, &customizer)
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
          if existing_config.present?
            raise("duplicate is :rateable, :by => #{config[:by][:model]}")
          end
        else
          class_attribute :rating_configs
          self.rating_configs = []
        end
      end

      # Copied from dm-is-remixable
      def create_rating_model(options, &customizer)
        parts = options[:model].split('::')
        name = parts.last
        namespace = (parts-[parts.last]).join('::').constantize

        rating_model = Model.new(name, namespace) do
          include DataMapper::Resource

          property :id, DataMapper::Property::Serial
        end

        rateable_key = Helper.key_name_from(self.name)
        rater = options[:by]
        rating_type, rating_options = Helper.property_options_from_with_option(options[:with])

        rating_options = {:required => true}.merge(rating_options||{})

        rateable_class = self.name
        rateable_name = rateable_class.underscore

        # define aliases accessible on all ratings
        rating_model.instance_eval do
          property :rating, rating_type, rating_options
          property rater[:key], rater[:type], rater[:options]
          property rateable_key, Integer, :required => true, :min => 0

          belongs_to rater[:name], rater[:model]
          belongs_to rateable_name, rateable_class

          if rater
            belongs_to rater[:name], rater[:model]

            # FIXME
            #validates_uniqueness_of rater[:key], :when => :testing_association, :scope => [parent_assocation]
            validates_uniqueness_of rater[:key], :when => :testing_property, :scope => [rateable_key]
          end

          timestamps(:at) if options[:timestamps] # TODO :timestamps => :on

          alias_method(:rater,rater[:name])
          alias_method(:rater=,"#{rater[:name]}=")
          alias_method(:rateable,rateable_name)
          alias_method(:rateable=,"#{rateable_name}=")

          alias_method(:rater_id,"#{rater[:name]}_id")
          alias_method(:rater_id=,"#{rater[:name]}_id=")
          alias_method(:rateable_id,"#{rateable_name}_id")
          alias_method(:rateable_id=,"#{rateable_name}_id=")

          instance_eval(&customizer) if customizer
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

        rating_options = {:required => true}.merge(rating_options||{})

        rateable_class = self.name
        rateable_name = rateable_class.underscore

        # define aliases accessible on all ratings
        model.instance_eval do
          property :rating, rating_type, rating_options
          property rater[:key], rater[:type], rater[:options]
          property rateable_key, Integer, :required => true, :min => 0

          belongs_to rater[:name], rater[:model]
          belongs_to rateable_name, rateable_class

          if rater
            belongs_to rater[:name], rater[:model]

            # FIXME
            #validates_uniqueness_of rater[:key], :when => :testing_association, :scope => [parent_assocation]
            validates_uniqueness_of rater[:key], :when => :testing_property, :scope => [rateable_key]
          end

          timestamps(:at) if options[:timestamps] # TODO :timestamps => :on

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
