module Integrations
  class GithubClient < BaseClient
    API_URL = "https://api.github.com"
    API_VERSION = "2022-11-28"

    def mentions_for(person)
      login = person_alias(person)
      return [] if login.blank?

      search_issues("is:open involves:#{login} updated:>=#{30.days.ago.to_date}")
    end

    def pending_review_requests
      search_issues("is:pr is:open review-requested:#{viewer_login}")
    end

    def recent_work
      search_issues("involves:#{viewer_login} updated:>=#{7.days.ago.to_date}")
    end

    private

    def search_issues(query)
      get("/search/issues", q: query, sort: "updated", order: "desc", per_page: 20)
        .fetch("items", [])
        .map { |item| context_item(item) }
    end

    def context_item(item)
      repository_url = item["repository_url"].to_s
      {
        source: "github",
        external_id: item.fetch("id").to_s,
        title: item.fetch("title"),
        body: item["body"].to_s.truncate(1000),
        metadata: {
          repository: repository_url.split("/repos/").last,
          number: item["number"],
          state: item["state"],
          type: item.key?("pull_request") ? "pull_request" : "issue",
          html_url: item["html_url"],
          author: item.dig("user", "login")
        },
        occurred_at: parse_time(item["updated_at"]) || parse_time(item["created_at"])
      }
    end

    def viewer_login
      connected_account!.metadata["login"].presence || get("/user").fetch("login")
    end

    def person_alias(person)
      aliases = connected_account!.metadata.fetch("person_aliases", {})
      aliases[person.to_s.downcase] || person.to_s.strip.gsub(/\s+/, "")
    end

    def get(path, params = {})
      response = connection(API_URL).get(path, params) do |request|
        request.headers["Authorization"] = "Bearer #{connected_account!.access_token}"
        request.headers["Accept"] = "application/vnd.github+json"
        request.headers["X-GitHub-Api-Version"] = API_VERSION
        request.headers["User-Agent"] = "jarvis-assistant"
      end
      ensure_success!(response)
    end
  end
end
