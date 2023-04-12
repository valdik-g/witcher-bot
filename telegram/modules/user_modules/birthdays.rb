# frozen_string_literal: true

# module for getting birthdays of players for 40 days
module Birthdays
  def birthdays(chat_id, bot, _user)
    birthday_message = sorted_passports.map do |pass|
      bd = pass.bd.split('.')
      next unless this_month_condition(bd) || next_month_condition(bd)

      "#{pass.nickname}: #{bd[0]}.#{bd[1]}\n"
    end.join
    bot.api.send_message(chat_id: chat_id, text: "Список дней рождений на следующие 40 дней:\n#{birthday_message}")
  end

  def sorted_passports
    pass_with_bd = Passport.where("bd <> '' and bd like '%.%'").select(:nickname, :bd)
    pass_with_bd.sort_by { |pass| "#{pass.bd.split('.')[1]}#{pass.bd.split('.')[0]}" }
  end

  def this_month_condition(b_date)
    (b_date[0] > format('%02i', DateTime.now.day) && b_date[1] == format('%02i', DateTime.now.month))
  end

  def next_month_condition(b_date)
    (b_date[0] < format('%02i', (DateTime.now + 40).day) && b_date[1] == format('%02i', (DateTime.now + 40).month))
  end
end
