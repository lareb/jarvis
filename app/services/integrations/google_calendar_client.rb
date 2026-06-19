module Integrations
  class GoogleCalendarClient < BaseClient
    API_URL = "https://www.googleapis.com/calendar/v3"

    def today_events
      calendar_id = connected_account!.metadata["calendar_id"].presence || "primary"
      response = connection(API_URL).get("/calendar/v3/calendars/#{CGI.escapeURIComponent(calendar_id)}/events", {
        timeMin: Time.zone.today.beginning_of_day.iso8601,
        timeMax: Time.zone.today.end_of_day.iso8601,
        singleEvents: true,
        orderBy: "startTime",
        maxResults: 50
      }) do |request|
        request.headers["Authorization"] = "Bearer #{access_token}"
      end

      ensure_success!(response).fetch("items", []).filter_map { |event| context_item(event) }
    end

    private

    def context_item(event)
      return if event["status"] == "cancelled"

      starts_at = parse_time(event.dig("start", "dateTime")) ||
        parse_time(event.dig("start", "date")) ||
        Time.zone.today.beginning_of_day

      {
        source: "google_calendar",
        external_id: event.fetch("id"),
        title: event["summary"].presence || "(untitled event)",
        body: event["description"].presence || event["location"],
        metadata: {
          starts_at: starts_at.iso8601,
          ends_at: event.dig("end", "dateTime") || event.dig("end", "date"),
          location: event["location"],
          attendees: event.fetch("attendees", []).map { |attendee| attendee.slice("email", "displayName", "responseStatus") },
          html_link: event["htmlLink"]
        },
        occurred_at: starts_at
      }
    end

    def access_token
      GoogleAccessToken.new(connected_account!).call
    end
  end
end
