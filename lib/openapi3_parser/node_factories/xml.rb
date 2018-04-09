# frozen_string_literal: true

require "openapi3_parser/node/xml"
require "openapi3_parser/node_factory_refactor/object"
require "openapi3_parser/validators/absolute_uri"

module Openapi3Parser
  module NodeFactories
    class Xml < NodeFactoryRefactor::Object
      allow_extensions
      field "name", input_type: String
      field "namespace",
            input_type: String,
            validate: -> (input) { Validators::AbsoluteUri.call(input) }
      field "prefix", input_type: String
      field "attribute", input_type: :boolean, default: false
      field "wrapped", input_type: :boolean, default: false

      private

      def build_object(data, context)
        Node::Xml.new(data, context)
      end
    end
  end
end
