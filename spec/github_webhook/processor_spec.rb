require 'spec_helper'

module GithubWebhook
  describe Processor do

    class Request
      attr_accessor :headers, :body

      def initialize
        @headers = {}
        @body = StringIO.new
      end
    end

    class ControllerWithoutSecret
      ### Helpers to mock ActionController::Base behavior
      attr_accessor :request, :pushed

      def self.skip_before_action(*args); end
      def self.before_action(*args); end
      def head(*args); end
      ###

      include GithubWebhook::Processor

      def github_push(payload)
        @pushed = payload[:foo]
      end
    end

    class ControllerWithPrivateSecret < ControllerWithoutSecret
      private
      def webhook_secret(payload)
        "secret"
      end
    end

    class Controller < ControllerWithoutSecret
      def webhook_secret(payload)
        "secret"
      end
    end

    let(:controller_class) { Controller }

    let(:controller) do
      controller = controller_class.new
      controller.request = Request.new
      controller
    end

    describe "#create" do
      context 'when #webhook_secret is not defined' do
        let(:controller_class) { ControllerWithoutSecret }

        it "raises a AbstractController::ActionNotFound" do
          expect { controller.send :authenticate_github_request! }
            .to raise_error(AbstractController::ActionNotFound)
        end
      end

      context 'when #webhook_secret is private' do
        let(:controller_class) { ControllerWithPrivateSecret }

        it "calls the #push method in controller" do
          expect(controller).to receive(:github_push)
          controller.request.body = StringIO.new({ :foo => "bar" }.to_json.to_s)
          controller.request.headers['X-Hub-Signature-256'] = "sha256=3f3ab3986b656abb17af3eb1443ed6c08ef8fff9fea83915909d1b421aec89be"
          controller.request.headers['X-GitHub-Event'] = 'push'
          controller.request.headers['Content-Type'] = 'application/json'
          controller.send :authenticate_github_request!  # Manually as we don't have the before_filter logic in our Mock object
          controller.create
        end
      end

      it "calls the #push method in controller (json)" do
        controller.request.body = StringIO.new({ :foo => "bar" }.to_json.to_s)
        controller.request.headers['X-Hub-Signature-256'] = "sha256=3f3ab3986b656abb17af3eb1443ed6c08ef8fff9fea83915909d1b421aec89be"
        controller.request.headers['X-GitHub-Event'] = 'push'
        controller.request.headers['Content-Type'] = 'application/json'
        controller.send :authenticate_github_request!  # Manually as we don't have the before_action logic in our Mock object
        controller.create
        expect(controller.pushed).to eq "bar"
      end

      it "calls the #push method (x-www-form-urlencoded encoded)" do
        body = "payload=" + CGI::escape({ :foo => "bar" }.to_json.to_s)
        controller.request.body = StringIO.new(body)
        controller.request.headers['X-Hub-Signature-256'] = "sha256=cefe60b775fcb22483ceece8f20be4869868a20fb4aa79829e53c1de61b99d01"
        controller.request.headers['X-GitHub-Event'] = 'push'
        controller.request.headers['Content-Type'] = 'application/x-www-form-urlencoded'
        controller.send :authenticate_github_request!  # Manually as we don't have the before_action logic in our Mock object
        controller.create
        expect(controller.pushed).to eq "bar"
      end

      it "raises an error when signature does not match" do
        controller.request.body = StringIO.new({ :foo => "bar" }.to_json.to_s)
        controller.request.headers['X-Hub-Signature-256'] = "sha256=FOOBAR"
        controller.request.headers['X-GitHub-Event'] = 'push'
        controller.request.headers['Content-Type'] = 'application/json'
        expect { controller.send :authenticate_github_request! }.to raise_error(AbstractController::ActionNotFound)
      end

      it "raises an error when the github event method is not implemented" do
        controller.request.headers['X-GitHub-Event'] = 'deployment'
        controller.request.headers['Content-Type'] = 'application/json'
        expect { controller.create }.to raise_error(
          AbstractController::ActionNotFound,
          "GithubWebhooksController#github_deployment not implemented",
        )
      end

      it "raises an error when the github event is not in the whitelist" do
        controller.request.headers['X-GitHub-Event'] = 'fake_event'
        controller.request.headers['Content-Type'] = 'application/json'
        expect { controller.send :check_github_event! }.to raise_error(
          AbstractController::ActionNotFound,
          "fake_event is not a whitelisted GitHub event. See https://developer.github.com/v3/activity/events/types/",
        )
      end

      it "raises an error when the content type is not correct" do
        controller.request.body = StringIO.new({ :foo => "bar" }.to_json.to_s)
        controller.request.headers['X-Hub-Signature-256'] = "sha256=3f3ab3986b656abb17af3eb1443ed6c08ef8fff9fea83915909d1b421aec89be"
        controller.request.headers['X-GitHub-Event'] = 'ping'
        controller.request.headers['Content-Type'] = 'application/xml'
        expect { controller.send :authenticate_github_request! }.to raise_error(
          AbstractController::ActionNotFound,
          "Content-Type application/xml is not supported. Use 'application/x-www-form-urlencoded' or 'application/json",
        )
      end

      it 'raises SignatureError when the X-Hub-Signature header is missing' do
        controller.request.body = StringIO.new('{}')
        controller.request.headers['Content-Type'] = 'application/json'
        controller.request.headers['X-GitHub-Event'] = 'ping'
        expect { controller.send :authenticate_github_request! }.to raise_error(AbstractController::ActionNotFound)
      end
    end
  end
end
