# frozen_string_literal: true

require "openapi_parser/nodes/security_scheme"
require "openapi_parser/node_factories/oauth_flows"
require "openapi_parser/node_factory/object"
require "openapi_parser/node_factory/optional_reference"

module OpenapiParser
  module NodeFactories
    class SecurityScheme
      include NodeFactory::Object

      allow_extensions

      field "type", input_type: String, required: true
      field "description", input_type: String
      field "name", input_type: String
      field "in", input_type: String
      field "scheme", input_type: String
      field "bearerFormat", input_type: String
      field "flows", factory: :flows_factory
      field "openIdConnectUrl", input_type: String

      private

      def build_object(data, context)
        Nodes::SecurityScheme.new(data, context)
      end

      def flows_factory(context)
        NodeFactories::OauthFlows.new(context)
      end
    end
  end
end
