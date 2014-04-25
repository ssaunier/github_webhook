module GithubWebhook::Processor
  extend ActiveSupport::Concern

  included do
    before_filter :authenticate_github_request!, :only => :create
  end

  class SignatureError < StandardError; end
  class UnspecifiedWebhookSecretError < StandardError; end

  def create
    self.send json_body[:action], json_body
    head(:ok)
  end

  private

  HMAC_DIGEST = OpenSSL::Digest.new('sha1')

  def authenticate_github_request!
    raise UnspecifiedWebhookSecretError.new unless defined?(self.class::WEBHOOK_SECRET)

    expected_signature = "sha1=#{OpenSSL::HMAC.hexdigest(HMAC_DIGEST, self.class::WEBHOOK_SECRET, request_body)}"
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
end
