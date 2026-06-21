# Jarvis

Project Jarvis is a personal AI operating assistant. Phase 1 implements a read-only Daily Assistant MVP for an Engineering Manager / Full Stack Developer.

## Backend Stack

- Ruby on Rails API
- PostgreSQL
- Redis and Sidekiq
- OpenAI GPT API wrapper
- Real Gmail, Jira Cloud, GitHub, and Google Calendar REST clients

## Phase 1 Behavior

Jarvis behaves like a personal AI Chief of Staff, not a generic chatbot. The command pipeline is:

1. `CommandProcessor` persists and orchestrates the request.
2. `IntentDetector` maps natural language to a supported intent.
3. `ContextCollector` fetches read-only context from integration clients.
4. `AiSummaryService` generates a structured summary. It uses OpenAI when `OPENAI_API_KEY` is present and deterministic local summaries otherwise.
5. `ApprovalPolicy` blocks write actions for Phase 1.

Supported intents:

- `person_update`: "Any update from Anthony?"
- `important_emails`: "Summarize today's important emails."
- `daily_focus`: "What should I focus on today?"
- `daily_standup`: "Prepare my daily standup."

## Safety

Phase 1 is read-only. Jarvis can read, summarize, suggest action items, and draft possible responses. It must not send emails, delete/archive emails, create or close Jira tickets, modify GitHub data, or modify calendar events.

Future write actions should call `ApprovalPolicy.authorize!` before doing anything. Blocked actions currently raise `ApprovalPolicy::ReadOnlyViolation`.

## Setup

```bash
bundle install
bin/rails db:create db:migrate db:seed
bin/rails server
```

The Rails API runs on `http://localhost:3000`.

## Frontend

The Next.js frontend lives in `frontend/`.

```bash
cd frontend
npm install
npm run dev
```

The frontend runs on `http://localhost:3001` and calls the Rails API through `NEXT_PUBLIC_API_BASE_URL`.

For local development, create `frontend/.env.local` when the API is not on the default port:

```bash
NEXT_PUBLIC_API_BASE_URL=http://localhost:3000
```

Restart the Rails server after dependency or CORS changes.

Run Sidekiq separately when you want background jobs:

```bash
bundle exec sidekiq
```

Run tests:

```bash
bundle exec rspec
```

## API

### Create Command

```bash
curl -X POST http://localhost:3000/api/v1/commands \
  -H "Content-Type: application/json" \
  -d '{"command":"Any update from Anthony?"}'
```

Example response:

```json
{
  "intent": "person_update",
  "summary": "Anthony has recent activity: Anthony replied about the pending invoice and requested the updated timesheet.",
  "action_items": [
    "Share updated timesheet",
    "Confirm invoice amount"
  ],
  "suggested_response": "Hi Anthony, thanks for the update. I will share the revised timesheet and confirm the invoice amount shortly.",
  "confidence_score": 0.82,
  "id": 1,
  "status": "completed"
}
```

### Show Command

```bash
curl http://localhost:3000/api/v1/commands/1
```

Returns command status, detected intent, collected context, AI summary, suggested actions, and any error message.

### Daily Briefing

```bash
curl http://localhost:3000/api/v1/daily_briefing
```

Returns meetings, important emails, Jira priorities, GitHub PR review requests, and recommended focus items.

### Jira Tickets

```bash
curl http://localhost:3000/api/v1/jira_tickets
```

Returns all tickets from the Jira projects configured in `JIRA_PROJECTS`, ordered by most recently updated.
Fetched tickets are cached in the local `jira_tickets` table and updated by Jira issue key on every fetch.

## Integrations

Read-only REST clients live under `app/services/integrations`:

- `Integrations::GmailClient`
- `Integrations::JiraClient`
- `Integrations::GithubClient`
- `Integrations::GoogleCalendarClient`

Credentials are encrypted in `integration_accounts`. Missing or failed providers return no context while other connected providers continue to work.

### Configure provider credentials

Google OAuth must grant:

- `https://www.googleapis.com/auth/gmail.readonly`
- `https://www.googleapis.com/auth/calendar.readonly`

GitHub fine-grained tokens need read access to metadata, issues, and pull requests for the repositories Jarvis should search. Jira Cloud uses an API token for a user with Browse Projects permission.

Set the applicable variables and run the configuration task:

```bash
export GOOGLE_CLIENT_ID="..."
export GOOGLE_CLIENT_SECRET="..."
export GOOGLE_ACCESS_TOKEN="..."
export GOOGLE_REFRESH_TOKEN="..."
export GOOGLE_CALENDAR_ID="primary"

export GITHUB_TOKEN="..."
export GITHUB_LOGIN="your-github-login"
export GITHUB_PERSON_ALIASES='{"anthony":"anthony-github-login"}'

export JIRA_BASE_URL="https://your-company.atlassian.net"
export JIRA_EMAIL="you@example.com"
export JIRA_API_TOKEN="..."
export JIRA_PROJECTS="JAR,PLATFORM"

bin/rails integrations:configure
bin/rails integrations:status
```

Only variables for providers you want to connect are required. Restart Rails after configuring credentials. Google access tokens are refreshed automatically using the refresh token. The frontend continues to call the existing command and daily briefing endpoints.

## Jobs

Sidekiq-backed Active Job classes:

- `ProcessCommandJob`
- `DailyBriefingJob`
- `SyncGmailJob`
- `SyncJiraJob`
- `SyncGithubJob`
- `SyncCalendarJob`


## API keys
Official API references: 
Gmail (https://developers.google.com/workspace/gmail/api/reference/rest/v1/users.messages/list), 
Calendar (https://developers.google.com/workspace/calendar/api/v3/reference/events/list), 
GitHub (https://docs.github.com/en/rest/pulls/review-requests), 
Jira (https://developer.atlassian.com/cloud/jira/platform/rest/v3/api-group-issue-search/).
