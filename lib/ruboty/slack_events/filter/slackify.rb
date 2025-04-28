# frozen_string_literal: true

module Ruboty
  module SlackEvents
    module Filter
      # Convert Ruboty text format to Slack text format
      class Slackify
        attr_reader :resolvers #: Resolvers

        # @rbs resolvers: Resolvers
        def initialize(resolvers:)
          @resolvers = resolvers
        end

        # @rbs text: String
        def call(text) #: String
          replace_user_mentions(text)
        end

        # @rbs text: String
        def replace_user_mentions(text) #: String
          text.to_s.gsub(/@(?<user_name>\w+)/) do |user_mention|
            user_name = Regexp.last_match[:user_name]
            user_info = resolvers.user_resolver.user_info_by_name(user_name)
            next user_mention unless user_info

            "<@#{user_info.id}>"
          end
        end
      end
    end
  end
end
