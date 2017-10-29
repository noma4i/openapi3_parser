# frozen_string_literal: true

require "openapi_parser/node"
require "openapi_parser/fields/map"

module OpenapiParser
  module Nodes
    class Schema
      include Node

      HASH_ARRAY_WITH_ATLEAST_ONE_ELEMENT = -> (i) {
        i.is_a?(Array) && i.map(&:class).uniq == [Hash] && i.count > 0
      }

      allow_extensions

      field "title", input_type: String
      field "multipleOf", input_type: Numeric
      field "maximum", input_type: Integer
      field "exclusiveMaximum", input_type: :boolean, default: false
      field "minimum", input_type: Integer
      field "exclusiveMinimum", input_type: :boolean, default: false
      field "maxLength", input_type: -> (i) { i.is_a?(Integer) && i > 0 }
      field "minLength",
        input_type: -> (i) { i.is_a?(Integer) && i >= 0 },
        default: 0
      field :pattern, input_type: String
      field "maxItems", input_type: -> (i) { i.is_a?(Integer) && i > 0 }
      field "minItems",
        input_type: -> (i) { i.is_a?(Integer) && i >= 0 },
        default: 0
      field "uniqueItems", input_type: :boolean, default: false
      field "maxProperties", input_type: -> (i) { i.is_a?(Integer) && i > 0 }
      field "minProperties",
        input_type: -> (i) { i.is_a?(Integer) && i >= 0 },
        default: 0
      field "required",
        input_type: -> (i) {
          i.is_a?(Array) && i.count > 0 && i.map(:class).uniq == [String]
        }
      field "enum",
        input_type: -> (i) { i.is_a?(Array) && i.uniq.count == i.count }

      field "type", input_type: String
      field "allOf",
        input_type: HASH_ARRAY_WITH_ATLEAST_ONE_ELEMENT,
        build: :build_schema_array
      field "oneOf",
        input_type: HASH_ARRAY_WITH_ATLEAST_ONE_ELEMENT,
        build: :build_schema_array
      field "anyOf", input_type: HASH_ARRAY_WITH_ATLEAST_ONE_ELEMENT,
        build: :build_schema_array
      field "not",
        input_type: Hash,
        build: :build_referenceable_schema
      field "items",
        input_type: Hash,
        build: :build_referenceable_schema
      field "properties", input_type: Hash, build: :build_properties
      field "additionalProperties",
        input_type: -> (i) {
          [true, false].include?(i) || i.is_a?(Hash)
        },
        build: :build_additional_properties
      field "description", input_type: String
      field "format", input_type: String
      field "default"

      field "nullable", input_type: :boolean, default: false
      field "discriminator", input_type: Hash
      field "readOnly", input_type: :boolean, default: false
      field "writeOnly", input_type: :boolean, default: false
      field "xml", input_type: Hash
      field "externalDocs", input_type: Hash
      field "example"
      field "deprecated", input_type: :boolean, default: false

      def title
        fields["title"]
      end

      def multiple_of
        fields["multipleOf"]
      end

      def maximum
        fields["maximum"]
      end

      def exclusiveMaximum
        fields["exclusiveMaximum"]
      end

      def minimum
        fields["minimum"]
      end

      def exclusiveMinimum
        fields["exclusiveMinimum"]
      end

      def maxLength
        fields["maxLength"]
      end

      def minLength
        fields["minLength"]
      end

      def pattern
        fields["pattern"]
      end

      def maxItems
        fields["maxItems"]
      end

      def minItems
        fields["minItems"]
      end

      def uniqueItems
        fields["uniqueItems"]
      end

      def maxProperties
        fields["maxProperties"]
      end

      def minProperties
        fields["minProperties"]
      end

      def required
        fields["required"]
      end

      def enum
        fields["enum"]
      end

      def type
        fields["type"]
      end

      def all_of
        fields["allOf"]
      end

      def one_of
        fields["oneOf"]
      end

      def any_of
        fields["anyOf"]
      end

      def not
        fields["not"]
      end

      def items
        fields["items"]
      end

      def properties
        fields["properties"]
      end

      def additional_properties
        fields["additionalProperties"]
      end

      def description
        fields["description"]
      end

      def format
        fields["format"]
      end

      def default
        fields["default"]
      end

      def nullable
        fields["nullable"]
      end

      def disciminator
        fields["discriminator"]
      end

      def read_only
        fields["readOnly"]
      end

      def write_only
        fields["writeOnly"]
      end

      def xml
        fields["xml"]
      end

      def external_docs
        fields["externalDocs"]
      end

      def example
        fields["example"]
      end

      def deprecated
        fields["deprecated"]
      end

      private

      def build_referenceable_schema(input, context)
        context.possible_reference(input) do |resolved_input, resolved_context|
          Schema.new(resolved_input, resolved_context)
        end
      end

      def build_schema_array(input, context)
        input.map.with_index do |schema_input, index|
          build_referenceable_schema(schema_input, context.next_namespace(index))
        end
      end

      def build_additional_properties(input, context)
        return input unless input.is_a?(Hash)
        build_referenceable_schema(input, context)
      end

      def build_properties(input, context)
        Fields::Map.call(input, context) do |next_input, next_context|
          Schema.new(next_input, next_context)
        end
      end
    end
  end
end