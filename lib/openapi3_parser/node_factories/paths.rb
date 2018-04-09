# frozen_string_literal: true

require "openapi3_parser/node_factory_refactor/map"
require "openapi3_parser/node_factory/optional_reference"
require "openapi3_parser/node_factories/path_item"
require "openapi3_parser/node/paths"

module Openapi3Parser
  module NodeFactories
    class Paths < NodeFactoryRefactor::Map
      PATH_REGEX = %r{
        \A
        # required prefix slash
        /
        (
          # Match a path
          ([\-;_.!~*'()a-zA-Z\d:@&=+$,]|%[a-fA-F\d]{2})*
          # Match a path template parameter
          ({([\-;_.!~*'()a-zA-Z\d:@&=+$,]|%[a-fA-F\d]{2})+})*
          # optional segment separating slash
          /?
        )*
        \Z
      }x

      def initialize(context)
        factory = NodeFactory::OptionalReference.new(NodeFactories::PathItem)

        super(context,
              allow_extensions: true,
              value_factory: factory,
              validate: :validate)
      end

      private

      def build_map(data)
        Node::Paths.new(data, context)
      end

      def validate
        paths = context.input.keys.reject { |key| NodeFactoryRefactor::EXTENSION_REGEX =~ key }
        validate_paths(paths)
      end

      def validate_paths(paths)
        invalid_paths = paths.reject { |p| PATH_REGEX.match(p) }
        errors = []
        unless invalid_paths.empty?
          joined = invalid_paths.map { |p| "'#{p}'" }.join(", ")
          errors << %(There are invalid paths: #{joined})
        end

        conflicts = conflicting_paths(paths)

        unless conflicts.empty?
          joined = conflicts.map { |p| "'#{p}'" }.join(", ")
          errors << %(There are paths that conflict: #{joined})
        end

        errors
      end

      def conflicting_paths(paths)
        potential_conflicts = paths.each_with_object({}) do |path, memo|
          without_params = path.gsub(/{.*?}/, "")
          memo[path] = without_params if path != without_params
        end

        grouped_paths = potential_conflicts.group_by(&:last)
                                           .map { |_k, v| v.map(&:first) }

        grouped_paths.select { |group| group.size > 1 }.flatten
      end
    end
  end
end
