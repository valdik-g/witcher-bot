# frozen_string_literal: true

# module for switching between passport and inventory
module PassportCallbackQuery
  def get_inventory(message, bot, get_passport_markup)
    user = find_or_build_user(message.from)
    passport = user.passport
    inventory = passport.inventory
    inventory += "\n" unless passport.inventory.split("\n").empty?
    additional_kvest = additional_kvest_message(passport.additional_kvest)
    repeat_kvest = repeat_kvest_message(passport.kvest_repeat)
    bot.api.edit_message_text(chat_id: user.telegram_id, message_id: message.message.message_id,
                              text: "\xF0\x9F\x8E\x92 СУМКА:\n#{inventory}"\
      "#{additional_kvest}\xF0\x9F\xA7\xAA Эликсиры:\n#{passport.elixirs.split(' ').join("\n")}#{if passport.school == 'Школа Змеи'
                                                                                                   "\n\n\xF0\x9F\x91\xBB Фамильяр:\n#{passport.familiar}\n"
                                                                                                 end}",
                              reply_markup: get_passport_markup)
  end

  def get_passport_back(message, bot, passport_markup)
    user = find_or_build_user(message.from)
    bot.api.edit_message_text(chat_id: user.telegram_id, message_id: message.message.message_id,
                              text: output_passport(user.passport_id, user), reply_markup: passport_markup)
  end

  private

  def additional_kvest_message(additional_kvest)
    additional_kvest.zero? ? '' : "Свиток дополнительного квеста #{additional_kvest} штук(и)\n\n"
  end
  # \xF0\x9F\x8E\x9F\xEF\xB8\x8F Специальные предметы:\n
  def repeat_kvest_message(repeat_kvest)
    repeat_kvest.zero? ? '' : "Свиток дополнительного квеста #{repeat_kvest} штук(и)\n\n"
  end
end
