class User < ApplicationRecord
    belongs_to :passport, class_name: 'Passport', foreign_key: 'passport_id'
end