class QuotesController < ApplicationController
  def index
    @quote = Quote.new
    @project = Project.find(params[:project_id])
    @quotes = Quote.where(project: @project).order(created_at: :desc)

    breadcrumbs.add "Admin view: #{@project.name}", project_details_path(@project)

  end

  def new
    @project = Project.find(params[:project_id])
    @quote = Quote.new
  end

  def create
    @quote = Quote.new(quote_params)
    @project = Project.find(params[:project_id])
    @quote.project = @project

    respond_to do |format|
      if @quote.save
        format.html { redirect_to project_quotes_path(@project), notice: "Quote created successfully." }
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            'quote-modal',
            partial: 'quotes/form',
            locals: { quote: @quote, project: @project }
          )
        end
      else
        format.html { render :new }
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            'quote-modal',
            partial: 'quotes/form',
            locals: { quote: @quote, project: @project }
          )
        end
      end
    end
  end

  def edit
    @project = Project.find(params[:project_id])
    @quote = Quote.find(params[:id])
  end

  def update
    @project = Project.find(params[:project_id])
    @quote = Quote.find(params[:id])

    if @quote.update(quote_params)
      redirect_to project_quotes_path(@project), notice: "Quote updated successfully."
    else
      render :edit
    end
  end

  private

  def quote_params
    params.require(:quote).permit(:number, :date, :value, :recipient, :responsible, :status, :link, :currency, :project_id)
  end
end
