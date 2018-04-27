# frozen_string_literal: true

require "openapi3_parser/node_factory_refactor/type_checker"

module Openapi3Parser
  module NodeFactoryRefactor
    module ObjectFactory
      class NodeBuilder
        def self.errors(factory)
          new(factory).errors
        end

        def self.data(factory)
          new(factory).data
        end

        def initialize(factory)
          @factory = factory
          @validatable = Validation::Validatable.new(factory)
        end

        def errors
          return validatable.collection if factory.nil_input?
          TypeChecker.validate_type(validatable, type: ::Hash)
          return validatable.collection if validatable.errors.any?
          validatable.collection
        end

        def data
          return default_value if factory.nil_input?
          TypeChecker.raise_on_invalid_type(factory.context, type: ::Hash)

          factory.processed_input.each_with_object({}) do |(key, value), memo|
            memo[key] = resolve_value(key, value)
          end
        end

        private_class_method :new

        private

        attr_reader :factory, :validatable

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

        def default_value
          if factory.nil_input? && factory.default.nil?
            nil
          else
            factory.processed_input
          end
        end
      end
    end
  end
end
