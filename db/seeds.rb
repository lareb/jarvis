demo_user = User.find_or_create_by!(email: "demo@example.com") do |user|
  user.name = "Demo User"
end

IntegrationAccount::PROVIDERS.each do |provider|
  demo_user.integration_accounts.find_or_create_by!(provider: provider) do |account|
    account.status = "expired"
    account.metadata = {}
  end
end
