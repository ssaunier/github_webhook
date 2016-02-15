module GithubWebhook::Processor
  extend ActiveSupport::Concern

  included do
    before_filter :authenticate_github_request!, only: :create
    before_filter :check_github_event!, only: :create
  end

  class SignatureError < StandardError; end
  class UnspecifiedWebhookSecretError < StandardError; end
  class UnsupportedGithubEventError < StandardError; end

  GITHUB_EVENTS_WHITELIST = %w(ping commit_comment create delete deployment deployment_status download follow fork fork_apply gist gollum issue_comment issues member membership page_build public pull_request pull_request_review_comment push release repository status team_add watch)

  def create
    if self.respond_to? event_method
      self.send event_method, json_body
      head(:ok)
    else
      raise NoMethodError.new("GithubWebhooksController##{event_method} not implemented")
    end
  end

  def ping(payload)
    puts "[GithubWebhook::Processor] Hook ping received, hook_id: #{payload[:hook_id]}, #{payload[:zen]}"
  end

  private

  HMAC_DIGEST = OpenSSL::Digest.new('sha1')

  def authenticate_github_request!
    raise UnspecifiedWebhookSecretError.new unless respond_to?(:webhook_secret)
    secret = webhook_secret(json_body)

    expected_signature = "sha1=#{OpenSSL::HMAC.hexdigest(HMAC_DIGEST, secret, request_body)}"
    if signature_header != expected_signature
      raise SignatureError.new "Actual: #{signature_header}, Expected: #{expected_signature}"
    end
  end

  def check_github_event!
    unless GITHUB_EVENTS_WHITELIST.include?(request.headers['X-GitHub-Event'])
      raise UnsupportedGithubEventError.new("#{request.headers['X-GitHub-Event']} is not a whiltelisted GitHub event. See https://developer.github.com/v3/activity/events/types/")
    end
  end

  def request_body
    @request_body ||= (
      request.body.rewind
      request.body.read
    )
  end

  def json_body
    @json_body ||= ActiveSupport::HashWithIndifferentAccess.new(JSON.load(request_body))
  end

  def signature_header
    @signature_header ||= request.headers['X-Hub-Signature']
  end

  def event_method
    @event_method ||= "github_#{request.headers['X-GitHub-Event']}".to_sym
  end
end
