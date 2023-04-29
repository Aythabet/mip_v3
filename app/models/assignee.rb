class Assignee < ApplicationRecord
  has_many :tasks
  has_many :vacations

  validates :name, uniqueness: true
  validates :email, uniqueness: true
  validate :vacation_days_non_negative

  paginates_per 20

  after_create :calculate_vacation_days_available

  private

  def vacation_days_non_negative
    if vacation_days_available.negative?
      errors.add(:vacation_days_available, "You can't have vacation debts!")
    end
  end

  def calculate_vacation_days_available
    start_month = self.created_at.month
    start_year = self.created_at.year
    current_month = Date.today.month
    current_year = Date.today.year

    if current_month >= start_month && current_year >= start_year
      years_of_service = current_year - start_year
      months_of_service = current_month - start_month + years_of_service * 12
      total_days = months_of_service * 2

      if current_month == 12 && self.vacation_days_available > 7
        self.vacation_days_available = 7
      else
        self.vacation_days_available = total_days
      end

      self.save
    end
  end
end
