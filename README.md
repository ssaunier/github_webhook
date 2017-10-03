[![Build Status](https://travis-ci.org/ssaunier/github_webhook.svg?branch=master)](https://travis-ci.org/ssaunier/github_webhook)
[![Code Climate](https://codeclimate.com/github/ssaunier/github_webhook/badges/gpa.svg)](https://codeclimate.com/github/ssaunier/github_webhook)
[![Gem Version](https://badge.fury.io/rb/github_webhook.svg)](http://badge.fury.io/rb/github_webhook)


# GithubWebhook

This gem will help you to quickly setup a route in your Rails application which listens
to a [GitHub webhook](https://developer.github.com/webhooks/)

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'github_webhook', '~> 1.1'
```

And then execute:

    $ bundle install

## Configuration

First, configure a route to receive the github webhook POST requests.

```ruby
# config/routes.rb
resource :github_webhooks, only: :create, defaults: { formats: :json }
```

Then create a new controller:

```ruby
# app/controllers/github_webhooks_controller.rb
class GithubWebhooksController < ActionController::Base
  include GithubWebhook::Processor

  # Handle push event
  def github_push(payload)
    # TODO: handle push webhook
  end

  # Handle create event
  def github_create(payload)
    # TODO: handle create webhook
  end

  private

  def webhook_secret(payload)
    ENV['GITHUB_WEBHOOK_SECRET']
  end
end
```

Add as many instance methods as events you want to handle in
your controller.

All events are prefixed with `github_`. So, a `push` event can be handled by `github_push(payload)`, or a `create` event can be handled by `github_create(payload)`, etc.

You can read the [full list of events](https://developer.github.com/v3/activity/events/types/) GitHub can notify you about.

## Adding the Webhook to your git repository:

First, install [octokit](https://github.com/octokit/octokit.rb), then run a rails console.

```bash
$ gem install octokit
$ rails console
```

In the rails console, add the WebHook to GitHub:

```ruby
require "octokit"
client = Octokit::Client.new(:login => 'ssaunier', :password => 's3cr3t!!!')

repo = "ssaunier/github_webhook"
callback_url = "yourdomain.com/github_webhooks"
webhook_secret = "a_gr34t_s3cr3t"  # Must be set after that in ENV['GITHUB_WEBHOOK_SECRET']

# Create the WebHook
client.subscribe "https://github.com/#{repo}/events/push.json", callback_url, webhook_secret
```

The secret is set at the webhook creation. Store it in an environment variable,
`GITHUB_WEBHOOK_SECRET` as per the example. It is important to have such a secret,
as it will guarantee that your process legit webhooks requests, thus only from GitHub.

You can have an overview of your webhooks at the following URL:

```
https://github.com/:username/:repo/settings/hooks
```

## Contributing

### Specs

This project uses [Appraisal](https://github.com/thoughtbot/appraisal) to test against multiple
versions of Rails.

On Travis, builds are also run on multiple versions of Ruby, each with multiple versions of Rails.

When you run `bundle install`, it will use the latest version of Rails.
You can then run `bundle exec rake spec` to run the test with that version of Rails.

To run the specs against each version of Rails, use `bundle exec appraisal rake spec`.
