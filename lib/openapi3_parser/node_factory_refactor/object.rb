# frozen_string_literal: true

require "forwardable"
require "ostruct"

require "openapi3_parser/context"
require "openapi3_parser/node_factory_refactor/object_factory/dsl"
require "openapi3_parser/node_factory/field_config"
require "openapi3_parser/node_factory/object/node_builder"
require "openapi3_parser/node_factory/object/validator"
require "openapi3_parser/validation/error_collection"

module Openapi3Parser
  module NodeFactoryRefactor
    class Object
      extend Forwardable
      extend ObjectFactory::Dsl

      def_delegators "self.class",
                     :field_configs,
                     :allowed_extensions?,
                     :mutually_exclusive_fields,
                     :allowed_default?

      attr_reader :context, :processed_input

      def initialize(context)
        @context = context
        input = nil_input? ? default : context.input
        @processed_input = input.nil? ? nil : process_input(input)
      end

      def resolved_input
        raw_resolved_input
      end

      def raw_resolved_input
        @raw_resolved_input ||= build_resolved_input
      end

      def raw_input
        context.input
      end

      def nil_input?
        context.input.nil?
      end

      def valid?
        errors.empty?
      end

      def errors
        @errors ||= build_errors
      end

      def node
        @node ||= build_valid_node
      end

      def default
        nil
      end

      private

      def validate(_input, _context); end

      def process_input(input)
        self.class.field_configs.each_with_object(input.dup) do |(field, config), memo|
          memo[field] = nil unless memo[field]
          next unless config.factory?
          next_context = Context.next_field(context, field)
          memo[field] = config.initialize_factory(next_context, self)
        end
      end

      def build_resolved_input
        return unless processed_input

        processed_input.each_with_object({}) do |(key, value), memo|
          next if value.respond_to?(:nil_input?) && value.nil_input?
          memo[key] = if value.respond_to?(:resolved_input)
                        value.resolved_input
                      else
                        value
                      end
        end
      end

      def build_errors
        return Validation::ErrorCollection.new if nil_input? && allowed_default?
        unless validate_type.nil?
          error = Validation::Error.new(
            "Invalid type. #{validate_type}", context, self.class
          )
          return Validation::ErrorCollection.new([error])
        end
        validator = NodeFactory::Object::Validator.new(processed_input, self)
        Validation::ErrorCollection.combine(
          transform_errors(validate(context.input, context)),
          validator.errors
        )
      end

      def build_valid_node
        if nil_input? && allowed_default?
          return default.nil? ? nil : build_node(processed_input)
        end

        unless validate_type.nil?
          raise Openapi3Parser::Error::InvalidType,
                "Invalid type for #{context.location_summary}. "\
                "#{validate_type}"
        end

        validate_before_build
        build_node(processed_input)
      end

      def validate_before_build
        errors = Array(validate(context.input, context))
        return unless errors.any?
        raise Openapi3Parser::Error::InvalidData,
              "Invalid data for #{context.location_summary}. "\
              "#{errors.join(', ')}"
      end

      def build_node(input)
        data = NodeFactory::Object::NodeBuilder.new(input, self).data
        build_object(data, context)
      end

      def validate_type
        valid_type = context.input.is_a?(Hash)
        return "Expected an object" unless valid_type
      end

      def transform_errors(errors)
        error_objects = Array(errors).map do |error|
          if error.is_a?(Validation::Error)
            error
          else
            Validation::Error.new(error, context, self.class)
          end
        end
        Validation::ErrorCollection.new(error_objects)
      end
    end
  end
end
