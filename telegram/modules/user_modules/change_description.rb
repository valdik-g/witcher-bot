# frozen_string_literal: true

# module for changing user description
module ChangeDescription
  def change_description(message, bot, user, cancel_markup)
    output_all_passports(bot, message.chat.id)
    bot.api.send_message(chat_id: message.chat.id,
                         text: 'Жги, выбирай кому поменять описание, вводи циферку',
                         reply_markup: cancel_markup)
    user.update(step: 'input_descr_passport')
  end

  def input_descr_passport(message, bot, user)
    bot.api.send_message(chat_id: message.chat.id,
                         text: "Предыдущее описание: #{@change_passport_h.description}\n" \
     'Введите новое описание:')
    user.update(step: 'input_new_description')
    Passport.find(id: message.text)
  end

  def input_new_description(message, bot, user, change_passport_h)
    change_passport_h.update(description: message.text)
    return_buttons(user, bot, message.chat.id, 'Описание изменено')
  end
end
