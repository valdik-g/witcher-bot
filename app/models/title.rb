class Title < ApplicationRecord
  has_and_belongs_to_many :passports
end