require 'spec_helper'
require 'net/http'
require 'uri'

describe CcApiStub::Frameworks do
  let(:url) { "http://example.com/v2/frameworks?inline-relations-depth=1" }

  describe ".succeed_to_load" do
    subject { CcApiStub::Frameworks.succeed_to_load }

    it_behaves_like "a stubbed get request"
  end

  describe ".fail_to_load" do
    subject { CcApiStub::Frameworks.fail_to_load }

    it_behaves_like "a stubbed get request", :code => 500, :ignore_response => true
  end
end