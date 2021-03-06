# frozen_string_literal: true

require "ostruct"

require "openapi3_parser/context"
require "openapi3_parser/node_factory"
require "openapi3_parser/node_factory/field_config"
require "openapi3_parser/node_factory/object/node_builder"
require "openapi3_parser/node_factory/object/validator"
require "openapi3_parser/validation/error_collection"

module Openapi3Parser
  module NodeFactory
    module Object
      include NodeFactory

      module ClassMethods
        def field(name, **options)
          @field_configs ||= {}
          @field_configs[name] = FieldConfig.new(options)
        end

        def field_configs
          @field_configs || {}
        end

        def allow_extensions
          @allow_extensions = true
        end

        def disallow_extensions
          @allow_extensions = false
        end

        def allowed_extensions?
          @allow_extensions == true
        end

        def mutually_exclusive(*fields, required: false)
          @mutually_exclusive ||= []
          @mutually_exclusive << OpenStruct.new(
            fields: fields, required: required
          )
        end

        def mutually_exclusive_fields
          @mutually_exclusive || []
        end
      end

      def self.included(base)
        base.extend(NodeFactory::ClassMethods)
        base.extend(ClassMethods)
        base.class_eval do
          input_type Hash
        end
      end

      def allowed_extensions?
        self.class.allowed_extensions?
      end

      def mutually_exclusive_fields
        self.class.mutually_exclusive_fields
      end

      def field_configs
        self.class.field_configs || {}
      end

      private

      def process_input(input)
        field_configs.each_with_object(input.dup) do |(field, config), memo|
          memo[field] = nil unless memo[field]
          next unless config.factory?
          next_context = Context.next_field(context, field)
          memo[field] = config.initialize_factory(next_context, self)
        end
      end

      def validate_input
        validator = Validator.new(processed_input, self)
        Validation::ErrorCollection.combine(super, validator.errors)
      end

      def build_node(input)
        data = NodeBuilder.new(input, self).data
        build_object(data, context)
      end

      def build_object(data, _context)
        data
      end

      def build_resolved_input
        processed_input.each_with_object({}) do |(key, value), memo|
          next if value.respond_to?(:nil_input?) && value.nil_input?
          memo[key] = if value.respond_to?(:resolved_input)
                        value.resolved_input
                      else
                        value
                      end
        end
      end
    end
  end
end
