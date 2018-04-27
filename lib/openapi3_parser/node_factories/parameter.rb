# frozen_string_literal: true

require "openapi3_parser/context"
require "openapi3_parser/node/parameter"
require "openapi3_parser/node_factories/parameter_like"
require "openapi3_parser/node_factory_refactor/object"
require "openapi3_parser/validation/error"

module Openapi3Parser
  module NodeFactories
    class Parameter < NodeFactoryRefactor::Object
      include ParameterLike

      allow_extensions

      field "name", input_type: String, required: true
      field "in", input_type: String,
                  required: true,
                  validate: :validate_in
      field "description", input_type: String
      field "required", input_type: :boolean, default: false
      field "deprecated", input_type: :boolean, default: false
      field "allowEmptyValue", input_type: :boolean, default: false

      field "style", input_type: String, default: :default_style
      field "explode", input_type: :boolean, default: :default_explode
      field "allowReserved", input_type: :boolean, default: false
      field "schema", factory: :schema_factory
      field "example"
      field "examples", factory: :examples_factory

      field "content", factory: :content_factory

      mutually_exclusive "example", "examples"

      private

      def build_object(data, context)
        Node::Parameter.new(data, context)
      end

      def validate(input, context)
        errors = []

        if input["in"] == "path" && !input["required"]
          errors << Validation::Error.new(
            "Must be included and true for a path parameter",
            Context.next_field(context, "required"),
            self.class
          )
        end

        errors
      end

      def default_style
        return "simple" if %w[path header].include?(context.input["in"])
        "form"
      end

      def validate_in(input)
        valid = %w[header query cookie path].include?(input)
        "in can only be header, query, cookie, or path" unless valid
      end
    end
  end
end
