class Passport < ApplicationRecord
  has_and_belongs_to_many :kvests
  has_and_belongs_to_many :titles
  has_one :user
  has_one :user_prerecording, inverse_of: 'passport' 
end