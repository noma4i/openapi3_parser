# frozen_string_literal: true

require "openapi3_parser/node/license"
require "openapi3_parser/node_factory_refactor/object"
require "openapi3_parser/validators/url"

module Openapi3Parser
  module NodeFactories
    class License < NodeFactoryRefactor::Object
      allow_extensions
      field "name", input_type: String, required: true
      field "url",
            input_type: String,
            validate: ->(input) { Validators::Url.call(input) }

      private

      def build_object(data, context)
        Node::License.new(data, context)
      end
    end
  end
end
