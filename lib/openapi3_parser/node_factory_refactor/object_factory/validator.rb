# frozen_string_literal: true

require "openapi3_parser/array_sentence"
require "openapi3_parser/error"

module Openapi3Parser
  module NodeFactoryRefactor
    module ObjectFactory
      class Validator
        using ArraySentence

        def self.call(*args)
          new(*args).call
        end

        def initialize(factory, validatable, building_node)
          @factory = factory
          @validatable = validatable
          @building_node = building_node
        end

        def call
          check_missing_required_fields
          check_unexpected_fields
          check_mutually_exclusive_fields
          check_invalid_fields
        end

        private_class_method :new

        private

        attr_reader :factory, :validatable, :building_node

        def location_summary
          factory.context.location_summary
        end

        def check_missing_required_fields
          fields = missing_required_fields
          return if fields.empty?

          if building_node
            raise Openapi3Parser::Error::MissingFields,
                  "Missing required fields for #{location_summary}: "\
                  "#{fields.sentence_join}"
          else
            validatable.add_error(
              "Missing required fields: #{fields.sentence_join}"
            )
          end
        end

        def missing_required_fields
          configs = factory.field_configs
          configs.each_with_object([]) do |(name, field_config), memo|
            field = factory.raw_input[name]
            is_nil = if field.respond_to?(:nil_input?)
                       field.nil_input?
                     else
                       field.nil?
                     end
            memo << name if field_config.required?(factory) && is_nil
          end
        end

        def check_unexpected_fields
          fields = unexpected_fields
          return if fields.empty?

          if building_node
            raise Openapi3Parser::Error::UnexpectedFields,
                  "Unexpected fields for #{location_summary}: "\
                  "#{fields.sentence_join}"
          else
            validatable.add_error(
              "Unexpected fields: #{fields.sentence_join}"
            )
          end
        end

        def unexpected_fields
          unexpected_keys = factory.raw_input.keys - factory.field_configs.keys
          if factory.allowed_extensions?
            unexpected_keys.reject do |key|
              key =~ NodeFactoryRefactor::EXTENSION_REGEX
            end
          else
            unexpected_keys
          end
        end

        def check_mutually_exclusive_fields
          mutually_exclusive = MututallyExclusiveFields.new(factory)
          required_errors = mutually_exclusive.required_errors
          exclusive_errors = mutually_exclusive.exclusive_errors

          if building_node
            if required_errors.any?
              raise Openapi3Parser::Error::MissingFields,
                    "Mutually exclusive fields for #{location_summary}: "\
                    "#{required_errors.first}"
            end

            if exclusive_errors.any?
              raise Openapi3Parser::Error::UnexpectedFields,
                    "Mutually exclusive fields for #{location_summary}: "\
                    "#{exclusive_errors.first}"
            end
          else
            validateable.add_errors(required_errors)
            validateable.add_errors(exclusive_errors)
          end
        end

        def check_invalid_fields
          # todo
        end

        class MututallyExclusiveFieldErrors
          using ArraySentence

          def initialize(factory)
            @factory = factory
          end

          def required_errors
            errors[:required]
          end

          def exlcusive_errors
            errors[:exclusive]
          end

          def errors
            @errors ||= begin
                          default = { required: [], exclusive: [] }
                          factory
                            .mutually_exclusive_fields
                            .each_with_object(default) do |exclusive, errors|
                              add_error(errors, exclusive)
                            end
                        end
          end

          private

          attr_reader :factory

          def add_error(errors, mutually_exclusive)
            fields = mutually_exclusive.fields
            number_non_nil = count_non_nil_fields(fields, factory.raw_input)
            if number_non_nil.zero? && mutually_exclusive.required
              errors[:required] << required_error(fields)
            elsif number_non_nil > 1
              errors[:exclusive] << exclusive_error(fields)
            end
          end

          def count_non_nil_fields(fields, input)
            fields.count do |field|
              data = input[field]
              data.respond_to?(:nil_input?) ? !data.nil_input? : !data.nil?
            end
          end

          def required_error(fields)
            "One of #{fields.sentence_join} is required"
          end

          def exclusive_error(fields)
            "#{fields.sentence_join} are mutually exclusive fields"
          end
        end
      end
    end
  end
end
