require "spec_helper"

describe CFoundry::V2::App do
  let(:client) { fake_client }

  describe "environment" do
    let(:app) { fake :app, :env => { "FOO" => "1" } }

    it "returns a hash-like object" do
      expect(app.env["FOO"]).to eq "1"
    end

    describe "converting keys and values to strings" do
      let(:app) { fake :app, :env => { :FOO => 1 } }

      it "converts keys and values to strings" do
        expect(app.env.to_hash).to eq("FOO" => "1")
      end
    end

    context "when changes are made to the hash-like object" do
      it "reflects the changes in .env" do
        expect {
          app.env["BAR"] = "2"
        }.to change { app.env.to_hash }.from("FOO" => "1").to("FOO" => "1", "BAR" => "2")
      end
    end

    context "when the env is set to something else" do
      it "reflects the changes in .env" do
        expect {
          app.env = { "BAR" => "2" }
        }.to change { app.env.to_hash }.from("FOO" => "1").to("BAR" => "2")
      end
    end
  end

  describe "#summarize!" do
    let(:app) { fake :app }

    it "assigns :instances as #total_instances" do
      stub(app).summary { { :instances => 4 } }

      app.summarize!

      expect(app.total_instances).to eq(4)
    end
  end

  shared_examples_for "something may stage the app" do
    subject { fake :app, :client => client }
    let(:response) { { :body => '{ "foo": "bar" }' } }

    before do
      stub(client.base).put("v2", "apps", subject.guid, anything) do
        response
      end
    end

    context "when asynchronous is true" do
      it "sends the PUT request with &stage_async=true" do
        mock(client.base).put(
            "v2", "apps", subject.guid,
            hash_including(
              :params => { :stage_async => true },
              :return_response => true )) do
          response
        end

        update(true)
      end

      context "and a block is given" do
        let(:response) do
          { :headers => { "x-app-staging-log" => "http://app/staging/log" },
            :body => "{}"
          }
        end

        it "yields the URL for the logs" do
          yielded_url = nil
          update(true) do |url|
            yielded_url = url
          end

          expect(yielded_url).to eq "http://app/staging/log"
        end
      end
    end

    context "when asynchronous is false" do
      it "sends the PUT request with &stage_async=false" do
        mock(client.base).put(
            "v2", "apps", subject.guid,
            hash_including(:params => { :stage_async => false})) do
          response
        end

        update(false)
      end
    end
  end

  describe "#start!" do
    it_should_behave_like "something may stage the app" do
      def update(async, &blk)
        subject.start!(async, &blk)
      end
    end
  end

  describe "#restart!" do
    it_should_behave_like "something may stage the app" do
      def update(async, &blk)
        subject.restart!(async, &blk)
      end
    end
  end

  describe "#update!" do
    describe "changes" do
      subject { fake :app, :client => client }
      let(:response) { { :body => '{ "foo": "bar" }' } }

      before do
        stub(client.base).put("v2", "apps", subject.guid, anything) do
          response
        end
      end

      it "applies the changes from the response JSON" do
        expect {
          subject.update!
        }.to change { subject.manifest }.to(:foo => "bar")
      end
    end

    it_should_behave_like "something may stage the app" do
      def update(async, &blk)
        subject.update!(async, &blk)
      end
    end
  end
end
