# frozen_string_literal: true

# module for switching between passport and inventory
module GetInventory
  def get_inventory(message, bot)
    user = find_or_build_user(message.from)
    passport = user.passport
    bot.api.edit_message_text(chat_id: user.telegram_id, message_id: message.message.message_id,
                              text: "\xF0\x9F\x8E\x92 СУМКА:\n#{passport.inventory}" \
                                    "#{special_items_message(passport.additional_kvest, passport.kvest_repeat)}}" \
                                    "#{elixirs_message(passport)}#{familiars_message(passport)}",
                              reply_markup: passport_markup)
  end

  def get_passport_back(message, bot)
    user = find_or_build_user(message.from)
    bot.api.edit_message_text(chat_id: user.telegram_id, message_id: message.message.message_id,
                              text: output_passport(user.passport_id, user), reply_markup: passport_markup)
  end

  def passport_markup
    Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: [
      Telegram::Bot::Types::InlineKeyboardButton.new(
        text: 'Открыть паспорт', callback_data: 'passport'
      )
    ])
  end

  private

  def special_items_message(additional_kvest, repeat_kvest)
    add_kvest = additional_kvest_message(additional_kvest)
    rep_kvest = repeat_kvest_message(repeat_kvest)
    add_kvest.blank? && rep_kvest.blank? ? '' : "Специальные предметы: \n#{add_kvest}#{rep_kvest}"
  end

  def additional_kvest_message(additional_kvest)
    additional_kvest.zero? ? '' : "Свиток дополнительного квеста #{additional_kvest} штук(и)\n\n"
  end

  # \xF0\x9F\x8E\x9F\xEF\xB8\x8F Специальные предметы:\n
  def repeat_kvest_message(repeat_kvest)
    repeat_kvest.zero? ? '' : "Свиток дополнительного квеста #{repeat_kvest} штук(и)\n\n"
  end

  def elixirs_message(passport)
    "\xF0\x9F\xA7\xAA Эликсиры:\n#{passport.elixirs.split(' ').join("\n")}"
  end

  def familiars_message(passport)
    passport.school == 'Школа Змеи' ? "\n\n\xF0\x9F\x91\xBB Фамильяр:\n#{passport.familiar}\n" : ''
  end
end
