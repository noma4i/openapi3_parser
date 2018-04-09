# frozen_string_literal: true

require "openapi3_parser/context"
require "openapi3_parser/node_factory_refactor/map"
require "openapi3_parser/node_factories/path_item"
require "openapi3_parser/node/callback"

module Openapi3Parser
  module NodeFactories
    class Callback < NodeFactoryRefactor::Map
      def initialize(context)
        super(context,
              allow_extensions: true,
              value_factory: NodeFactories::PathItem)
      end

      private

      def build_map(data)
        Node::Callback.new(data, context)
      end
    end
  end
end
