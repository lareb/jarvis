"use client";

import {
  AlertCircle,
  ArrowUpRight,
  CheckCircle2,
  CircleDot,
  CloudDownload,
  Loader2,
  RefreshCw,
  TicketCheck
} from "lucide-react";
import { useEffect, useMemo, useState } from "react";
import { checkJiraStatus, getJiraTickets, JiraTicket } from "@/lib/api";
import { JiraSetupModal } from "./jira-setup-modal";

type LoadState = "idle" | "loading" | "success" | "error";

export function JarvisWorkbench() {
  const [tickets, setTickets] = useState<JiraTicket[]>([]);
  const [loadState, setLoadState] = useState<LoadState>("idle");
  const [error, setError] = useState<string | null>(null);
  const [jiraConnected, setJiraConnected] = useState(false);
  const [showSetupModal, setShowSetupModal] = useState(false);
  const [checkingStatus, setCheckingStatus] = useState(true);

  const openTickets = useMemo(
    () => tickets.filter((ticket) => ticket.metadata.status_category?.toLowerCase() !== "done").length,
    [tickets]
  );

  useEffect(() => {
    checkConnection();
  }, []);

  async function checkConnection() {
    try {
      const status = await checkJiraStatus();
      setJiraConnected(status.connected);
      setCheckingStatus(false);
    } catch {
      setJiraConnected(false);
      setCheckingStatus(false);
    }
  }

  async function loadTickets() {
    if (!jiraConnected) {
      setShowSetupModal(true);
      return;
    }

    await fetchTickets();
  }

  async function fetchTickets() {
    setLoadState("loading");
    setError(null);

    try {
      const response = await getJiraTickets();
      setTickets(response.tickets);
      setLoadState("success");
    } catch (err) {
      setLoadState("error");
      setError(err instanceof Error ? err.message : "Unable to fetch Jira tickets");
    }
  }

  async function handleSetupSuccess() {
    setJiraConnected(true);
    await fetchTickets();
  }

  if (checkingStatus) {
    return (
      <main className="jiraShell">
        <header className="jiraHeader">
          <div className="jiraBrand">
            <div className="jiraMark">
              <TicketCheck size={24} />
            </div>
            <div>
              <p className="eyebrow">Jarvis integration</p>
              <h1>Jira workspace</h1>
            </div>
          </div>
        </header>

        <section className="emptyState">
          <Loader2 className="spin emptyLoader" size={30} />
          <h3>Checking Jira connection</h3>
        </section>
      </main>
    );
  }

  return (
    <main className="jiraShell">
      <header className="jiraHeader">
        <div className="jiraBrand">
          <div className="jiraMark">
            <TicketCheck size={24} />
          </div>
          <div>
            <p className="eyebrow">Jarvis integration</p>
            <h1>Jira workspace</h1>
          </div>
        </div>
        <span className="connectionStatus">
          <span className={`statusDot ${jiraConnected ? "connected" : "disconnected"}`} />
          {jiraConnected ? "Connected" : "Not connected"}
        </span>
      </header>

      <section className="jiraHero">
        <div>
          <p className="eyebrow">Your work, in one place</p>
          <h2>Fetch every ticket from Jira</h2>
          <p className="heroCopy">
            Load tickets from the Jira projects configured for this account. No tickets are changed.
          </p>
        </div>
        <button
          className="primaryButton"
          onClick={loadTickets}
          disabled={loadState === "loading" || checkingStatus}
          title={!jiraConnected ? "Connect Jira first" : ""}
        >
          {loadState === "loading" ? <Loader2 className="spin" size={19} /> : <CloudDownload size={19} />}
          {loadState === "loading" ? "Fetching tickets..." : !jiraConnected ? "Connect Jira" : tickets.length ? "Fetch again" : "Fetch all Jira tickets"}
        </button>
      </section>

      {error ? (
        <div className="errorBox" role="alert">
          <AlertCircle size={19} />
          <div>
            <strong>Jira could not be reached</strong>
            <p>{error}</p>
          </div>
        </div>
      ) : null}

      {loadState === "idle" && jiraConnected ? (
        <section className="emptyState">
          <div className="emptyIcon">
            <CloudDownload size={28} />
          </div>
          <h3>No tickets loaded yet</h3>
          <p>Use the button above to retrieve tickets from your configured Jira projects.</p>
        </section>
      ) : null}

      {loadState === "idle" && !jiraConnected ? (
        <section className="emptyState">
          <div className="emptyIcon">
            <AlertCircle size={28} />
          </div>
          <h3>Jira not connected</h3>
          <p>Connect your Jira account to fetch and view your tickets.</p>
          <button className="primaryButton" onClick={() => setShowSetupModal(true)}>
            Connect Jira
          </button>
        </section>
      ) : null}

      {loadState === "loading" ? (
        <section className="emptyState" aria-live="polite">
          <Loader2 className="spin emptyLoader" size={30} />
          <h3>Fetching Jira tickets</h3>
          <p>This may take a moment when your projects contain many tickets.</p>
        </section>
      ) : null}

      {loadState === "success" ? (
        <>
          <section className="summaryGrid" aria-label="Jira ticket summary">
            <SummaryCard icon={<TicketCheck size={20} />} label="Total tickets" value={tickets.length} />
            <SummaryCard icon={<CircleDot size={20} />} label="Open tickets" value={openTickets} />
            <SummaryCard
              icon={<CheckCircle2 size={20} />}
              label="Done tickets"
              value={tickets.length - openTickets}
            />
          </section>

          <section className="ticketPanel">
            <div className="ticketPanelHeader">
              <div>
                <p className="eyebrow">Latest updates first</p>
                <h3>Jira tickets</h3>
              </div>
              <button className="secondaryButton" onClick={loadTickets}>
                <RefreshCw size={16} />
                Refresh
              </button>
            </div>

            {tickets.length ? (
              <div className="ticketList">
                {tickets.map((ticket) => (
                  <TicketRow key={ticket.external_id} ticket={ticket} />
                ))}
              </div>
            ) : (
              <div className="emptyResults">
                <h4>No tickets found</h4>
                <p>The configured Jira projects did not return any tickets.</p>
              </div>
            )}
          </section>
        </>
      ) : null}

      {showSetupModal && (
        <JiraSetupModal
          onClose={() => setShowSetupModal(false)}
          onSuccess={handleSetupSuccess}
        />
      )}

      <style jsx>{`
        .statusDot {
          display: inline-block;
          width: 8px;
          height: 8px;
          border-radius: 50%;
          background: #ef4444;
          margin-right: 8px;
        }

        .statusDot.connected {
          background: #10b981;
        }
      `}</style>
    </main>
  );
}

function SummaryCard({ icon, label, value }: { icon: React.ReactNode; label: string; value: number }) {
  return (
    <article className="summaryCard">
      <div className="summaryIcon">{icon}</div>
      <div>
        <span>{label}</span>
        <strong>{value}</strong>
      </div>
    </article>
  );
}

function TicketRow({ ticket }: { ticket: JiraTicket }) {
  const updatedAt = ticket.occurred_at
    ? new Intl.DateTimeFormat("en", { dateStyle: "medium", timeStyle: "short" }).format(
        new Date(ticket.occurred_at)
      )
    : "Unknown";

  return (
    <article className="ticketRow">
      <div className="ticketMain">
        <div className="ticketIdentity">
          <span className="ticketKey">{ticket.external_id}</span>
          <StatusPill status={ticket.metadata.status} />
          {ticket.metadata.priority ? <span className="priorityPill">{ticket.metadata.priority}</span> : null}
        </div>
        <h4>{ticket.title}</h4>
        {ticket.body ? <p>{ticket.body}</p> : null}
      </div>
      <div className="ticketMeta">
        <span>
          <strong>Assignee</strong>
          {ticket.metadata.assignee || "Unassigned"}
        </span>
        <span>
          <strong>Updated</strong>
          {updatedAt}
        </span>
        {ticket.metadata.url ? (
          <a href={ticket.metadata.url} target="_blank" rel="noreferrer">
            Open in Jira
            <ArrowUpRight size={15} />
          </a>
        ) : null}
      </div>
    </article>
  );
}

function StatusPill({ status }: { status?: string | null }) {
  return <span className="statusPill">{status || "Unknown status"}</span>;
}
