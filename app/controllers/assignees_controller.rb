class AssigneesController < ApplicationController
  def index
    breadcrumbs.add "Assignees", assignees_path
    @assignees = Assignee
      .select("assignees.*, MAX(tasks.last_jira_update)")
      .joins("LEFT JOIN tasks ON tasks.assignee_id = assignees.id")
      .group("assignees.id")
      .order("MAX(tasks.last_jira_update) DESC")
      .page(params[:page])

    @assignees_count = Assignee.count
  end

  def retrieve_assignees
    url = "https://agenceinspire.atlassian.net/rest/api/3/user/search?query=+&maxResults=1000"
    response = call_jira_api(url)
    return unless response.code == "200"

    json_assignee = JSON.parse(response.body)
    json_assignee.each do |assignee|
      assignee_name = assignee["displayName"]
      assignee_email = assignee["emailAddress"]
      find_or_create_assignee(assignee_name, assignee_email)
    end

    redirect_to assignees_path
  end

  def send_data_to_assignee
    assignee = Assignee.find(params[:id])
    ReportMailer.send_data_to_user(assignee).deliver_now
    redirect_to assignee_path, notice: "Data sent to assignee"
  end

  def edit
    @assignee = Assignee.find(params[:id])
    breadcrumbs.add "Admin view: #{@assignee.name}", assignee_profile_path(@assignee)
  end

  def update
    @assignee = Assignee.find(params[:id])
    if @assignee.update(assignee_params)
      redirect_to request.referrer || assignee_profile_path(@assignee), notice: "Assignee was updated."
    else
      render :edit
    end
  end

  def show
    @assignee = Assignee.find(params[:id])
    breadcrumbs.add "Prod view: #{@assignee.name}", assignees_path(@assignee)
    @assignee_tasks = Task.where(assignee: @assignee).order(last_jira_update: :desc)
    generate_cr(Date.today)
    assignee_unique_projects_list
    @tasks_by_time_status = tasks_by_time_status
    @assignee_tasks_paginated = Task.where(assignee: @assignee).order(last_jira_update: :desc).page(params[:page])
    calculate_time_statistics
    calculate_task_ratio_sum
    @assignee_ratio = calculate_assignee_ratio
  end

  def assignee_profile
    @assignee = Assignee.find(params[:id])
    breadcrumbs.add "Admin view: #{@assignee.name}", assignee_profile_path(@assignee)
    @assignees_projects = Project.joins(:tasks).where(tasks: { assignee_id: @assignee.id })
      .select("projects.*, SUM(tasks.time_spent) AS total_time_spent")
      .group("projects.id")
  end

  def generate_pdf_report
    pdf = Prawn::Document.new
    assignee = Assignee.find(params[:id])

    pdf.font("Helvetica", size: 18)
    pdf.text "<b>#{assignee.name}</b> - <font size='14'> Brut: #{assignee.salary} TND - Hourly Cost: #{assignee.hourly_rate} TND </font>", :inline_format => true

    pdf.font("Helvetica", size: 12, style: :bold)
    # Calculate total tasks, time estimated, and time spent in 2023
    total_tasks = assignee.tasks.count
    total_tasks_2023 = assignee.tasks.where("extract(year from created_at) = ?", 2023).count
    total_time_estimated = assignee.tasks.where("extract(year from created_at) = ?", 2023).sum(:time_forecast)
    total_time_spent = assignee.tasks.where("extract(year from created_at) = ?", 2023).sum(:time_spent)

    pdf.text "Total tasks: #{total_tasks}"
    pdf.text "Total tasks in 2023: #{total_tasks_2023}"
    pdf.text "Total time estimated on JIRA in 2023: #{format_duration(total_time_estimated)}"
    pdf.text "Total time logged on JIRA in 2023: #{format_duration(total_time_spent)} - <font size='12'> #{(assignee.hourly_rate.to_f * (total_time_spent.to_f / 3600.0).round(2)).round(2)} TND </font>", :inline_format => true

    pdf.font("Helvetica", size: 10, style: :normal)
    pdf.text "\n"

    tasks_per_project = list_of_assignee_tasks_per_project(assignee)
    tasks_per_project.each do |project|
      project_cost_2023 = project_cost_2023(project.name)
      time_spent = stats_of_unique_project_by_assignee(project, assignee, 2023)
      assignee_project_cost = (assignee.hourly_rate.to_f * (time_spent.to_f / 3600.0).round(2)).round(2)

      pdf.text "\n#{project.name}\n Cost in 2023: <b>#{project_cost_2023} TND</b>", :inline_format => true
      pdf.text "#{assignee.name} logged <b>#{format_duration(time_spent)}</b> on JIRA", :inline_format => true
      pdf.text "Individual cost <font size='10'> <b>#{assignee_project_cost} TND </b></font> - That's #{(assignee_project_cost.to_f / project_cost_2023.to_f * 100).round(2)} % from total", :inline_format => true
    end

    pdf.move_down(10) # Add space between sections

    send_data pdf.render, filename: "Report #{assignee.name}.pdf", type: "application/pdf", disposition: "attachment"
  end

  private

  def project_cost_2023(project_name)
    project = Project.where(name: project_name).first
    total_time_spent_2023 = project.tasks.where("extract(year from created_at) = ?", 2023).sum(:time_spent)
    (total_time_spent_2023.to_f / 3600.0.round(2) * 25).round(2)
  end

  def list_of_assignee_tasks_per_project(assignee)
    assignee.tasks.joins(:project).select("distinct projects.*")
  end

  def stats_of_unique_project_by_assignee(project, assignee, year)
    tasks = assignee.tasks.where(project: project).where("extract(year from created_at) = ?", year)
    tasks.sum(:time_spent)
  end

  def assignee_params
    params.require(:assignee).permit(:name, :email, :admin, :salary, :hourly_rate, :vacation_days_available, :on_vacation)
  end

  def find_or_create_assignee(assignee_name, assignee_email, admin: false)
    assignee_name = format_name(assignee_name)
    assignee_email = assignee_email.present? ? assignee_email : format_email(assignee_name)
    Assignee.create(email: assignee_email) do |user|
      user.name = assignee_name
      user.admin = admin
    end
  end

  def generate_cr(day)
    @assignee_todays_tasks = Task.where(assignee: @assignee)
      .where("DATE(last_jira_update) = ? OR DATE(created_at) = ?", day, day)
      .order(last_jira_update: :desc)

    @assignee_yesterday_tasks = Task.where(assignee: @assignee)
      .where("DATE(last_jira_update) = ? OR DATE(created_at) = ?", day - 1, day - 1)
      .order(last_jira_update: :desc)
  end

  def assignee_unique_projects_list
    # Load the assignee by ID
    @assignee = Assignee.find(params[:id])

    # Load all the unique projects for the assignee's tasks
    @project_task_counts = @assignee.tasks.group(:project_id).count
    @projects_jira_ids = []
    @project_task_counts.each do |project_id, task_count|
      project = Project.find(project_id)
      @projects_jira_ids << { project_id: project_id, jira_id: project.jira_id }
    end

    # Calculate task percentages for each project
    @project_task_percentages = {}
    total_tasks = @assignee.tasks.count
    @project_task_counts.each do |project_id, task_count|
      project = Project.find(project_id)
      @project_task_percentages[project.jira_id] = (task_count.to_f / total_tasks * 100).round(2)
    end

    # Sort the projects by the number of tasks in descending order
    @projects_jira_ids.sort_by! { |project| -@project_task_counts[project[:project_id]] }
  end

  def tasks_by_time_status
    assignee = Assignee.find(params[:id])
    total_tasks = assignee.tasks.count
    in_time_tasks = assignee.tasks.where("time_spent = time_forecast").count
    early_tasks = assignee.tasks.where("time_spent < time_forecast").count
    delayed_tasks = assignee.tasks.where("time_spent > time_forecast").count
    no_data_tasks = assignee.tasks.where("time_forecast IS NULL OR time_spent IS NULL").count

    in_time_percentage = (in_time_tasks.to_f / total_tasks.to_f * 100).round(2)
    early_percentage = (early_tasks.to_f / total_tasks.to_f * 100).round(2)
    delayed_percentage = (delayed_tasks.to_f / total_tasks.to_f * 100).round(2)
    no_data_percentage = (no_data_tasks.to_f / total_tasks.to_f * 100).round(2)

    { in_time: { count: in_time_tasks, percentage: in_time_percentage },
      early: { count: early_tasks, percentage: early_percentage },
      delayed: { count: delayed_tasks, percentage: delayed_percentage },
      no_data: { count: no_data_tasks, percentage: no_data_percentage } }
  end

  def calculate_time_statistics
    @total_time_estimation = @assignee_tasks.sum(:time_forecast) || 0
    @total_time_spent = @assignee_tasks.sum(:time_spent) || 0
    @time_difference = @total_time_estimation - @total_time_spent
  end

  def calculate_task_ratio_sum
    @task_ratio_sum = @assignee_tasks.sum { |task| calculate_task_ratio(task) }
  end

  def calculate_assignee_ratio
    (@task_ratio_sum.fdiv(@assignee_tasks.count || 0) * 100).round(2)
  end

  def calculate_task_ratio(task)
    if task.time_forecast && task.time_spent
      task_time_gap = task.time_forecast - task.time_spent
      accepted_gap_ratio = task_time_gap / task.time_forecast
      if accepted_gap_ratio < 0.17
        return 1
      end
    end
    return 0
  end
end
