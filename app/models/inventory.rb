class Inventory < ApplicationRecord
  has_many :passports_inventories
  has_many :passports, through: :passports_inventories
end