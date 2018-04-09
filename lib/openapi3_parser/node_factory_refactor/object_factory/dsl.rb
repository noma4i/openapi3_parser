# frozen_string_literal: true

require "ostruct"

module Openapi3Parser
  module NodeFactoryRefactor
    module ObjectFactory
      module Dsl
        def field(name, **options)
          @field_configs ||= {}
          @field_configs[name] = NodeFactory::FieldConfig.new(options)
        end

        def field_configs
          @field_configs || {}
        end

        def allow_extensions
          @allow_extensions = true
        end

        def allowed_extensions?
          @allow_extensions == true
        end

        def mutually_exclusive(*fields, required: false)
          @mutually_exclusive ||= []
          @mutually_exclusive << OpenStruct.new(
            fields: fields, required: required
          )
        end

        def mutually_exclusive_fields
          @mutually_exclusive || []
        end

        def disallow_default
          @allow_default = false
        end

        def allowed_default?
          @allow_default.nil? || @allow_default
        end
      end
    end
  end
end
