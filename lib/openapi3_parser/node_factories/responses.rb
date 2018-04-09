# frozen_string_literal: true

require "openapi3_parser/context"
require "openapi3_parser/node_factory_refactor/map"
require "openapi3_parser/node_factories/response"
require "openapi3_parser/node_factory/optional_reference"
require "openapi3_parser/node/responses"

module Openapi3Parser
  module NodeFactories
    class Responses < NodeFactoryRefactor::Map
      KEY_REGEX = /
        \A
        (
        default
        |
        [1-5]([0-9][0-9]|XX)
        )
        \Z
      /x

      def initialize(context)
        factory = NodeFactory::OptionalReference.new(NodeFactories::Response)

        super(context,
              allow_extensions: true,
              value_factory: factory,
              validate: method(:validate_keys))
      end

      private

      def build_map(data)
        Node::Responses.new(data, context)
      end

      def validate_keys(input, _context)
        invalid = input.keys.reject do |key|
          NodeFactoryRefactor::EXTENSION_REGEX.match(key) || KEY_REGEX.match(key)
        end

        return if invalid.empty?

        codes = invalid.map { |k| "'#{k}'" }.join(", ")
        "Invalid responses keys: #{codes} - default, status codes and status "\
        "code ranges allowed"
      end
    end
  end
end
