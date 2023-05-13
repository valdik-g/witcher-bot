# frozen_string_literal: true

class Prerecording < ApplicationRecord
  def close_message
    close_message = ''
    self.choosed_options.split(',').each_with_index do |option, i|
      option_prerecord = UserPrerecording.where('days LIKE ?', "%#{i}%")
      close_message += "#{option}\n\n#{(option_prerecord.map do |pr|
                                            Passport.find(pr.passport_id).nickname
                                          end).join("\n")}\n\n"
    end
    close_message
  end
end
