# frozen_string_literal: true

# module for getting passports completed kvests list
module GetKvests
  def get_kvests(message, bot, user)
    if user.passport_id.nil?
      bot.api.send_message(chat_id: message.chat.id,
                           text: 'Похоже к вам еще не привязан паспорт, используйте кнопку ' \
                                 'Получить свой паспорт')
    else
      message_kvests = user.passport.kvests.map { |kvest| "#{kvest['kvest_name']}\n" }.join
      bot.api.send_message(chat_id: message.chat.id, text: "Выполненные квесты:\n\n#{message_kvests}")
    end
  end
end
