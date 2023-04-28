class QuotesController < ApplicationController
  def index
    @quote = Quote.new
    @project = Project.find(params[:project_id])
    @quotes = Quote.where(project_id: @project)
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
            'quote',
            partial: 'quotes/form',
            locals: { quote: @quote, project: @project }
          )
        end
      else
        format.turbo_stream do
          render turbo_stream: turbo_stream.append(
            'quote-errors',
            partial: 'quotes/form',
            locals: { quote: @quote, project: @project }
          )
        end
      end
    end
  end


  private

  def quote_params
    params.require(:quote).permit(:number, :date, :value, :recipient, :responsible, :status)
  end
end
