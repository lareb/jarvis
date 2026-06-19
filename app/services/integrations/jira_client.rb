module Integrations
  class JiraClient < BaseClient
    MAX_RESULTS = 20

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
      response = connection(base_url).post("/rest/api/3/search/jql") do |request|
        request.headers["Authorization"] = "Basic #{Base64.strict_encode64("#{jira_email}:#{connected_account!.access_token}")}"
        request.headers["Accept"] = "application/json"
        request.body = {
          jql: scoped_jql(jql),
          maxResults: MAX_RESULTS,
          fields: %w[summary description priority status assignee reporter updated created labels]
        }
      end

      ensure_success!(response).fetch("issues", []).map { |issue| context_item(issue) }
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

      %(project in (#{projects.map { |key| %("#{sanitize_jql(key)}") }.join(', ')}) AND (#{jql}))
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
