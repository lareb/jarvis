export type CommandResponse = {
  id: number;
  status: string;
  intent: string;
  summary: string;
  action_items: string[];
  suggested_response: string | null;
  confidence_score: number;
};

export type ContextItem = {
  source: string;
  external_id: string;
  title: string;
  body: string;
  metadata: Record<string, unknown>;
  occurred_at: string;
};

export type JiraTicket = ContextItem & {
  source: "jira";
  metadata: {
    priority?: string | null;
    project_key?: string | null;
    project_name?: string | null;
    status?: string | null;
    status_category?: string | null;
    assignee?: string | null;
    reporter?: string | null;
    labels?: string[];
    url?: string;
  };
};

export type JiraTicketsResponse = {
  tickets: JiraTicket[];
  total: number;
};

export type CommandDetails = {
  id: number;
  status: string;
  intent: string;
  command: string;
  response: CommandResponse;
  context: ContextItem[];
  suggested_actions: string[];
  error_message: string | null;
};

export type DailyBriefing = {
  meetings: ContextItem[];
  important_emails: ContextItem[];
  jira_priorities: ContextItem[];
  github_prs: ContextItem[];
  recommended_focus: string[];
};

const API_BASE_URL = process.env.NEXT_PUBLIC_API_BASE_URL || "http://localhost:3000";

async function request<T>(path: string, init?: RequestInit): Promise<T> {
  const response = await fetch(`${API_BASE_URL}${path}`, {
    ...init,
    headers: {
      "Content-Type": "application/json",
      ...init?.headers
    }
  });

  if (!response.ok) {
    const payload = await response.json().catch(() => null);
    throw new Error(payload?.error || `Request failed with ${response.status}`);
  }

  return response.json() as Promise<T>;
}

export function createCommand(command: string) {
  return request<CommandResponse>("/api/v1/commands", {
    method: "POST",
    body: JSON.stringify({ command })
  });
}

export function getCommand(id: number) {
  return request<CommandDetails>(`/api/v1/commands/${id}`);
}

export function getDailyBriefing() {
  return request<DailyBriefing>("/api/v1/daily_briefing");
}

export function getJiraTickets() {
  return request<JiraTicketsResponse>("/api/v1/jira_tickets");
}

export function checkJiraStatus() {
  return request<{ connected: boolean; email?: string; base_url?: string }>(
    "/api/v1/integrations/jira/status"
  );
}

export function setupJiraIntegration(email: string, api_token: string, base_url: string) {
  return request<{ success: boolean; metadata: Record<string, unknown> }>(
    "/api/v1/integrations/jira/setup",
    {
      method: "POST",
      body: JSON.stringify({ email, api_token, base_url })
    }
  );
}
