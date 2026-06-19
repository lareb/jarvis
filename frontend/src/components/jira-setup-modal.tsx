"use client";

import { AlertCircle, Loader2, X } from "lucide-react";
import { useState } from "react";
import { setupJiraIntegration } from "@/lib/api";

interface JiraSetupModalProps {
  onClose: () => void;
  onSuccess: () => void;
}

export function JiraSetupModal({ onClose, onSuccess }: JiraSetupModalProps) {
  const [email, setEmail] = useState("");
  const [apiToken, setApiToken] = useState("");
  const [baseUrl, setBaseUrl] = useState("https://your-domain.atlassian.net");
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    setError(null);
    setLoading(true);

    try {
      await setupJiraIntegration(email, apiToken, baseUrl);
      onSuccess();
      onClose();
    } catch (err) {
      setError(err instanceof Error ? err.message : "Setup failed");
    } finally {
      setLoading(false);
    }
  }

  return (
    <div className="modalOverlay" onClick={onClose}>
      <div className="modal" onClick={(e) => e.stopPropagation()}>
        <div className="modalHeader">
          <h2>Connect Jira</h2>
          <button className="closeButton" onClick={onClose} disabled={loading}>
            <X size={20} />
          </button>
        </div>

        <form onSubmit={handleSubmit} className="modalForm">
          {error && (
            <div className="errorAlert">
              <AlertCircle size={18} />
              <span>{error}</span>
            </div>
          )}

          <div className="formGroup">
            <label htmlFor="email">Jira Email</label>
            <input
              id="email"
              type="email"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              placeholder="your-email@example.com"
              required
              disabled={loading}
            />
          </div>

          <div className="formGroup">
            <label htmlFor="baseUrl">Jira Base URL</label>
            <input
              id="baseUrl"
              type="url"
              value={baseUrl}
              onChange={(e) => setBaseUrl(e.target.value)}
              placeholder="https://your-domain.atlassian.net"
              required
              disabled={loading}
            />
          </div>

          <div className="formGroup">
            <label htmlFor="apiToken">
              API Token{" "}
              <a
                href="https://support.atlassian.com/atlassian-account/docs/manage-api-tokens-for-your-atlassian-account/"
                target="_blank"
                rel="noreferrer"
                className="helpLink"
              >
                (how to generate)
              </a>
            </label>
            <input
              id="apiToken"
              type="password"
              value={apiToken}
              onChange={(e) => setApiToken(e.target.value)}
              placeholder="Enter your Jira API token"
              required
              disabled={loading}
            />
          </div>

          <div className="modalFooter">
            <button type="button" className="secondaryButton" onClick={onClose} disabled={loading}>
              Cancel
            </button>
            <button type="submit" className="primaryButton" disabled={loading}>
              {loading ? (
                <>
                  <Loader2 className="spin" size={18} />
                  Connecting...
                </>
              ) : (
                "Connect Jira"
              )}
            </button>
          </div>
        </form>

        <style jsx>{`
          .modalOverlay {
            position: fixed;
            inset: 0;
            background: rgba(0, 0, 0, 0.5);
            display: flex;
            align-items: center;
            justify-content: center;
            z-index: 1000;
          }

          .modal {
            background: white;
            border-radius: 8px;
            box-shadow: 0 20px 25px -5px rgba(0, 0, 0, 0.1);
            width: 90%;
            max-width: 420px;
            max-height: 90vh;
            overflow-y: auto;
          }

          .modalHeader {
            display: flex;
            justify-content: space-between;
            align-items: center;
            padding: 24px;
            border-bottom: 1px solid #e5e7eb;
          }

          .modalHeader h2 {
            margin: 0;
            font-size: 1.25rem;
            font-weight: 600;
            color: #111827;
          }

          .closeButton {
            background: none;
            border: none;
            cursor: pointer;
            padding: 4px;
            display: flex;
            align-items: center;
            justify-content: center;
            color: #6b7280;
            transition: color 0.2s;
          }

          .closeButton:hover:not(:disabled) {
            color: #111827;
          }

          .closeButton:disabled {
            opacity: 0.5;
            cursor: not-allowed;
          }

          .modalForm {
            padding: 24px;
            display: flex;
            flex-direction: column;
            gap: 16px;
          }

          .errorAlert {
            display: flex;
            gap: 12px;
            padding: 12px;
            background: #fee2e2;
            color: #991b1b;
            border-radius: 6px;
            align-items: flex-start;
            font-size: 0.875rem;
          }

          .formGroup {
            display: flex;
            flex-direction: column;
            gap: 8px;
          }

          .formGroup label {
            font-size: 0.875rem;
            font-weight: 500;
            color: #374151;
          }

          .helpLink {
            color: #3b82f6;
            text-decoration: none;
            font-weight: normal;
          }

          .helpLink:hover {
            text-decoration: underline;
          }

          .formGroup input {
            padding: 10px 12px;
            border: 1px solid #d1d5db;
            border-radius: 6px;
            font-size: 0.875rem;
            transition: border-color 0.2s;
          }

          .formGroup input:focus {
            outline: none;
            border-color: #3b82f6;
            box-shadow: 0 0 0 3px rgba(59, 130, 246, 0.1);
          }

          .formGroup input:disabled {
            background: #f3f4f6;
            color: #9ca3af;
            cursor: not-allowed;
          }

          .modalFooter {
            display: flex;
            gap: 12px;
            padding: 24px;
            border-top: 1px solid #e5e7eb;
            justify-content: flex-end;
          }

          .primaryButton,
          .secondaryButton {
            display: flex;
            align-items: center;
            gap: 8px;
            padding: 10px 16px;
            border-radius: 6px;
            font-size: 0.875rem;
            font-weight: 500;
            cursor: pointer;
            transition: all 0.2s;
            border: none;
          }

          .primaryButton {
            background: #3b82f6;
            color: white;
          }

          .primaryButton:hover:not(:disabled) {
            background: #2563eb;
          }

          .primaryButton:disabled {
            background: #9ca3af;
            cursor: not-allowed;
          }

          .secondaryButton {
            background: white;
            color: #374151;
            border: 1px solid #d1d5db;
          }

          .secondaryButton:hover:not(:disabled) {
            background: #f9fafb;
          }

          .secondaryButton:disabled {
            opacity: 0.5;
            cursor: not-allowed;
          }

          .spin {
            animation: spin 1s linear infinite;
          }

          @keyframes spin {
            from {
              transform: rotate(0deg);
            }
            to {
              transform: rotate(360deg);
            }
          }
        `}</style>
      </div>
    </div>
  );
}
