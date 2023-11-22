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
      Time.current
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
    @passed_vacations = Vacation.where("end_date < ?", Date.today).order(start_date: :desc)
  end

  def flagged_tasks
    breadcrumbs.add "Flagged Tasks", flagged_tasks_path
    @tasks = Task.where(flagged: true)
      .where("status = ? OR status = ? OR status = ?", "In Progress", "Done", "Réalisé")
      .where("last_jira_update >= ?", 1.month.ago)
  end

  def start_slack_message_job
    FlaggedTasksSlackMessageJob.set(queue: :critical).perform_async(params[:task_id])
    redirect_to flagged_tasks_path, notice: "Slack message sent!"
  end

  def start_jira_issue_comment_job
    FlaggedTasksJiraIssueCommentJob.set(queue: :critical).perform_async(params[:task_id])
    redirect_to flagged_tasks_path, notice: "Jira comment sent!"
  end

  def generate_assignees_report
    assignees = Assignee.where("hourly_rate > 0")
    pdf = Prawn::Document.new(page_size: [1200, 700]) # Set the page size to a custom width and height

    data = [
      [
        "Ressource",
        "Salaire Brut",
        "Jours travaillés sur 200 jours",
        "% de remplissage sur 200 jours",
        "Coût total selon JIRA sur 200 jours",
        "Revenue total par la ressource sur 200 jours",
      ],
    ]

    assignees.each do |assignee|
      total_time_worked = assignee_total_time_worked(assignee, 2023)

      data << [
        assignee.name,
        assignee.salary,
        convert_seconds_to_real_days(total_time_worked),
        percentage_fill_200_days(total_time_worked),
        calculate_cost(assignee, total_time_worked),
        calculate_revenue_share(assignee),
      ]
    end

    pdf.table(data, cell_style: { size: 10, padding: 5 }, column_widths: [100, 70, 70, 70, 250, 250]) do
      row(0).font_style = :bold
      self.header = true
      self.row_colors = ["DDDDDD", "FFFFFF"]
    end

    send_data pdf.render, filename: "Tableau_Rapport_Ressource_par_projets_pour_2023.pdf", type: "application/pdf", disposition: "attachment"
  end

  def assignee_total_time_worked(assignee, year)
    assignee.tasks
            .where("tasks.created_at >= ? AND tasks.created_at <= ?", Date.new(year, 1, 1), Date.new(year, 12, 31))
            .sum(:time_spent)
  end

  def convert_seconds_to_real_days(seconds)
    hours_per_day = 7
    seconds_in_a_day = 24 * 60 * 60

    days = seconds.to_f / (hours_per_day * 60 * 60)

    if days >= 1
      days_str = format("%.1f days", days)
    else
      days_str = format("%.1f hours", days * hours_per_day)
    end

    days_str
  end

  def percentage_fill_200_days(total_time_worked)
    percentage = (total_time_worked / (200 * 7 * 60 * 60)) * 100
    percentage_str = "#{percentage.round(2)} %"
  end

  def calculate_cost(assignee, seconds)
    hours_worked = seconds / (60 * 60)
    total_cost = hours_worked * assignee.hourly_rate

    project_costs = []

    projects = Project.joins(:tasks)
      .where(tasks: { assignee_id: assignee.id })
      .distinct

    projects.each do |project|
      project_total_time_spent = project.tasks.sum(:time_spent)
      assignee_time_spent = project.tasks
        .where(assignee_id: assignee.id)
        .where("tasks.created_at >= ? AND tasks.created_at <= ?", Date.new(2023, 1, 1), Date.new(2023, 12, 31))
        .sum(:time_spent)
      project_cost = (assignee_time_spent / (60 * 60)) * assignee.hourly_rate
      next if project_cost == 0  # Skip projects with a cost of 0
      project_costs << "#{project.name}: #{project_cost.round(2)} TND | #{(assignee_time_spent * 100 / project_total_time_spent).round(2)} %"
    end

    total_cost_string = "Total Cost: #{total_cost.round(2)} TND"
    formatted_project_costs = project_costs.join("\n")

    "#{total_cost_string}\n#{formatted_project_costs}\n"
  end

  def calculate_revenue_share(assignee)
    total_revenue = 0
    project_revenues = []

    projects = Project.joins(:tasks)
      .where(tasks: { assignee_id: assignee.id })
      .where("projects.total_selling_price > 0")
      .distinct

    projects.each do |project|
      total_time_spent = project.tasks.sum(:time_spent)
      assignee_time_spent = project.tasks.where(assignee_id: assignee.id).sum(:time_spent)

      if total_time_spent > 0
        ratio = assignee_time_spent.to_f / total_time_spent
        revenue_share = project.total_selling_price * ratio
        total_revenue += revenue_share.round(2)
        project_revenues << "#{project.name}: #{revenue_share.round(2)} TND | #{(ratio * 100).round(2)} %"
      end
    end

    formatted_project_revenues = project_revenues.join("\n")
    total_revenue_string = "Total: #{total_revenue} TND"

    "#{total_revenue_string}\n#{formatted_project_revenues}"
  end

  def daily_reports
    @assignees = Assignee.all # Adjust as needed
    @active_assignees = Assignee.where(active: true) # Adjust as needed

    if params[:selected_date].present?
      begin
        @date_today = Date.parse(params[:selected_date].to_s)
      rescue ArgumentError
        @date_today = Date.today
      end
    else
      @date_today = Date.today
    end

    respond_to do |format|
      format.html
    end
  end
end
