# frozen_string_literal: true

module Openapi3Parser
  module Node
    class Map
      include Enumerable

      attr_reader :node_data, :node_context

      def initialize(data, context)
        @node_data = data
        @node_context = context
      end

      def [](value)
        node_data[value]
      end

      def each(&block)
        node_data.each(&block)
      end
    end
  end
end
