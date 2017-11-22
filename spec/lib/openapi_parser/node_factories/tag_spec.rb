# frozen_string_literal: true

require "openapi_parser/node_factories/tag"
require "openapi_parser/nodes/tag"

require "support/node_object_factory"
require "support/helpers/context"

RSpec.describe OpenapiParser::NodeFactories::Tag do
  include Helpers::Context

  it_behaves_like "node object factory", OpenapiParser::Nodes::Tag do
    let(:input) do
      {
        "name" => "pet",
        "description" => "Pets operations",
        "externalDocs" => {
          "description" => "Find more info here",
          "url" => "https://example.com"
        }
      }
    end

    let(:context) { create_context(input) }
  end
end
