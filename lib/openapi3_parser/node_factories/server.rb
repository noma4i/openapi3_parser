# frozen_string_literal: true

require "openapi3_parser/node/server"
require "openapi3_parser/node_factory_refactor/map"
require "openapi3_parser/node_factory_refactor/object"
require "openapi3_parser/node_factories/server_variable"

module Openapi3Parser
  module NodeFactories
    class Server < NodeFactoryRefactor::Object
      allow_extensions
      field "url", input_type: String, required: true
      field "description", input_type: String
      field "variables", factory: :variables_factory

      private

      def build_object(data, context)
        Node::Server.new(data, context)
      end

      def variables_factory(context)
        NodeFactoryRefactor::Map.new(
          context,
          value_factory: NodeFactories::ServerVariable
        )
      end
    end
  end
end
