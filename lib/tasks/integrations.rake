namespace :integrations do
  desc "Show integration connection status without printing credentials"
  task status: :environment do
    user = User.find_by(email: ENV.fetch("JARVIS_USER_EMAIL", "demo@example.com"))
    abort "Jarvis user not found" unless user

    IntegrationAccount::PROVIDERS.each do |provider|
      account = user.integration_accounts.find_by(provider: provider)
      puts "#{provider}: #{account&.status || 'not configured'}"
    end
  end

  desc "Configure real provider credentials for the demo user from environment variables"
  task configure: :environment do
    user = User.find_or_create_by!(email: ENV.fetch("JARVIS_USER_EMAIL", "demo@example.com")) do |record|
      record.name = ENV.fetch("JARVIS_USER_NAME", "Demo User")
    end

    configure_account(
      user,
      "gmail",
      access_token: ENV["GOOGLE_ACCESS_TOKEN"],
      refresh_token: ENV["GOOGLE_REFRESH_TOKEN"],
      metadata: {}
    )
    configure_account(
      user,
      "google_calendar",
      access_token: ENV["GOOGLE_ACCESS_TOKEN"],
      refresh_token: ENV["GOOGLE_REFRESH_TOKEN"],
      metadata: { "calendar_id" => ENV.fetch("GOOGLE_CALENDAR_ID", "primary") }
    )
    configure_account(
      user,
      "github",
      access_token: ENV["GITHUB_TOKEN"],
      metadata: {
        "login" => ENV["GITHUB_LOGIN"],
        "person_aliases" => JSON.parse(ENV.fetch("GITHUB_PERSON_ALIASES", "{}"))
      }.compact
    )
    configure_account(
      user,
      "jira",
      access_token: ENV["JIRA_API_TOKEN"],
      metadata: {
        "base_url" => ENV["JIRA_BASE_URL"],
        "email" => ENV["JIRA_EMAIL"],
        "projects" => ENV.fetch("JIRA_PROJECTS", "").split(",").map(&:strip).reject(&:blank?)
      }.compact
    )
  end

  def configure_account(user, provider, access_token:, metadata:, refresh_token: nil)
    credentials_present = access_token.present? || refresh_token.present?
    unless credentials_present
      puts "#{provider}: skipped (no credentials supplied)"
      return
    end

    account = user.integration_accounts.find_or_initialize_by(provider: provider)
    account.assign_attributes(
      access_token: access_token,
      refresh_token: refresh_token,
      metadata: metadata,
      status: "connected"
    )
    account.save!
    puts "#{provider}: #{account.status}"
  end
end
