# frozen_string_literal: true

require "openapi3_parser/context"
require "openapi3_parser/node_factory_refactor"
require "openapi3_parser/node_factory_refactor/type_checker"
require "openapi3_parser/node/array"
require "openapi3_parser/validation/validatable"

module Openapi3Parser
  module NodeFactoryRefactor
    class Array
      attr_reader :context, :processed_input, :default, :value_input_type,
                  :value_factory, :validation

      def initialize(
        context,
        default: [],
        value_input_type: nil,
        value_factory: nil,
        validate: nil
      )
        @context = context
        @default = default
        @value_input_type = value_input_type
        @value_factory = value_factory
        @validation = validate
        input = nil_input? ? default : context.input
        @processed_input = input.nil? ? nil : process_input(input)
      end

      def raw_input
        context.input
      end

      def resolved_input
        raw_resolved_input
      end

      def raw_resolved_input
        @raw_resolved_input ||= processed_input.map do |value|
          value.respond_to?(:resolved_input) ? value.resolved_input : value
        end
      end

      def nil_input?
        context.input.nil?
      end

      def valid?
        errors.empty?
      end

      def errors
        @errors ||= ValidNodeBuilder.errors(self)
      end

      def node
        @node ||= begin
                    data = ValidNodeBuilder.data(self)
                    build_node(data)
                  end
      end

      private

      def process_input(input)
        input.each_with_index.map do |value, i|
          if value_factory
            initialize_value_factory(Context.next_field(context, i))
          else
            value
          end
        end
      end

      def initialize_value_factory(field_context)
        if value_factory.is_a?(Class)
          value_factory.new(field_context)
        else
          value_factory.call(field_context)
        end
      end

      def build_node(data)
        Node::Array.new(data, context)
      end

      class ValidNodeBuilder
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
          TypeChecker.validate_type(validatable, type: ::Array)
          return validatable.collection if validatable.errors.any?
          collate_errors
          validatable.collection
        end

        def data
          return default_value if factory.nil_input?

          TypeChecker.raise_on_invalid_type(factory.context, type: ::Array)
          check_values(raise_on_invalid: true)
          validate(raise_on_invalid: true)

          factory.processed_input.map do |value|
            value.respond_to?(:node) ? value.node : value
          end
        end

        private_class_method :new

        private

        attr_reader :factory, :validatable

        def collate_errors
          check_values(raise_on_invalid: false)
          validate(raise_on_invalid: false)

          factory.processed_input.each do |value|
            validatable.add_errors(value.errors) if value.respond_to?(:errors)
          end
        end

        def default_value
          if factory.nil_input? && factory.default.nil?
            nil
          else
            factory.processed_input
          end
        end

        def check_values(raise_on_invalid: false)
          return unless factory.value_input_type

          factory.context.input.each_index do |index|
            check_field_type(
              Context.next_field(factory.context, index), raise_on_invalid
            )
          end
        end

        def check_field_type(context, raise_on_invalid)
          if raise_on_invalid
            TypeChecker.raise_on_invalid_type(context,
                                              type: factory.value_input_type)
          else
            TypeChecker.validate_type(validatable,
                                      type: factory.value_input_type,
                                      context: context)
          end
        end

        def validate(raise_on_invalid: false)
          run_validation

          return if !raise_on_invalid || validatable.errors.empty?

          first_error = validatable.errors.first
          raise Openapi3Parser::Error::InvalidData,
                "Invalid data for #{first_error.context.location_summary}. "\
                "#{first_error.error_message}"
        end

        def run_validation
          if factory.validation.is_a?(Symbol)
            factory.send(:validation, validatable)
          else
            factory.validation&.call(validatable)
          end
        end
      end
    end
  end
end
