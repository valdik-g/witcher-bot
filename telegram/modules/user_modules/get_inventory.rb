# frozen_string_literal: true

# module for switching between passport and inventory
module GetInventory
  def get_inventory(message, bot)
    user = find_or_build_user(message.from)
    passport = user.passport
    items, elixirs = get_items_and_elixirs(passport)
    bot.api.edit_message_text(chat_id: user.telegram_id, message_id: message.message.message_id,
                              text: "\xF0\x9F\x8E\x92 СУМКА:\n#{items}\n" \
                                    "#{special_items_message(passport.additional_kvest, passport.kvest_repeat)}" \
                                    "#{elixirs_message(elixirs)}#{familiars_message(passport)}",
                              reply_markup: passport_markup)
  end

  def get_passport_back(message, bot)
    user = find_or_build_user(message.from)
    bot.api.edit_message_text(chat_id: user.telegram_id, message_id: message.message.message_id,
                              text: output_passport(user.passport_id, user), reply_markup: inventory_markup)
  end

  def passport_markup
    Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: [
      Telegram::Bot::Types::InlineKeyboardButton.new(
        text: 'Открыть паспорт', callback_data: 'passport'
      )
    ])
  end

  def inventory_markup
    Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: [
      Telegram::Bot::Types::InlineKeyboardButton.new(
        text: 'Открыть инвентарь', callback_data: 'inventory'
      )
    ])
  end

  private

  def special_items_message(additional_kvest, repeat_kvest)
    add_kvest = additional_kvest_message(additional_kvest)
    rep_kvest = repeat_kvest_message(repeat_kvest)
    add_kvest.blank? && rep_kvest.blank? ? '' : "\nСпециальные предметы: \n#{add_kvest}#{rep_kvest}\n"
  end

  def additional_kvest_message(additional_kvest)
    additional_kvest.zero? ? '' : "Свиток дополнительного квеста #{additional_kvest} штук(и)\n"
  end

  # \xF0\x9F\x8E\x9F\xEF\xB8\x8F Специальные предметы:\n
  def repeat_kvest_message(repeat_kvest)
    repeat_kvest.zero? ? '' : "Свиток повторного квеста #{repeat_kvest} штук(и)\n"
  end

  def elixirs_message(elixirs)
    elixirs.blank? ? '' : "\xF0\x9F\xA7\xAA Эликсиры:\n#{elixirs}\n"
  end

  def familiars_message(passport)
    passport.school == 'Школа Змеи' ? "\n\xF0\x9F\x91\xBB Фамильяр:\n#{passport.familiar}\n" : ''
  end

  def get_items_and_elixirs(passport)
    items, elixirs = [[], []]
    passport.inventor.split("\n").each do |item|
      item.include?("Эликсир") ? elixirs.push(item) : items.push(item)
    end
    [items.join("\n"), elixirs.join("\n")]
  end
end
