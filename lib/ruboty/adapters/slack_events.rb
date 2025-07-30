# frozen_string_literal: true

require "ruboty"

module Ruboty
  module Adapters
    class SlackEvents < Base
      env :SLACK_TOKEN, "Bot token. Ref: https://api.slack.com/concepts/token-types#bot"
      env :SLACK_APP_TOKEN, "App-level token. Ref: https://api.slack.com/concepts/token-types#app-level"
      env :SLACK_IGNORE_BOT_MESSAGE, "If this has truthy value, bot ignores messages by bots", optional: true
      env :SLACK_AUTO_RECONNECT, "If this has truthy value, reconnect websocket automatically", optional: true

      # @rbs!
      #   type robotMessage = {
      #     body: String,
      #     from: String,
      #     to: String,
      #     original: receivedMessage?,
      #     code: boolish?,
      #   }
      #   type receivedMessage = {
      #     body: String,
      #     from: String,
      #     from_name: String,
      #     to: String,
      #     thread_ts: String?,
      #   }

      def run
        init
        connect
      end

      # @rbs message: robotMessage
      def say(message)
        Ruboty::SlackEvents::Logger.debug("say") { message.to_json }

        text =
          if message[:code]
            <<~MARKDOWN
              ```
              #{message[:body]}
              ```
            MARKDOWN
          else
            slackify.call(message[:body].to_s)
          end

        slack_client.chat_postMessage(
          channel: message[:to],
          attachments: [],
          markdown_text: text,
          thread_ts: message.dig(:original, :thread_ts)
        )
      end

      def slack_client #: Slack::Web::Client
        @slack_client ||= ::Slack::Web::Client.new(token: ENV.fetch("SLACK_TOKEN", nil))
      end

      def resolvers #: ::Ruboty::SlackEvents::UserRepository
        @resolvers ||= ::Ruboty::SlackEvents::Resolvers.new(slack_client:)
      end

      def slackify #: ::Ruboty::SlackEvents::Filter::Slackify
        @slackify ||= ::Ruboty::SlackEvents::Filter::Slackify.new(resolvers:)
      end

      def rubotify #: ::Ruboty::SlackEvents::Filter::Rubotify
        @rubotify ||= ::Ruboty::SlackEvents::Filter::Rubotify.new(resolvers:)
      end

      def ignore_bot_message?
        [nil, "", "false"].none?(ENV.fetch("SLACK_IGNORE_BOT_MESSAGE", nil))
      end

      private

      def init
        response = slack_client.auth_test

        ENV["RUBOTY_NAME"] ||= response["user"]
      end

      def connect #: void
        # Socket mode requires app-level token. so, construct another client with app-level token.
        # Ref: https://api.slack.com/methods/apps.connections.open
        slack_app_client = ::Slack::Web::Client.new(token: ENV.fetch("SLACK_APP_TOKEN", nil))

        handler = SlackEventsHandler.new(self)
        auto_reconnect = [nil, "", "false"].none?(ENV.fetch("SLACK_AUTO_RECONNECT", nil))

        ::Ruboty::SlackEvents::Api::SocketClient.new(slack_client: slack_app_client,
                                                     auto_reconnect:).connect do |message|
          handler.handle_event(message)
        end
      end
    end
  end
end

require_relative "slack_events/slack_events_handler"
