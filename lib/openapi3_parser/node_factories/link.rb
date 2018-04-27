# frozen_string_literal: true

require "openapi3_parser/node/license"
require "openapi3_parser/node_factory_refactor/map"
require "openapi3_parser/node_factory_refactor/object"
require "openapi3_parser/node_factories/server"

module Openapi3Parser
  module NodeFactories
    class Link < NodeFactoryRefactor::Object

      allow_extensions

      # @todo The link object in OAS is pretty meaty and there's lot of scope
      # for further work here to make use of it's funcationality

      field "operationRef", input_type: String
      field "operationId", input_type: String
      field "parameters", factory: :parameters_factory
      field "requestBody"
      field "description", input_type: String
      field "server", factory: :server_factory

      mutually_exclusive "operationRef", "operationId", required: true

      private

      def build_object(data, context)
        Node::Link.new(data, context)
      end

      def parameters_factory(context)
        NodeFactoryRefactor::Map.new(context)
      end

      def server_factory(context)
        NodeFactories::Server.new(context)
      end
    end
  end
end
