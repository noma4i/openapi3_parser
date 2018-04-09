# frozen_string_literal: true

require "openapi3_parser/error"
require "openapi3_parser/validation/error"
require "openapi3_parser/validation/error_collection"

module Openapi3Parser
  module NodeFactoryRefactor
    class Field
      attr_reader :context

      def initialize(context, input_type: nil, validate: nil)
        @context = context
        @input_type = input_type
        @given_validate = given_validate
      end

      def processed_input
        context.input
      end

      def resolved_input
        raw_resolved_input
      end

      def raw_resolved_input
        context.input
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

      private

      attr_reader :input_type, :given_validate

      def build_errors
        return Validation::ErrorCollection.new if nil_input?
        if input_type && !context.input.is_a?(input_type)
          error = Validation::Error.new(
            "Invalid type. Expected a #{input_type}", context, self.class
          )
          return Validation::ErrorCollection.new([error])
        end

        if given_validate.is_a?(Symbol)
          transform_errors(send(given_validate))
        else
          transform_errors(given_validate&.call(context.input, self))
        end
      end

      def build_valid_node
        return nil if nil_input?
        if input_type && !context.input.is_a?(input_type)
          raise Openapi3Parser::Error::InvalidType,
                "Invalid type for #{next_context.location_summary}. "\
                "Expected a #{input_type}"
        end
        build_node
      end

      def build_node
        context.input
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
