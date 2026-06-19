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
    const text = await response.text();
    throw new Error(text || `Request failed with ${response.status}`);
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
