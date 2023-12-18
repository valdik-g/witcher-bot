# frozen_string_literal: true

# module for ranking up users
module RemoveKvest
  def choose_passport_to_remove(message, bot, user)
    if user.admin
      output_all_passports(bot, message.chat.id)
      bot.api.send_message(chat_id: message.chat.id, text: 'Выберите того, кому необходимо удалить квест',
                           reply_markup: cancel_markup)
      user.update(step: 'choose_kvest_to_delete')
    else
      bot.api.send_message(chat_id: message.chat.id, text: 'Ты как сюда залез?)')
    end
  end

  def choose_kvest_to_delete(message, bot, user, passport_id)
    passport = Passport.find_by(id: message.text)
    if passport.nil?
      return_buttons(user, bot, message.chat.id, 'Некорректный ввод, повторите команду')
    else
      output_all_passport_kvests(bot, message.chat.id, passport_id)
      bot.api.send_message(chat_id: message.chat.id, text: 'Выберите квест который необходимо удалить')
      user.update(step: 'remove_passport_kvest')
    end
  end

  def remove_passport_kvest(message, bot, user, passport_id, kvest_id)
    kvest = Kvest.find_by(id: message.text)
    passport = Passport.find_by(id: passport_id)
    if kvest.nil?
      return_buttons(user, bot, message.chat.id, 'Некорректный ввод, повторите команду')
    else
      passport.kvests.delete(kvest)
      passport.update(crons: (passport.crons - kvest.crons_reward), level: (passport.level.to_i - kvest.level_reward.to_i),
                      additional_kvest: (passport.additional_kvest - kvest.additional_kvest), kvest_repeat: (passport.kvest_repeat - kvest.kvest_repeat))
      if passport.title_id
        title = Title.find_by(id: passport.title_id)
        passport.titles.delete(title)
      end
      return_buttons(user, bot, message.chat.id, 'Квест удален (Дополнительная награда не ' \
                                                 'удаляется автоматически: предметы в инвентаре)')
    end
  end
end
  