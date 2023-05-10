class User < ApplicationRecord
  belongs_to :passport, optional: true
end