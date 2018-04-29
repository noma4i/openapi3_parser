# frozen_string_literal: true

require "openapi3_parser/error"
require "openapi3_parser/node_factory_refactor/type_checker"

module Openapi3Parser
  module NodeFactoryRefactor
    module ObjectFactory
      class FieldConfig
        def initialize(
          input_type: nil,
          factory: nil,
          required: false,
          default: nil,
          validate: nil
        )
          @given_input_type = input_type
          @given_factory = factory
          @given_required = required
          @given_default = default
          @given_validate = validate
        end

        def factory?
          !given_factory.nil?
        end

        def initialize_factory(context, parent_factory)
          if given_factory.is_a?(Class)
            given_factory.new(context)
          elsif given_factory.is_a?(Symbol)
            parent_factory.send(given_factory, context)
          else
            given_factory.call(context)
          end
        end

        def required?
          given_required
        end

        def check_input_type(validatable, building_node)
          return unless given_input_type || validatable.input.nil?

          if building_node
            TypeChecker.raise_on_invalid_type(validatable.context,
                                              type: given_input_type)
          else
            TypeChecker.validate_type(validatable, type: given_input_type)
          end
        end

        def validate_field(validatable, building_node)
          return if !given_validate || validatable.input.nil?

          run_validation(validatable)

          if building_node && validatable.errors.any?
            error = validatable.errors.first
            location_summary = error.context.location_summary
            raise Error::InvalidData,
                  "Invalid data for #{location_summary}: #{error.message}"
          end
        end

        def default(factory)
          return given_default.call if given_default.is_a?(Proc)
          return factory.send(given_default) if given_default.is_a?(Symbol)
          given_default
        end

        private

        attr_reader :given_input_type, :given_factory, :given_required,
                    :given_default, :given_validate

        def run_validation(validatable)
          if given_validate.is_a?(Proc)
            given_validate.call(validatable)
          elsif given_validate.is_a?(Symbol)
            validatable.factory.send(given_validate, validatable)
          elsif given_validate.respond_to?(:call)
            given_validate.call(validatable)
          else
            raise Error::NotCallable, "Expected a Proc, a Symbol or an object"\
                                      " responding to .call for validate"
          end
        end
      end
    end
  end
end
