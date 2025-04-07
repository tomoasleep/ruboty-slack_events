## Unreleased

- Let UserResolver#user_info_by_id return nil on user_not_found error (https://github.com/tomoasleep/ruboty-slack_events/pull/2)

## 0.3.0 - 2025-04-04

- Rewrite text filter to parse links and unescape HTML entities

## 0.2.0 - 2025-04-03

- Support reply on threads
- Ignore message events without text field

## 0.1.1 - 2025-04-02

- Add ./bin/run-ruboty script to run ruboty locally with this gem
- Fix message formatting issue when :code option is given

## 0.1.0 - 2025-04-01

- Initial release
