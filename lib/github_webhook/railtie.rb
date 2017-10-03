require 'rails'

module GithubWebhook
  class Railties < ::Rails::Railtie
    initializer 'Rails logger' do
      GithubWebhook.logger = Rails.logger
    end
  end
end
