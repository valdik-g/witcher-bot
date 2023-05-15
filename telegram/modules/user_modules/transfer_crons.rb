# frozen_string_literal: true

# module for transfering crons between users
module TransferCrons
  def transfer_crons(message, bot, user)
    output_all_passports(bot, message.chat.id)
    bot.api.send_message(chat_id: message.chat.id, text: 'Кому переведем кроны?', reply_markup: cancel_markup)
    user.update(step: 'input_passport_to_transfer')
  end

  def input_passport_to_transfer(message, bot, user)
    bot.api.send_message(chat_id: message.chat.id, text: "Сколько?\nДоступно #{user.passport.crons}")
    user.update(step: 'transfer_crons')
    message.text.to_i
  end
end
