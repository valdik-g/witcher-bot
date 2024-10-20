class UserPrerecording < ApplicationRecord
  belongs_to :passport

  scope :voted -> { where(voted: true) }
end