class PassportsInventory < ApplicationRecord
  belongs_to :passport
  belongs_to :inventory

  after_update do |passport_inventory|
    passport_inventory.delete if passport_inventory.quantity == 0
  end
end