class Document < ApplicationRecord
  has_one_attached :file

  validates :uuid, presence: true, uniqueness: true
  validates :expires_at, presence: true

  scope :expired, -> { where("expires_at < ?", Time.current) }
end
