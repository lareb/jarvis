"use client";

import {
  AlertCircle,
  Bot,
  CalendarDays,
  CheckCircle2,
  Clock3,
  Github,
  Inbox,
  Loader2,
  MessageSquareText,
  Send,
  Sparkles,
  TicketCheck
} from "lucide-react";
import { FormEvent, useEffect, useMemo, useState } from "react";
import {
  CommandDetails,
  CommandResponse,
  DailyBriefing,
  createCommand,
  getCommand,
  getDailyBriefing
} from "@/lib/api";

const suggestedCommands = [
  "Any update from Anthony?",
  "Summarize today's important emails.",
  "What should I focus on today?",
  "Prepare my daily standup."
];

type LoadState = "idle" | "loading" | "error";

export function JarvisWorkbench() {
  const [command, setCommand] = useState("Any update from Anthony?");
  const [result, setResult] = useState<CommandResponse | null>(null);
  const [details, setDetails] = useState<CommandDetails | null>(null);
  const [briefing, setBriefing] = useState<DailyBriefing | null>(null);
  const [commandState, setCommandState] = useState<LoadState>("idle");
  const [briefingState, setBriefingState] = useState<LoadState>("idle");
  const [error, setError] = useState<string | null>(null);

  const hasResult = Boolean(result);
  const confidenceLabel = useMemo(() => {
    if (!result) return "No summary";
    return `${Math.round(result.confidence_score * 100)}% confidence`;
  }, [result]);

  useEffect(() => {
    loadBriefing();
  }, []);

  async function submitCommand(event?: FormEvent<HTMLFormElement>) {
    event?.preventDefault();
    if (!command.trim()) return;

    setCommandState("loading");
    setError(null);

    try {
      const response = await createCommand(command.trim());
      setResult(response);
      const commandDetails = await getCommand(response.id);
      setDetails(commandDetails);
      setCommandState("idle");
    } catch (err) {
      setCommandState("error");
      setError(err instanceof Error ? err.message : "Unable to process command");
    }
  }

  async function loadBriefing() {
    setBriefingState("loading");

    try {
      setBriefing(await getDailyBriefing());
      setBriefingState("idle");
    } catch {
      setBriefingState("error");
    }
  }

  return (
    <main className="shell">
      <aside className="sidebar">
        <div className="brand">
          <div className="brandMark">
            <Bot size={22} />
          </div>
          <div>
            <h1>Jarvis</h1>
            <p>Chief of Staff</p>
          </div>
        </div>

        <nav className="navList" aria-label="Jarvis views">
          <a className="navItem active" href="#command">
            <MessageSquareText size={18} />
            Command
          </a>
          <a className="navItem" href="#briefing">
            <CalendarDays size={18} />
            Daily Briefing
          </a>
          <a className="navItem" href="#context">
            <Inbox size={18} />
            Context
          </a>
        </nav>

        <div className="statusBox">
          <div className="statusDot" />
          <span>Read-only Phase 1</span>
        </div>
      </aside>

      <section className="workspace">
        <header className="topbar">
          <div>
            <p className="eyebrow">Daily Assistant MVP</p>
            <h2>Work Context</h2>
          </div>
          <button className="iconTextButton" onClick={loadBriefing} disabled={briefingState === "loading"}>
            {briefingState === "loading" ? <Loader2 className="spin" size={18} /> : <Sparkles size={18} />}
            Refresh
          </button>
        </header>

        <div className="grid">
          <section id="command" className="panel commandPanel">
            <div className="panelHeader">
              <div>
                <p className="eyebrow">Ask Jarvis</p>
                <h3>Command</h3>
              </div>
              <span className="pill">{confidenceLabel}</span>
            </div>

            <form className="commandForm" onSubmit={submitCommand}>
              <input
                value={command}
                onChange={(event) => setCommand(event.target.value)}
                placeholder="Ask about a person, email, priorities, or standup"
              />
              <button type="submit" disabled={commandState === "loading"}>
                {commandState === "loading" ? <Loader2 className="spin" size={18} /> : <Send size={18} />}
                Run
              </button>
            </form>

            <div className="quickCommands">
              {suggestedCommands.map((item) => (
                <button key={item} type="button" onClick={() => setCommand(item)}>
                  {item}
                </button>
              ))}
            </div>

            {error ? (
              <div className="errorBox">
                <AlertCircle size={18} />
                <span>{error}</span>
              </div>
            ) : null}

            <div className={hasResult ? "answerBlock ready" : "answerBlock"}>
              {result ? (
                <>
                  <div className="intentRow">
                    <span>{result.intent}</span>
                    <span>{result.status}</span>
                  </div>
                  <p>{result.summary}</p>
                  <h4>Action Items</h4>
                  <ul>
                    {result.action_items.map((item) => (
                      <li key={item}>
                        <CheckCircle2 size={16} />
                        {item}
                      </li>
                    ))}
                  </ul>
                  {result.suggested_response ? (
                    <div className="draftBox">
                      <h4>Draft Response</h4>
                      <p>{result.suggested_response}</p>
                    </div>
                  ) : null}
                </>
              ) : (
                <p className="muted">Run a command to generate a summary, action items, and a draft response.</p>
              )}
            </div>
          </section>

          <section id="briefing" className="panel briefingPanel">
            <div className="panelHeader">
              <div>
                <p className="eyebrow">Today</p>
                <h3>Recommended Focus</h3>
              </div>
              <Clock3 size={20} />
            </div>

            <ul className="focusList">
              {(briefing?.recommended_focus || []).map((item) => (
                <li key={item}>{item}</li>
              ))}
            </ul>

            <div className="briefingStats">
              <Metric icon={<CalendarDays size={18} />} label="Meetings" value={briefing?.meetings.length || 0} />
              <Metric icon={<Inbox size={18} />} label="Emails" value={briefing?.important_emails.length || 0} />
              <Metric icon={<TicketCheck size={18} />} label="Jira" value={briefing?.jira_priorities.length || 0} />
              <Metric icon={<Github size={18} />} label="PRs" value={briefing?.github_prs.length || 0} />
            </div>
          </section>

          <section id="context" className="panel contextPanel">
            <div className="panelHeader">
              <div>
                <p className="eyebrow">Sources</p>
                <h3>Collected Context</h3>
              </div>
              <span className="pill">{details?.context.length || 0} items</span>
            </div>

            <div className="contextList">
              {(details?.context || []).map((item) => (
                <article key={`${item.source}-${item.external_id}`} className="contextItem">
                  <div>
                    <span className="source">{item.source}</span>
                    <h4>{item.title}</h4>
                    <p>{item.body}</p>
                  </div>
                </article>
              ))}
              {!details?.context.length ? <p className="muted">Context appears here after a command runs.</p> : null}
            </div>
          </section>
        </div>
      </section>
    </main>
  );
}

function Metric({ icon, label, value }: { icon: React.ReactNode; label: string; value: number }) {
  return (
    <div className="metric">
      {icon}
      <span>{label}</span>
      <strong>{value}</strong>
    </div>
  );
}
