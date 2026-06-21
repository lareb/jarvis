# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.2].define(version: 2026_06_20_120000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "ai_summaries", force: :cascade do |t|
    t.bigint "command_id", null: false
    t.text "summary"
    t.jsonb "action_items", default: [], null: false
    t.text "suggested_response"
    t.decimal "confidence_score", precision: 5, scale: 2, default: "0.0", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["command_id"], name: "index_ai_summaries_on_command_id", unique: true
  end

  create_table "commands", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.text "raw_text", null: false
    t.string "intent"
    t.string "status", default: "pending", null: false
    t.jsonb "response", default: {}, null: false
    t.text "error_message"
    t.datetime "started_at"
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["intent"], name: "index_commands_on_intent"
    t.index ["user_id", "status"], name: "index_commands_on_user_id_and_status"
    t.index ["user_id"], name: "index_commands_on_user_id"
  end

  create_table "context_items", force: :cascade do |t|
    t.bigint "command_id", null: false
    t.string "source", null: false
    t.string "external_id"
    t.string "title", null: false
    t.text "body"
    t.jsonb "metadata", default: {}, null: false
    t.datetime "occurred_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["command_id", "source"], name: "index_context_items_on_command_id_and_source"
    t.index ["command_id"], name: "index_context_items_on_command_id"
    t.index ["occurred_at"], name: "index_context_items_on_occurred_at"
  end

  create_table "integration_accounts", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "provider", null: false
    t.text "access_token"
    t.text "refresh_token"
    t.datetime "expires_at"
    t.jsonb "metadata", default: {}, null: false
    t.string "status", default: "expired", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id", "provider"], name: "index_integration_accounts_on_user_id_and_provider", unique: true
    t.index ["user_id"], name: "index_integration_accounts_on_user_id"
    t.check_constraint "provider::text = ANY (ARRAY['gmail'::character varying, 'jira'::character varying, 'github'::character varying, 'google_calendar'::character varying]::text[])", name: "integration_accounts_provider_check"
  end

  create_table "jira_tickets", force: :cascade do |t|
    t.bigint "integration_account_id", null: false
    t.string "external_id", null: false
    t.string "title", null: false
    t.text "body"
    t.jsonb "metadata", default: {}, null: false
    t.datetime "occurred_at"
    t.datetime "last_synced_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["integration_account_id", "external_id"], name: "index_jira_tickets_on_account_and_external_id", unique: true
    t.index ["integration_account_id"], name: "index_jira_tickets_on_integration_account_id"
    t.index ["last_synced_at"], name: "index_jira_tickets_on_last_synced_at"
    t.index ["occurred_at"], name: "index_jira_tickets_on_occurred_at"
  end

  create_table "ticket_automation_runs", force: :cascade do |t|
    t.bigint "jira_ticket_id", null: false
    t.string "status", default: "pending_approval", null: false
    t.string "branch_name", null: false
    t.string "base_branch", default: "main", null: false
    t.string "repository_path", null: false
    t.string "worktree_path"
    t.string "codex_thread_id"
    t.text "codex_output"
    t.text "error_message"
    t.jsonb "command_log", default: [], null: false
    t.string "commit_sha"
    t.datetime "approved_at"
    t.datetime "started_at"
    t.datetime "completed_at"
    t.datetime "published_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["branch_name"], name: "index_ticket_automation_runs_on_branch_name"
    t.index ["jira_ticket_id"], name: "index_ticket_automation_runs_on_jira_ticket_id"
    t.index ["status"], name: "index_ticket_automation_runs_on_status"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", null: false
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  add_foreign_key "ai_summaries", "commands"
  add_foreign_key "commands", "users"
  add_foreign_key "context_items", "commands"
  add_foreign_key "integration_accounts", "users"
  add_foreign_key "jira_tickets", "integration_accounts"
  add_foreign_key "ticket_automation_runs", "jira_tickets"
end
