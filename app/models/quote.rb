class Quote < ApplicationRecord
  belongs_to :project

  validates :number, presence: true, uniqueness: true
  validates :date, presence: true
  validates :value, presence: true, numericality: { greater_than: 0 }
  validates :recipient, presence: true
  validates :status, presence: true, inclusion: { in: %w(Waiting Accepted Declined) }
end
