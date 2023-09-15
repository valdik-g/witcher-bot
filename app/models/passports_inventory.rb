class PassportsInventory < ApplicationRecord
  belongs_to :passport
  belongs_to :inventory
end