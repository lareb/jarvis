Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  namespace :api do
    namespace :v1 do
      resources :commands, only: [:create, :show]
      get "daily_briefing", to: "daily_briefings#show"
      resources :jira_tickets, only: [:index] do
        resources :automation_runs, only: [:create], controller: "ticket_automation_runs"
      end
      resources :ticket_automation_runs, only: [:show] do
        member do
          post :approve
          post :publish
        end
      end
      post "integrations/jira/setup", to: "integrations#jira_setup"
      get "integrations/jira/status", to: "integrations#jira_status"
    end
  end

  # Defines the root path route ("/")
  # root "posts#index"
end
