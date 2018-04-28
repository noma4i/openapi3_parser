# frozen_string_literal: true

require "openapi3_parser/node_factory_refactor/type_checker"
require "openapi3_parser/node_factory_refactor/object_factory/validator"

module Openapi3Parser
  module NodeFactoryRefactor
    module ObjectFactory
      class NodeBuilder
        def self.errors(factory)
          new(factory).errors
        end

        def self.node_data(factory)
          new(factory).node_data
        end

        def initialize(factory)
          @factory = factory
          @validatable = Validation::Validatable.new(factory)
        end

        def errors
          return validatable.collection if factory.nil_input?
          TypeChecker.validate_type(validatable, type: ::Hash)
          return validatable.collection if validatable.errors.any?
          validate(raise_on_invalid: false)
          validatable.collection
        end

        def node_data
          return build_node_data if factory.nil_input?
          TypeChecker.raise_on_invalid_type(factory.context, type: ::Hash)
          validate(raise_on_invalid: true)
          build_node_data
        end

        private_class_method :new

        private

        attr_reader :factory, :validatable

        def validate(raise_on_invalid:)
          Validator.call(factory, validatable, raise_on_invalid)
        end

        def build_node_data
          return if factory.nil_input? && factory.data.nil?

          factory.data.each_with_object({}) do |(key, value), memo|
            memo[key] = resolve_value(key, value)
          end
        end

        def resolve_value(key, value)
          config = factory.field_configs[key]
          resolved_value = value.respond_to?(:node) ? value.node : value

          # let a field config default take precedence if value is a nil_input?
          if (value.respond_to?(:nil_input?) && value.nil_input?) || value.nil?
            default = config&.default(factory)
            default.nil? ? resolved_value : default
          else
            resolved_value
          end
        end
      end
    end
  end
end
