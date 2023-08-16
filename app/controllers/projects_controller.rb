class ProjectsController < ApplicationController
  def index
    breadcrumbs.add "Projects", projects_path
    @projects = Project
      .left_joins(:tasks)
      .select("projects.*, COUNT(tasks.id) AS tasks_count")
      .group("projects.id")
      .order("COUNT(tasks.id) DESC")

    if params[:project_lead].present?
      project_lead = Assignee.find_by(name: params[:project_lead])
      if project_lead.present?
        @projects = @projects.where(lead: project_lead.name)
      else
        @projects = @projects.where(lead: params[:project_lead])
      end
    end

    if params[:search_term].present?
      search_term = params[:search_term].strip.downcase  # Convert search term to lowercase
      @projects = @projects.where("LOWER(projects.name) LIKE ? OR LOWER(projects.jira_id) LIKE ?", "%#{search_term}%", "%#{search_term}%")
    end

    @projects = @projects.page(params[:page])
    @projects_count = @projects.total_count

    render :index
  end

  def new
    @project = Project.new
  end

  def create
    @project = Project.new(project_params)
    if @project.save
      redirect_to projects_path
    else
      render :new
    end
  end

  def show
    breadcrumbs.add "Projects", projects_path
    @project = Project.find(params[:id])

    @total_time_estimation = 0
    @total_time_spent = 0

    @all_project_tasks = Task.where(project: @project).order(last_jira_update: :desc)
    @project_tasks = @all_project_tasks

    projects_unique_assignees_list
    projects_unique_statuses_list
    @tasks_by_time_status = tasks_by_time_status

    filter_tasks_by_assignee if params[:assignee].present?
    filter_tasks_by_search_term if params[:search_term].present?

    calculate_total_time_metrics(@all_project_tasks)

    @project_tasks = @project_tasks.page(params[:page])
    render :show
  end

  def project_details
    @project = Project.find(params[:id])
    breadcrumbs.add "Prod view: #{@project.name}", project_path(@project)

    @projects_assignees = Assignee.joins(tasks: :project)
      .select("assignees.*, SUM(tasks.time_spent) AS total_time_spent")
      .where(tasks: { project_id: @project.id })
      .group("assignees.id")

    @project_total_internal_cost = Task.joins(:assignee)
      .where(project: @project)
      .sum("tasks.time_spent * (assignees.hourly_rate / 3600)")

    @revenue_from_project = @project.total_selling_price - @project_total_internal_cost
  end

  def edit
    @project = Project.find(params[:id])
  end

  def update
    @project = Project.find(params[:id])

    if @project.update(project_params)
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            "selling_price",
            partial: "projects/edit",
            locals: { project: @project },
          )
        end
        format.html { redirect_to project_details_path(@project) }
      end
    else
      render :edit
    end
  end

  def update_project_status
    project = Project.find(params[:id])
    if project.archived_status == false
      project.update!(archived_status: true)
    else
      project.update!(archived_status: false)
    end

    redirect_to project_details_path(project)
  end

  def generate_pdf_report
    pdf = Prawn::Document.new
    project = Project.find(params[:id])

    assignee_names = projects_unique_assignees_list
    assignees_count = assignee_names.length
    cost_per_assignee = assignees_count > 0 ? project.total_internal_cost / assignees_count : 0

    project_total_internal_cost = Task.joins(:assignee)
      .where(project: project)
      .sum("tasks.time_spent * (assignees.hourly_rate / 3600)")

    pdf.text "Project Financial Data: #{project.name}"
    pdf.text "Project Lead: #{project.lead}"
    pdf.text "Total tasks: #{project.tasks.count}"
    pdf.text "\n"
    pdf.text "Internal Cost: #{project_total_internal_cost} TND"
    pdf.text "Selling Price: #{project.total_selling_price} TND"
    pdf.text "Cost per Assignee: #{number_with_precision((cost_per_assignee), precision: 2)} TND"
    pdf.text "\n"
    pdf.text "Assignees count: #{assignee_names.count}"
    pdf.text "Assignees: \n#{assignee_names.join("\n")}"

    send_data pdf.render, filename: "report.pdf", type: "application/pdf", disposition: "attachment"
  end

  private

  def project_params
    params.require(:project).permit(:name, :jira_id, :archived_status, :lead, :total_internal_cost, :total_selling_price)
  end

  def get_projects_data_with_pagination(startat)
    url = "https://agenceinspire.atlassian.net/rest/api/3/project/search?startAt=#{startat}&maxResults=50&expand=lead"
    response = call_jira_api(url)
    return unless response.code == "200"

    json_projects = JSON.parse(response.body)
    collect_projects_information(json_projects)
  end

  def collect_projects_information(json_projects)
    i = 0
    json = json_projects["values"]
    while i < json.length
      project_name = json[i]["name"]
      project_jira_id = json[i]["key"]
      project_lead = json[i]["lead"]["displayName"]
      find_or_create_project(project_name, project_jira_id, project_lead)
      i += 1
    end
  end

  def find_or_create_project(project_name, project_jira_id, project_lead)
    Project.find_or_create_by(name: project_name) do |project|
      project.jira_id = project_jira_id
      project.lead = project_lead
    end
  end

  def projects_unique_assignees_list
    # Load the project by ID
    project = Project.find(params[:id])

    # Load all the unique assignees for the project's tasks
    assignee_names = project.tasks.select(:assignee_id).distinct.joins(:assignee).pluck("assignees.name")

    # Extract the full names from the array of names
    @projects_unique_assignees = assignee_names.map { |name| name.split(" ").map(&:capitalize).join(" ") }

    @assignee_task_counts = {}
    project.tasks.group(:assignee_id).count.each do |assignee_id, task_count|
      @assignee_task_counts[Assignee.find(assignee_id).name] = task_count
    end

    @assignee_task_percentages = {}
    total_tasks = project.tasks.count
    @assignee_task_counts.each do |assignee, task_count|
      @assignee_task_percentages[assignee] = (task_count.to_f / total_tasks * 100).round(2)
    end

    @assignee_time_spent = {}
    project.tasks.joins(:assignee).group("assignees.name").sum(:time_spent).each do |assignee_name, time_spent|
      @assignee_time_spent[assignee_name] = time_spent
    end

    # Sort the unique assignees by the number of tasks in descending order
    @projects_unique_assignees.sort_by! { |assignee| -@assignee_task_counts[assignee] }
  end

  def projects_unique_statuses_list
    # Load the project by ID
    project = Project.find(params[:id])

    # Load all the unique statuses for the project's tasks
    status_names = project.tasks.select(:status).distinct.pluck(:status)

    # Extract the full names from the array of names
    @projects_unique_statuses = status_names.map(&:capitalize)

    # Get the count and percentage of tasks for each status
    @status_task_counts = {}
    total_tasks = @project.tasks.count
    project.tasks.group(:status).count.each do |status, task_count|
      @status_task_counts[status.capitalize] = task_count
    end

    @status_task_percentages = {}
    @status_task_counts.each do |status, task_count|
      @status_task_percentages[status] = (task_count.to_f / total_tasks * 100).round(2)
    end

    # Sort the unique statuses by the number of tasks in descending order
    @projects_unique_statuses.sort_by! { |status| -@status_task_counts[status] }
  end

  def tasks_by_time_status
    project = Project.find(params[:id])
    total_tasks = project.tasks.count
    in_time_tasks = project.tasks.where("time_spent = time_forecast").count
    early_tasks = project.tasks.where("time_spent < time_forecast").count
    delayed_tasks = project.tasks.where("time_spent > time_forecast").count
    no_data_tasks = project.tasks.where("time_forecast IS NULL OR time_spent IS NULL").count

    in_time_percentage = (in_time_tasks.to_f / total_tasks.to_f * 100).round(2)
    early_percentage = (early_tasks.to_f / total_tasks.to_f * 100).round(2)
    delayed_percentage = (delayed_tasks.to_f / total_tasks.to_f * 100).round(2)
    no_data_percentage = (no_data_tasks.to_f / total_tasks.to_f * 100).round(2)

    { in_time: { count: in_time_tasks, percentage: in_time_percentage },
      early: { count: early_tasks, percentage: early_percentage },
      delayed: { count: delayed_tasks, percentage: delayed_percentage },
      no_data: { count: no_data_tasks, percentage: no_data_percentage } }
  end

  def calculate_total_time_metrics(tasks)
    tasks.each do |task|
      @total_time_estimation += task.time_forecast || 0
      @total_time_spent += task.time_spent || 0
    end
    @time_difference = @total_time_estimation - @total_time_spent
  end

  def filter_tasks_by_assignee
    assignee_filter = Assignee.find_by(name: params[:assignee])
    @project_tasks = @project_tasks.where(assignee: assignee_filter).order(last_jira_update: :desc)
  end

  def filter_tasks_by_search_term
    search_term = params[:search_term].strip.downcase
    @project_tasks = @project_tasks.where("LOWER(tasks.status) LIKE ? OR LOWER(tasks.summary) LIKE ?", "%#{search_term}%", "%#{search_term}%")
  end
end
