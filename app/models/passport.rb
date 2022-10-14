class Passport < ApplicationRecord
  has_and_belongs_to_many :kvests
  has_and_belongs_to_many :titles
end