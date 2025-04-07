# frozen_string_literal: true

module Ruboty
  module SlackEvents
    class Resolvers
      class UserResolver
        attr_reader :slack_client #: Slack::Web::Client

        # @rbs slack_client: Slack::Web::Client
        def initialize(slack_client:)
          @slack_client = slack_client

          @user_caches = {}
        end

        # @rbs!
        #   # Full fields are described in https://api.slack.com/methods/users.info
        #   type userInfo = {
        #     id: String,
        #     name: String,
        #     real_name: String,
        #     is_bot: boolish,
        #     is_app_user: boolish,
        #   }

        # Calls user_info API with cache.
        # @rbs user_id: String
        def user_info_by_id(user_id) #: userInfo?
          return nil if user_id.nil?

          ensure_users

          @user_caches[user_id] ||= begin
            Logger.debug { "Slack API: users.info(#{user_id})" }
            res = slack_client.users_info(user: user_id)
            res.user
          rescue Slack::Web::Api::Errors::UserNotFound => e
            Logger.debug { "Slack API Error: users.info(#{user_id}) => #{e.message}" }
            nil
          end
        end

        # @rbs user_name: String
        def user_info_by_name(user_name) #: userInfo?
          return nil if user_name.nil?

          ensure_users

          @user_caches.find do |_, user|
            user.name == user_name
          end&.last
        end

        # Clears all user caches.
        def forget #: void
          @user_caches.clear
        end

        private

        def ensure_users
          return unless @user_caches.empty?

          Logger.debug { "Slack API: users.list()" }
          res = slack_client.users_list

          res.members.each do |user|
            @user_caches[user.id] = user
          end
        end
      end
    end
  end
end
