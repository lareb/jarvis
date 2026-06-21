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
  id: number;
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
  latest_automation_run?: TicketAutomationRun | null;
};

export type TicketAutomationRun = {
  id: number;
  jira_ticket_id: number;
  ticket_key: string;
  status:
    | "pending_approval"
    | "queued"
    | "running"
    | "ready_for_review"
    | "publishing"
    | "completed"
    | "failed";
  branch_name: string;
  base_branch: string;
  repository_path: string;
  worktree_path?: string | null;
  codex_thread_id?: string | null;
  codex_output?: string | null;
  error_message?: string | null;
  commit_sha?: string | null;
  created_at: string;
  updated_at: string;
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

export function createTicketAutomationRun(ticketId: number) {
  return request<{ run: TicketAutomationRun }>(`/api/v1/jira_tickets/${ticketId}/automation_runs`, {
    method: "POST"
  });
}

export function getTicketAutomationRun(runId: number) {
  return request<{ run: TicketAutomationRun }>(`/api/v1/ticket_automation_runs/${runId}`);
}

export function approveTicketAutomationRun(runId: number) {
  return request<{ run: TicketAutomationRun }>(`/api/v1/ticket_automation_runs/${runId}/approve`, {
    method: "POST"
  });
}

export function publishTicketAutomationRun(runId: number) {
  return request<{ run: TicketAutomationRun }>(`/api/v1/ticket_automation_runs/${runId}/publish`, {
    method: "POST"
  });
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
