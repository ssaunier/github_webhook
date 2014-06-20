module GithubWebhook::Processor
  extend ActiveSupport::Concern

  included do
    before_filter :authenticate_github_request!, :only => :create
  end

  class SignatureError < StandardError; end
  class UnspecifiedWebhookSecretError < StandardError; end

  def create
    if self.respond_to? event
      self.send event, json_body
      head(:ok)
    else
      raise NoMethodError.new("GithubWebhooksController##{event} not implemented")
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

  def event
    @event ||= request.headers['X-GitHub-Event'].to_sym
  end
end
