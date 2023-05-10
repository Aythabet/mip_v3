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

ActiveRecord::Schema[7.0].define(version: 2023_05_10_210445) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "assignees", force: :cascade do |t|
    t.string "name"
    t.string "email"
    t.boolean "admin"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.float "salary"
    t.float "hourly_rate"
    t.float "vacation_days_available"
    t.boolean "on_vacation"
  end

  create_table "jobs_logs", force: :cascade do |t|
    t.string "title"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.float "execution_time"
  end

  create_table "projects", force: :cascade do |t|
    t.string "name"
    t.string "jira_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "lead"
    t.boolean "archived_status", default: false
    t.decimal "total_internal_cost", precision: 10, scale: 2, default: "0.0"
    t.decimal "total_selling_price", precision: 10, scale: 2, default: "0.0"
  end

  create_table "quotes", force: :cascade do |t|
    t.string "number"
    t.date "date"
    t.float "value"
    t.string "recipient"
    t.string "responsible"
    t.string "status"
    t.bigint "project_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "link"
    t.string "currency"
    t.index ["project_id"], name: "index_quotes_on_project_id"
  end

  create_table "task_changelogs", force: :cascade do |t|
    t.string "changelog_id"
    t.string "author"
    t.string "field"
    t.string "from_value"
    t.string "to_value"
    t.datetime "timestamp"
    t.bigint "task_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "sentence"
    t.index ["task_id"], name: "index_task_changelogs_on_task_id"
  end

  create_table "task_worklogs", force: :cascade do |t|
    t.string "author"
    t.string "duration"
    t.datetime "created"
    t.datetime "updated"
    t.datetime "started"
    t.string "status"
    t.bigint "task_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "worklog_entry_id"
    t.string "sentence"
    t.index ["task_id"], name: "index_task_worklogs_on_task_id"
  end

  create_table "tasks", force: :cascade do |t|
    t.string "jira_id"
    t.string "status"
    t.bigint "project_id", null: false
    t.bigint "assignee_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "summary"
    t.float "time_spent", default: 0.0
    t.float "time_forecast", default: 0.0
    t.string "priority"
    t.string "epic"
    t.string "labels"
    t.datetime "last_jira_update"
    t.date "due_date"
    t.datetime "status_change_date"
    t.string "task_type"
    t.string "is_task_subtask"
    t.index ["assignee_id"], name: "index_tasks_on_assignee_id"
    t.index ["project_id"], name: "index_tasks_on_project_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "provider"
    t.string "uid"
    t.string "name"
    t.string "avatar_url"
    t.boolean "admin"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  create_table "vacations", force: :cascade do |t|
    t.date "start_date"
    t.date "end_date"
    t.float "duration"
    t.bigint "assignee_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "reason"
    t.index ["assignee_id"], name: "index_vacations_on_assignee_id"
  end

  add_foreign_key "quotes", "projects"
  add_foreign_key "task_changelogs", "tasks", on_delete: :cascade
  add_foreign_key "task_worklogs", "tasks", on_delete: :cascade
  add_foreign_key "tasks", "assignees"
  add_foreign_key "tasks", "projects"
  add_foreign_key "vacations", "assignees"
end
