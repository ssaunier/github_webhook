module GithubWebhook::Processor
  extend ActiveSupport::Concern
  require 'abstract_controller'

  included do
    before_action :authenticate_github_request!, only: :create
    before_action :check_github_event!, only: :create
  end

  # To fetch list from https://developer.github.com/v3/activity/events/types
  # run this little JS code in the console:
  #    document.querySelectorAll('.list-style-none li.lh-condensed a').forEach(e => console.log(e.text))
  GITHUB_EVENTS = %w(
    branch_protection_rule
    check_run
    check_suite
    code_scanning_alert
    commit_comment
    create
    delete
    dependabot_alert
    deploy_key
    deployment
    deployment_status
    discussion
    discussion_comment
    fork
    github_app_authorization
    gollum
    installation
    installation_repositories
    installation_target
    issue_comment
    issues
    label
    marketplace_purchase
    member
    membership
    merge_group
    meta
    milestone
    org_block
    organization
    package
    page_build
    ping
    project_card
    project
    project_column
    projects_v2
    projects_v2_item
    public
    pull_request
    pull_request_review_comment
    pull_request_review
    pull_request_review_thread
    push
    registry_package
    release
    repository
    repository_dispatch
    repository_import
    repository_vulnerability_alert
    secret_scanning_alert
    secret_scanning_alert_location
    security_advisory
    security_and_analysis
    sponsorship
    star
    status
    team_add
    team
    watch
    workflow_dispatch
    workflow_job
    workflow_run
  )

  def create
    if self.respond_to?(event_method, true)
      self.send event_method, json_body
      head(:ok)
    else
      raise AbstractController::ActionNotFound.new("GithubWebhooksController##{event_method} not implemented")
    end
  end

  def github_ping(payload)
    GithubWebhook.logger && GithubWebhook.logger.info("[GithubWebhook::Processor] Hook ping "\
      "received, hook_id: #{payload[:hook_id]}, #{payload[:zen]}")
  end

  private

  HMAC_DIGEST = OpenSSL::Digest.new('sha256')

  def authenticate_github_request!
    raise AbstractController::ActionNotFound.new unless respond_to?(:webhook_secret, true)
    secret = webhook_secret(json_body)

    expected_signature = "sha256=#{OpenSSL::HMAC.hexdigest(HMAC_DIGEST, secret, request_body)}"
    unless ActiveSupport::SecurityUtils.secure_compare(signature_header, expected_signature)
      GithubWebhook.logger && GithubWebhook.logger.warn("[GithubWebhook::Processor] signature "\
        "invalid, actual: #{signature_header}, expected: #{expected_signature}")
      raise AbstractController::ActionNotFound
    end
  end

  def check_github_event!
    unless GITHUB_EVENTS.include?(request.headers['X-GitHub-Event'])
      raise AbstractController::ActionNotFound.new("#{request.headers['X-GitHub-Event']} is not a whitelisted GitHub event. See https://developer.github.com/v3/activity/events/types/")
    end
  end

  def request_body
    @request_body ||= (
      request.body.rewind
      request.body.read
    )
  end

  def json_body
    @json_body ||= (
      content_type = request.headers['Content-Type']
      case content_type
      when 'application/x-www-form-urlencoded'
        require 'rack'
        payload = Rack::Utils.parse_query(request_body)['payload']
      when 'application/json'
        payload = request_body
      else
        raise AbstractController::ActionNotFound.new(
          "Content-Type #{content_type} is not supported. Use 'application/x-www-form-urlencoded' or 'application/json")
      end
      ActiveSupport::HashWithIndifferentAccess.new(JSON.load(payload))
    )
  end

  def signature_header
    @signature_header ||= request.headers['X-Hub-Signature-256'] || ''
  end

  def event_method
    @event_method ||= "github_#{request.headers['X-GitHub-Event']}".to_sym
  end
end
