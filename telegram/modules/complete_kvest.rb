# frozen_string_literal: true

# module for add completed kvests to users
module CompleteKvest
  def complete_kvest(message, bot, user, cancel_markup)
    if user.admin
      output_all_passports(bot, message.chat.id)
      bot.api.send_message(chat_id: message.chat.id,
                           text: 'Выберите номер паспорта игрока, выполнившего квест',
                           reply_markup: cancel_markup)
      user.update(step: 'input_passport_number')
    else
      bot.api.send_message(chat_id: message.chat.id, text: 'Ты как сюда залез?)')
    end
  end

  def input_passport_number(message, bot, user)
    kvests = Kvest.all
    kvests_message = ''
    kvests.map do |kvest|
      kvests_message += "#{kvest.id}: #{kvest.kvest_name}\n"
    end
    bot.api.send_message(chat_id: message.chat.id, text: kvests_message)
    bot.api.send_message(chat_id: message.chat.id, text: 'Введите номер(а) выполненного квеста')
    user.update(step: 'input_kvest_number')
    message.text
  end

  def input_kvest_number(message, bot, user, passport_number)
    kvest_number = message.text
    kvests_number = kvest_number.split(' ')
    passports_number = passport_number.split(' ')
    passports_number.map do |pass_number|
      passport = Passport.find_by(id: pass_number)
      next unless passport

      kvests_number.map do |number|
        kvest = Kvest.find_by(id: number)
        next unless kvest

        new_crons = kvest.crons_reward + passport.crons
        new_level = (kvest.level_reward + passport.level.to_i).to_s
        passport.update(crons: new_crons, level: new_level)
        passport.titles << Title.find_by(id: kvest.title_id) unless kvest.title_id.nil?
        passport.update(inventory: passport.inventory + kvest.additional_reward) if kvest.additional_reward != 'Нет'
        passport.update(inventory: "#{passport.inventory}\n") if kvest.additional_reward != 'Нет'
        passport.kvests << kvest
        bot.api.send_message(chat_id: message.chat.id,
                             text: "Квест #{kvest.kvest_name} успешно выполнен игроком #{passport.nickname}")
        unless User.find_by(passport_id: passport.id).nil?
          bot.api.send_message(chat_id: User.find_by(passport_id: passport.id).telegram_id,
                               text: "Поздравляем, ваш уровень повышен до #{passport.level}")
        end
      end
    end
    return_buttons(user, bot, message.chat.id, 'Квесты проставлены игрокам')
  end
end
