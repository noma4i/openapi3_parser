# frozen_string_literal: true

require "openapi3_parser/node/security_requirement"
require "openapi3_parser/node_factory_refactor/array"
require "openapi3_parser/node_factory_refactor/map"

module Openapi3Parser
  module NodeFactories
    class SecurityRequirement < NodeFactoryRefactor::Map
      def initialize(context)
        super(context, value_factory: NodeFactoryRefactor::Array)
      end

      private

      def build_map(data)
        Node::SecurityRequirement.new(data, context)
      end
    end
  end
end
