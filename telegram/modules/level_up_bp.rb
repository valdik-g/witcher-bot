# frozen_string_literal: true

# module for level up battle pass
module LevelUpBP
  def choose_level_up_bp_passports(message, bot, user)
    if user.admin
      output_all_passports(bot, message.chat.id)
      bot.api.send_message(chat_id: message.chat.id,
                           text: 'Выберите тех, кому повысить уровень бп:',
                           reply_markup: cancel_markup)
      user.update(step: 'level_up_passport')
    else
      bot.api.send_message(chat_id: message.chat.id, text: 'Ты как сюда залез?)')
    end
  end

  def level_up_passport(message, bot, user)
    message.text.split(' ').each do |passport_id|
      passport = Passport.find_by(id: passport_id)
      next unless passport

      next_level = passport.bp_level + 1
      bp_kvest = BattlePassKvest.find_by(id: next_level)
      
      unless bp_kvest
        bot.api.send_message(chat_id: message.chat.id,
          text: "Для игрока #{passport.nickname} невозможно повысить уровень боевого пропуска," \
                " создайте новый уровень пропуска")
        next
      end

      add_bp_reward(BattlePassKvest.find_by(id: next_level), passport)
      bot.api.send_message(chat_id: message.chat.id,
                           text: "Уровень боевого пропуска для игрока #{passport.nickname} повышен")
      unless User.find_by(passport_id: passport.id).nil?
        bot.api.send_message(chat_id: User.find_by(passport_id: passport.id).telegram_id,
                             text: "Поздравляем, ваш уровень боевого пропуска повышен до #{passport.bp_level}")
      end
    end

    return_buttons(user, bot, message.chat.id, "Уровень боевого пропуска повышен")
  end

  private

  def add_bp_reward(kvest, passport)
    new_crons = kvest.crons_reward + passport.crons
    new_addkvest = kvest.additional_kvest + passport.additional_kvest
    new_repkvest = kvest.kvest_repeat + passport.kvest_repeat
    new_callkvest = kvest.kvest_call + passport.kvest_call
    passport.update(crons: new_crons, additional_kvest: new_addkvest, 
                    kvest_repeat: new_repkvest, kvest_call: new_callkvest, bp_level: passport.bp_level + 1)
    passport.titles << Title.find_by(id: kvest.title_id) unless kvest.title_id.nil?
  end
end
