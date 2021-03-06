# frozen_string_literal: true

require "openapi3_parser/markdown"

module Openapi3Parser
  module Node
    class Object
      include Enumerable

      attr_reader :node_data, :node_context

      def initialize(data, context)
        @node_data = data
        @node_context = context
      end

      # Look up an attribute of the node by the name it has in the OpenAPI
      # document.
      #
      # @example Look up by OpenAPI naming
      #   obj["externalDocs"]
      #
      # @example Look up by symbol
      #   obj[:servers]
      #
      # @example Look up an extension
      #   obj["x-myExtension"]
      #
      # @param [String, Symbol] value
      #
      # @return anything
      def [](value)
        node_data[value.to_s]
      end

      # Look up an extension provided for this object, doesn't need a prefix of
      # "x-"
      #
      # @example Looking up an extension provided as "x-extra"
      #   obj.extension("extra")
      #
      # @param [String, Symbol] value
      #
      # @return [Hash, Array, Numeric, String, true, false, nil]
      def extension(value)
        node_data["x-#{value}"]
      end

      # Iterate through the attributes of this object
      def each(&block)
        node_data.each(&block)
      end

      # Used to render fields that can be in markdown syntax into HTML
      # @param  [String, nil] value
      # @return [String, nil]
      def render_markdown(value)
        return if value.nil?
        Markdown.to_html(value)
      end
    end
  end
end
