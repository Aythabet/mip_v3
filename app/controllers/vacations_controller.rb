class VacationsController < ApplicationController
  def index
    @vacation = Vacation.new
    @assignee = Assignee.find(params[:assignee_id])
    @vacations = Vacation.where(assignee_id: @assignee)
  end

  def new
    @assignee = Assignee.find(params[:assignee_id])
    @vacation = Vacation.new
  end

  def create
    @vacation = Vacation.new(vacation_params)
    @assignee = Assignee.find(params[:assignee_id])
    @vacation.assignee = @assignee

    respond_to do |format|
      if @vacation.save
        format.html { redirect_to assignee_vacations_path(@assignee), notice: "Quote created successfully." }
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            'vacation-modal',
            partial: 'vacations/form',
            locals: { vacation: @vacation, assignee: @assignee }
          )
        end
      else
        format.html { render :new }
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            'vacation-modal',
            partial: 'vacations/form',
            locals: { vacation: @vacation, assignee: @assignee }
          )
        end
      end
    end
  end

  private

  def vacation_params
    params.require(:vacation).permit(:start_date, :end_date, :duration)
  end
end
