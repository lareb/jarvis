module Integrations
  class GmailClient < BaseClient
    API_URL = "https://gmail.googleapis.com"
    MAX_RESULTS = 20

    def latest_from(person)
      return [] if person.blank?

      messages("from:(#{sanitize_query(person)}) newer_than:30d", max_results: 10)
    end

    def today_messages
      messages("after:#{Time.zone.today.strftime('%Y/%m/%d')} {is:important is:starred}")
    end

    private

    def messages(query, max_results: MAX_RESULTS)
      ids = get("/gmail/v1/users/me/messages", q: query, maxResults: max_results).fetch("messages", [])
      ids.filter_map { |message| message_details(message.fetch("id")) }
    end

    def message_details(id)
      payload = get(
        "/gmail/v1/users/me/messages/#{id}",
        format: "metadata",
        metadataHeaders: [ "From", "To", "Subject", "Date" ]
      )
      headers = payload.dig("payload", "headers").to_a.to_h { |header| [ header["name"].downcase, header["value"] ] }
      labels = payload.fetch("labelIds", [])

      {
        source: "gmail",
        external_id: payload.fetch("id"),
        title: headers["subject"].presence || "(no subject)",
        body: payload["snippet"],
        metadata: {
          from: headers["from"],
          to: headers["to"],
          thread_id: payload["threadId"],
          labels: labels,
          important: labels.include?("IMPORTANT") || labels.include?("STARRED")
        },
        occurred_at: Time.at(payload.fetch("internalDate").to_i / 1000.0)
      }
    end

    def get(path, params = {})
      response = connection(API_URL).get(path, params) do |request|
        request.headers["Authorization"] = "Bearer #{access_token}"
      end
      ensure_success!(response)
    end

    def access_token
      GoogleAccessToken.new(connected_account!).call
    end

    def sanitize_query(value)
      value.to_s.gsub(/[{}()]/, " ").squish
    end
  end
end
