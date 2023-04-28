class QuotesController < ApplicationController
  def create
    @project = Project.find(params[:project_id])
    @quote = @project.quotes.create(quote_params)
    redirect_to project_details_path(@project)
  end

  private

  def quote_params
    params.require(:quote).permit(:number, :date, :value, :recipient, :responsible, :status)
  end
end
