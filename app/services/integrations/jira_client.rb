module Integrations
  class JiraClient < BaseClient
    MAX_RESULTS = 20
    PAGE_SIZE = 100

    def initialize(user:, connection: nil)
      super(user: user, provider: "jira", connection: connection)
    end

    def all_issues
      search_all("updated IS NOT EMPTY ORDER BY updated DESC")
    end

    def issues_involving(person)
      return [] if person.blank?

      search(%(text ~ "\\"#{sanitize_jql(person)}\\"" ORDER BY updated DESC))
    end

    def high_priority_issues
      search("priority in (Highest, High) AND statusCategory != Done ORDER BY updated DESC")
    end

    def recent_activity
      search("assignee = currentUser() AND updated >= -7d ORDER BY updated DESC")
    end

    private

    def search(jql)
      response = search_request(jql, max_results: MAX_RESULTS)

      ensure_success!(response).fetch("issues", []).map { |issue| context_item(issue) }
    end

    def search_all(jql)
      issues = []
      next_page_token = nil

      loop do
        response = ensure_success!(
          search_request(jql, max_results: PAGE_SIZE, next_page_token: next_page_token)
        )
        response_issues = response.fetch("issues", [])
        issues.concat(response_issues)

        next_page_token = response["nextPageToken"].presence
        break if response["isLast"] || next_page_token.blank?
      end

      issues.map { |issue| context_item(issue) }
    end

    def search_request(jql, max_results:, next_page_token: nil)
      connection(base_url).post("/rest/api/3/search/jql") do |request|
        request.headers["Authorization"] = "Basic #{Base64.strict_encode64("#{jira_email}:#{connected_account!.access_token}")}"
        request.headers["Accept"] = "application/json"
        request.body = {
          jql: scoped_jql(jql),
          maxResults: max_results,
          fields: %w[summary description priority status assignee reporter updated created labels],
          nextPageToken: next_page_token
        }.compact
      end
    end

    def context_item(issue)
      fields = issue.fetch("fields")
      {
        source: "jira",
        external_id: issue.fetch("key"),
        title: fields["summary"].presence || issue.fetch("key"),
        body: adf_text(fields["description"]),
        metadata: {
          priority: fields.dig("priority", "name"),
          status: fields.dig("status", "name"),
          status_category: fields.dig("status", "statusCategory", "name"),
          assignee: fields.dig("assignee", "displayName"),
          reporter: fields.dig("reporter", "displayName"),
          labels: fields["labels"],
          url: "#{base_url}/browse/#{issue.fetch('key')}"
        },
        occurred_at: parse_time(fields["updated"]) || parse_time(fields["created"])
      }
    end

    def adf_text(value)
      return value if value.is_a?(String)
      return if value.blank?

      value.to_json.scan(/"text":"((?:\\.|[^"])*)"/).flatten.map { |text| JSON.parse(%("#{text}")) }.join(" ").truncate(1000)
    end

    def scoped_jql(jql)
      projects = connected_account!.metadata["projects"].to_a.compact_blank
      return jql if projects.empty?

      filter, separator, ordering = jql.partition(/\s+ORDER BY\s+/i)
      scoped_filter = %(project in (#{projects.map { |key| %("#{sanitize_jql(key)}") }.join(', ')}) AND (#{filter}))

      separator.present? ? "#{scoped_filter} ORDER BY #{ordering}" : scoped_filter
    end

    def base_url
      @base_url ||= connected_account!.metadata.fetch("base_url").delete_suffix("/")
    rescue KeyError
      raise ConfigurationError, "jira metadata.base_url is required"
    end

    def jira_email
      connected_account!.metadata["email"].presence || user.email
    end

    def sanitize_jql(value)
      value.to_s.gsub(/["\\]/, "").squish
    end
  end
end
