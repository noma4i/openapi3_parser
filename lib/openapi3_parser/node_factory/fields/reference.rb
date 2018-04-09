# frozen_string_literal: true

require "openapi3_parser/node_factory_refactor/field"
require "openapi3_parser/validators/reference"

module Openapi3Parser
  module NodeFactory
    module Fields
      class Reference < NodeFactoryRefactor::Field
        def initialize(context, factory)
          super(context, input_type: String, validate: :validate)
          @factory = factory
          @given_reference = context.input
          @reference_resolver = create_reference_resolver
        end

        def data
          reference_resolver&.data
        end

        private

        attr_reader :given_reference, :factory, :reference_resolver

        def validate
          return reference_validator.errors unless reference_validator.valid?
          reference_resolver&.errors
        end

        def build_node
          reference_resolver&.node
        end

        def reference_validator
          @reference_validator ||= Validators::Reference.new(given_reference)
        end

        def create_reference_resolver
          return unless given_reference
          context.register_reference(given_reference, factory)
        end
      end
    end
  end
end
