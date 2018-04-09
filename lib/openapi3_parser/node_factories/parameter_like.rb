# frozen_string_literal: true

module Openapi3Parser
  module NodeFactories
    module ParameterLike
      def default_explode
        context.input["style"] == "form"
      end

      def schema_factory(context)
        factory = NodeFactory::OptionalReference.new(NodeFactories::Schema)
        factory.call(context)
      end

      def examples_factory(context)
        factory = NodeFactory::OptionalReference.new(NodeFactories::Schema)
        NodeFactoryRefactor::Map.new(context, default: nil, value_factory: factory)
      end

      def content_factory(context)
        NodeFactoryRefactor::Map.new(context,
                                     default: nil,
                                     value_factory: NodeFactories::MediaType,
                                     validate: method(:validate_content).to_proc)
      end

      def validate_content(input, _context)
        "Must only have one item" unless input.size == 1
      end
    end
  end
end

# These are in the footer as a cyclic dependency can stop this module loading
require "openapi3_parser/node_factory/optional_reference"
require "openapi3_parser/node_factory_refactor/map"
require "openapi3_parser/node_factories/schema"
require "openapi3_parser/node_factories/example"
require "openapi3_parser/node_factories/media_type"
