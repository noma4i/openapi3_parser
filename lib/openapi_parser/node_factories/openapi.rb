# frozen_string_literal: true

require "openapi_parser/nodes/openapi"
require "openapi_parser/node_factory/object"
require "openapi_parser/node_factories/info"
require "openapi_parser/node_factories/array"
require "openapi_parser/node_factories/server"
require "openapi_parser/node_factories/paths"
require "openapi_parser/node_factories/components"
require "openapi_parser/node_factories/security_requirement"
require "openapi_parser/node_factories/tag"
require "openapi_parser/node_factories/external_documentation"

module OpenapiParser
  module NodeFactories
    class Openapi
      include NodeFactory::Object

      allow_extensions
      field "openapi", input_type: String, required: true
      field "info", factory: NodeFactories::Info, required: true
      field "servers", factory: :servers_factory
      field "paths", factory: NodeFactories::Paths, required: true
      field "components", factory: NodeFactories::Components
      field "security", factory: :security_factory
      field "tags", factory: :tags_factory
      field "externalDocs", factory: NodeFactories::ExternalDocumentation

      private

      def build_object(data, context)
        Nodes::Openapi.new(data, context)
      end

      def servers_factory(context)
        NodeFactories::Array.new(context, value_factory: NodeFactories::Server)
      end

      def security_factory(context)
        NodeFactories::Array.new(
          context, value_factory: NodeFactories::SecurityRequirement
        )
      end

      def tags_factory(context)
        NodeFactories::Array.new(context, value_factory: NodeFactories::Tag)
      end
    end
  end
end
