class AdminController < ApplicationController
  before_action :check_admin

  def index
  end

  def db_task_cleaner
    DbTaskCleanerJob.set(queue: :critical).perform_async

    flash.notice = "Checking tasks... this will take a minute!"
    redirect_to admin_index_path
  end

  def retrieve_tasks
    TasksJob.set(queue: :critical).perform_async

    flash.notice = "The import started, come back in few minutes!"
    redirect_to admin_index_path
  end

  def destroy_all
    DestroyTasksJob.set(queue: :critical).perform_async

    flash.notice = "All the tasks will be deleted."
    redirect_to tasks_path
  end

  def sidekiq_logs
  end

  def all_vacations
    breadcrumbs.add "Vacations", all_vacations_path

    @active_vacations = Vacation.where(
      "start_date <= ? AND ? <= (start_date + interval '1 day' * ((duration - 0.5) * 2))",
      Date.today,
      Date.today
    )
    @upcoming_vacations = Vacation.where(
      "start_date >= ? AND ? <= (start_date + interval '1 day' * ((duration - 0.5) * 2))",
      Date.today,
      Date.today
    ).where.not(
      "start_date <= ? AND ? <= (start_date + interval '1 day' * ((duration - 0.5) * 2))",
      Date.today,
      Date.today
    )
  end

  def tests
    breadcrumbs.add "Tests", tests_path
    @tasks = Task.where(flagged: true)
      .where("status = ? OR status = ? OR status = ?", "In Progress", "Done", "Réalisé")
      .where("last_jira_update >= ?", 1.month.ago)
  end

  def start_slack_message_job
    FlaggedTasksSlackMessageJob.set(queue: :critical).perform_async(params[:task_id])
    redirect_to tests_path, notice: "Slack message sent!"
  end

  def start_jira_issue_comment_job
    FlaggedTasksJiraIssueCommentJob.set(queue: :critical).perform_async(params[:task_id])
    redirect_to tests_path, notice: "Jira comment sent!"
  end
end
