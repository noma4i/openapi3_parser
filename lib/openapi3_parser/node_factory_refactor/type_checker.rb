# frozen_string_literal: true

require "openapi3_parser/error"
require "openapi3_parser/node_factory_refactor"

module Openapi3Parser
  module NodeFactoryRefactor
    class TypeChecker
      def self.validate_type(validatable, type:, context: nil)
        new(type).validate_type(validatable, context)
      end

      def self.raise_on_invalid_type(context, type:)
        new(type).raise_on_invalid_type(context)
      end

      private_class_method :new

      def initialize(type)
        @type = type
      end

      def validate_type(validatable, context)
        return unless type
        context ||= validatable.context
        valid_type?(context.input).tap do |valid|
          next if valid
          validatable.add_error("Invalid type. #{error_message}", context)
        end
      end

      def raise_on_invalid_type(context)
        return unless type
        unless valid_type?(context.input)
          raise Error::InvalidType,
                "Invalid type for #{context.location_summary}: "\
                "#{error_message}"
        end
      end

      private

      attr_reader :type

      def valid_type?(input)
        return [true, false].include?(input) if type == :boolean
        input.is_a?(type)
      end

      def error_message
        type_name = if type == Hash
                      "Object"
                    elsif type == :boolean
                      "Boolean"
                    else
                      type.to_s
                    end
        "Expected #{type_name}"
      end
    end
  end
end
