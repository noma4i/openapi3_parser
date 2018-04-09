# frozen_string_literal: true

require "openapi3_parser/context"
require "openapi3_parser/error"
require "openapi3_parser/node/map"
require "openapi3_parser/node_factory_refactor"
require "openapi3_parser/validation/error"
require "openapi3_parser/validation/error_collection"

module Openapi3Parser
  module NodeFactoryRefactor
    class Map
      attr_reader :context, :processed_input

      # rubocop:disable Metrics/ParameterLists
      def initialize(
        context,
        allow_extensions: false,
        default: {},
        key_input_type: String,
        value_input_type: nil,
        value_factory: nil,
        validate: nil
      )
        @context = context
        @allow_extensions = allow_extensions
        @default = default
        @given_key_input_type = key_input_type
        @given_value_input_type = value_input_type
        @given_value_factory = value_factory
        @given_validate = validate
        input = nil_input? ? default : context.input
        @processed_input = input.nil? ? nil : process_input(input)
      end
      # rubocop:enable Metrics/ParameterLists

      def raw_input
        context.input
      end

      def resolved_input
        raw_resolved_input
      end

      def raw_resolved_input
        @raw_resolved_input ||= build_raw_resolved_input
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
        @node ||= build_node
      end

      private

      attr_reader :default, :allow_extensions, :given_key_input_type,
                  :given_value_input_type, :given_value_factory,
                  :given_validate

      def process_input(input)
        input.each_with_object({}) do |(key, value), memo|
          memo[key] = if EXTENSION_REGEX =~ key || !given_value_factory
                        value
                      else
                        next_context = Context.next_field(context, key)
                        initialize_value_factory(next_context)
                      end
        end
      end

      def build_raw_resolved_input
        processed_input.each_with_object({}) do |(key, value), memo|
          memo[key] = if value.respond_to?(:resolved_input)
                        value.resolved_input
                      else
                        value
                      end
        end
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

      def build_errors
        return Validation::ErrorCollection.new if nil_input?

        # check correct type
        unless context.input.is_a?(::Hash)
          error = Validation::Error.new(
            "Invalid type. Expected a object", context, self.class
          )
          return Validation::ErrorCollection.new([error])
        end

        invalid_key = invalid_key_error
        type_errors = validate_value_input_type(processed_input, context)

        field_errors = processed_input.each_value.inject({}) do |memo, value|
          errors = value.respond_to?(:errors) ? value.errors : []
          Validation::ErrorCollection.combine(memo, errors)
        end

        validate_errors = if given_validate.is_a?(Symbol)
                            send(given_validate)
                          else
                            given_validate&.call(processed_input, context)
                          end

        Validation::ErrorCollection.combine(
          Validation::ErrorCollection.combine(
            transform_errors(invalid_key),
            transform_errors(type_errors)
          ),
          Validation::ErrorCollection.combine(
            transform_errors(field_errors),
            transform_errors(validate_errors)
          ),
        )
      end

      def build_node
        return build_default if nil_input?
        check_value_input_type(processed_input)
        data = processed_input.each_with_object({}) do |(key, value), memo|
          memo[key] = value.respond_to?(:node) ? value.node : value
        end
        build_map(data)
      end

      def initialize_value_factory(context)
        factory = given_value_factory
        return factory.new(context) if factory.is_a?(Class)
        factory.call(context)
      end

      def invalid_key_error
        return unless given_key_input_type
        invalid_keys = context.input.keys.reject do |key|
          key.is_a?(given_key_input_type)
        end
        error = "Expected keys to be of type #{given_key_input_type}"
        error if invalid_keys.any?
      end

      def validate_value_input_type(input, context)
        input.each_with_object([]) do |(key, value), memo|
          error = error_for_value_input_type(value)
          next unless error
          memo << Validation::Error.new(
            error, Context.next_field(context, key), self.class
          )
        end
      end

      def check_value_input_type(input)
        input.each do |key, value|
          error = error_for_value_input_type(value)
          next unless error
          next_context = Context.next_field(context, key)
          raise Openapi3Parser::Error::InvalidType,
                "Invalid type for #{next_context.location_summary}. "\
                "#{error}"
        end
      end

      def error_for_value_input_type(value)
        type = given_value_input_type
        return unless type
        "Expected #{type}" unless value.is_a?(type)
      end

      def build_default
        return if default.nil?
        build_map(default)
      end

      def build_map(data)
        Node::Map.new(data, context)
      end
    end
  end
end
