require 'spec_helper'
require 'fixtures/data.rb'

describe 'API errors', type: 'feature' do
  let(:errors)          {  DataMagic::ErrorChecker.check(params, options, config) }
  let(:expected_errors) { [] }
  let(:config)          { DataMagic.config }
  let(:options)         { {} }
  let(:params)          { {} }

  before :all do
    DataMagic.destroy
    ENV['DATA_PATH'] = './spec/fixtures/sample-data'
    DataMagic.init(load_now: true)
  end
  after :all do
    DataMagic.destroy
  end

  RSpec.configure do |c|
    c.alias_it_should_behave_like_to :it_correctly, ', it correctly'
  end

  shared_examples "returns an error" do
    it "with the right content" do
      expect(errors).to eq expected_errors
    end
  end

  describe "are returned" do
    context "when an unknown parameter is provided" do
      let(:params) { { "frog" => "toad" } }
      let(:expected_errors) do
        [{
          error: 'parameter_not_found',
          message: "The input parameter 'frog' is not known in this dataset.",
          input: 'frog'
        }]
      end
      it_correctly "returns an error"
    end

    context "when an unknown field is specified in the field list" do
      let(:options) { { fields: %w(state marjorie) } }
      let(:expected_errors) do
        [{
          error: 'field_not_found',
          input: 'marjorie',
          message: "The input field 'marjorie' (in the fields parameter) is not a field in this dataset."
        }]
      end
      it_correctly "returns an error"
    end

    context "when an unknown operator is used" do
      let(:params) { { "population__brak" => "1200" } }
      let(:expected_errors) do
        [{
          error: 'operator_not_found',
          message: "The input operator 'brak' (appended to the parameter 'population') is not known or supported. (Known operators: range, ne, not)",
          input: 'brak',
          parameter: 'population'
        }]
      end
      it_correctly "returns an error"
    end

    context "when a value of the wrong type is provided for a field" do
      let(:params) { { "population" => "kevin" } }
      let(:expected_errors) do
        [{
          error: 'parameter_type_error',
          message: "The parameter 'population' expects an integer, but received a string.",
          input: 'kevin',
          parameter: 'population',
          expected_type: 'integer',
          input_type: 'string'
        }]
      end
      # Pending
      # it_correctly "returns an error"
    end

    context "when a range is specified incorrectly" do
      let(:params) { { "population__range" => "kevin..3" } }
      let(:expected_errors) do
        [{
          error: 'range_format_error',
          message: "The range 'kevin..3' supplied to parameter 'population' isn't in the correct format.",
          input: 'kevin..3',
          parameter: 'population'
        }]
      end
      it_correctly "returns an error"
    end

    context "when multiple errors occur" do
      let(:params)  { { "population__range" => "kevin..3" } }
      let(:options) { { fields: %w(state frog marjorie) } }
      let(:expected_errors) do
        [
          {
            error: 'field_not_found',
            message: "The input field 'frog' (in the fields parameter) is not a field in this dataset.",
            input: 'frog'
          }, {
            error: 'field_not_found',
            message: "The input field 'marjorie' (in the fields parameter) is not a field in this dataset.",
            input: 'marjorie'
          }, {
            error: 'range_format_error',
            message: "The range 'kevin..3' supplied to parameter 'population' isn't in the correct format.",
            input: 'kevin..3',
            parameter: 'population'
          }
        ]
      end
      # NOTE: This currently also asserts the ordering of errors in the JSON
      # response, which it shouldn't, because that doesn't matter.
      it_correctly "returns an error"
    end
  end
end