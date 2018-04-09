# frozen_string_literal: true

require "openapi3_parser/node/server_variable"
require "openapi3_parser/node_factory_refactor/object"
require "openapi3_parser/node_factory_refactor/array"

module Openapi3Parser
  module NodeFactories
    class ServerVariable < NodeFactoryRefactor::Object
      allow_extensions
      field "enum", factory: :enum_factory, validate: :validate_enum
      field "default", input_type: String, required: true
      field "description", input_type: String

      private

      def enum_factory(context)
        NodeFactoryRefactor::Array.new(
          context,
          default: nil,
          value_input_type: String
        )
      end

      def validate_enum(input)
        return "Expected atleast one value" if input.empty?
      end

      def build_object(data, context)
        Node::ServerVariable.new(data, context)
      end
    end
  end
end
