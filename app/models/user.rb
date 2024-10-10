class User < ApplicationRecord
  belongs_to :passport, optional: true

  scope :admins, -> { where(admin: true) }
end