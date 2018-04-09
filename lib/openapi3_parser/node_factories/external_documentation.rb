# frozen_string_literal: true

require "openapi3_parser/node/external_documentation"
require "openapi3_parser/node_factory_refactor/object"
require "openapi3_parser/validators/url"

module Openapi3Parser
  module NodeFactories
    class ExternalDocumentation < NodeFactoryRefactor::Object

      allow_extensions

      field "description", input_type: String
      field "url",
            required: true,
            input_type: String,
            validate: ->(input) { Validators::Url.call(input) }

      private

      def build_object(data, context)
        Node::ExternalDocumentation.new(data, context)
      end
    end
  end
end
