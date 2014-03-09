module DataMapper
  module Is
    module Rateable

      Inflector = DataMapper::Inflector

      module Helper

        def self.key_name_from(model_name)
          model_name.demodulize.underscore + '_id'
        end

        # converts the value passed to :with => ... to DM-property type and options
        def self.property_options_from_with_option(allowed_ratings)
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
        def self.rater_from_by_option(by_option)
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

        DEFAULT_OPTIONS = {
          :with => 0..5,
          :timestamps => true
        }

        #
        # Fills in defaults and adds values based on values passed in the options hash.
        #
        def self.complete_options(options,clz)
          raise("model option not supported") if options[:model]
          raise 'options :as and :concerning are mutually exclusive' if options[:as] and options[:concerning]
          rater = Helper.rater_from_by_option(options[:by])

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

          options = DEFAULT_OPTIONS.merge(options).merge(
            :by => rater,
            :as => as,
            :model => model,
            :rating_name => rating_name
          )

          options.freeze
        end

      end#Helper
    end
  end
end
