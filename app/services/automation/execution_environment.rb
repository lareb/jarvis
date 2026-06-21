module Automation
  module ExecutionEnvironment
    module_function

    def codex
      select(ENV.fetch(
        "JARVIS_CODEX_ENV_ALLOWLIST",
        "PATH,HOME,CODEX_HOME,CODEX_API_KEY,LANG,LC_ALL,TERM"
      )).merge("JARVIS_TICKET_PROMPT" => "1")
    end

    def git
      select(ENV.fetch(
        "JARVIS_GIT_ENV_ALLOWLIST",
        "PATH,HOME,SSH_AUTH_SOCK,GIT_ASKPASS,GIT_SSH_COMMAND,LANG,LC_ALL,TERM"
      ))
    end

    def select(csv)
      ENV.to_h.slice(*csv.split(",").map(&:strip).reject(&:blank?))
    end
  end
end
