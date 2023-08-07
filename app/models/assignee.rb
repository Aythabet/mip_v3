class Assignee < ApplicationRecord
  has_many :tasks
  has_many :vacations

  after_initialize :set_assignee_vacation_days

  validates :name, uniqueness: true
  validates :email, uniqueness: true

  paginates_per 50

  validate :vacation_days_non_negative

  private

  def set_assignee_vacation_days
    if self.vacation_days_available.nil? || vacation_days_available.negative?
      self.vacation_days_available = 0
    end
  end

  def vacation_days_non_negative
    if vacation_days_available.negative? || vacation_days_available.nil?
      errors.add(:vacation_days_available, "You can't have vacation debts!")
    end
  end
end
