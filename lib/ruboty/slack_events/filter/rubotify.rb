# frozen_string_literal: true

require "cgi"

module Ruboty
  module SlackEvents
    module Filter
      # Convert Slack text format to Ruboty format
      # For more details of Slack text format, see: https://api.slack.com/reference/surfaces/formatting
      class Rubotify
        attr_reader :resolvers #: Resolvers

        # @rbs resolvers: Resolvers
        def initialize(resolvers:)
          @resolvers = resolvers
        end

        # @rbs text: String
        def call(text) #: String
          text
            .then { replace_user_mentions(_1) }
            .then { replace_link(_1) }
            .then { unescape(_1) }
        end

        private

        # @rbs text: String
        def replace_user_mentions(text) #: String
          text.gsub(/<@(?<user_id>\w+)>/) do |user_mention|
            user_id = Regexp.last_match[:user_id]

            user_info = resolvers.user_resolver.user_info_by_id(user_id)

            next user_mention unless user_info

            "@#{user_info.name}"
          end
        end

        # @rbs text: String
        def replace_link(text) #: String
          text.gsub(/<(?<url>[^>|]+)(?:\|(?<text>[^>]+))?>/) do |link|
            url = Regexp.last_match[:url]
            text = Regexp.last_match[:text]

            begin
              next link unless URI.parse(url).scheme
            rescue URI::InvalidURIError, URI::InvalidComponentError
              next link
            end

            text || url
          end
        end

        # Unescape HTML entities in the text.
        # See: https://api.slack.com/reference/surfaces/formatting#escaping
        # @rbs text: String
        def unescape(text) #: String
          CGI.unescapeHTML(text)
        end
      end
    end
  end
end
