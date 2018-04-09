# frozen_string_literal: true

require "openapi3_parser/validation/error"
require "openapi3_parser/validation/error_collection"

module Openapi3Parser
  module Validation
    class Validatable
      attr_reader :factory, :errors

      UNDEFINED = Class.new

      def initialize(factory)
        @factory = factory
        @errors = []
      end

      def add_error(error, context = nil, factory_class = UNDEFINED)
        return unless error
        return @errors << error if error.is_a?(Validation::Error)

        @errors << Validation::Error.new(
          error,
          context || factory.context,
          factory_class == UNDEFINED ? factory.class : factory_class
        )
      end

      def add_errors(errors)
        errors = errors.to_a if errors.respond_to?(:errors)
        errors.each { |e| add_error(e) }
      end

      def collection
        ErrorCollection.new(errors)
      end
    end
  end
end
