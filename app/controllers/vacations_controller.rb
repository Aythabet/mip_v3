class VacationsController < ApplicationController
  def index
    @vacation = Vacation.new
    @assignee = Assignee.find(params[:assignee_id])
    @vacations = Vacation.where(assignee_id: @assignee).order(created_at: :desc)
  end

  def new
    @assignee = Assignee.find(params[:assignee_id])
    @vacation = Vacation.new
  end

  def create
    @vacation = Vacation.new(vacation_params)
    @assignee = Assignee.find(params[:assignee_id])
    @vacation.assignee = @assignee

    if check_vacation_request(@assignee, @vacation.duration)
      set_vacation_end_date(@vacation)
      if @vacation.save
        @assignee.update(vacation_days_available: (@assignee.vacation_days_available - @vacation.duration))
        respond_to do |format|
          format.html { redirect_to assignee_vacations_path(@assignee), notice: "Quote created successfully." }
          format.turbo_stream do
            render turbo_stream: turbo_stream.replace(
              'vacation-modal',
              partial: 'vacations/form',
              locals: { vacation: @vacation, assignee: @assignee }
            )
          end
        end
      else
        respond_to do |format|
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
    else
      flash[:alert] = "The assignee does not have enough vacation days available."
      redirect_to assignee_vacations_path(@assignee)
    end
  end

  def edit
  end

  def show
  end

  def update
  end

  def destroy
    @assignee = Assignee.find(params[:assignee_id])
    @vacation = @assignee.vacations.find(params[:id])
    @assignee.update(vacation_days_available: (@assignee.vacation_days_available + @vacation.duration))
    @vacation.destroy!
    redirect_to assignee_vacations_path(@assignee)
  end

  private

  def vacation_params
    params.require(:vacation).permit(:start_date, :end_date, :duration, :reason)
  end

  def check_vacation_request(assignee, duration)
    return assignee.vacation_days_available >= duration
  end

  def set_vacation_end_date(vacation)
    @vacation.end_date = @vacation.start_date
    days_left = @vacation.duration - 1 # Exclude the start date

    while days_left > 0
      @vacation.end_date += 1.day
      if @vacation.end_date.on_weekend? # Skip weekends
        next
      else
        days_left -= 1 # Decrease the remaining duration
      end
    end
  end
end
