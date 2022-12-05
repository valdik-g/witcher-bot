require 'telegram/bot'

class BirthdayJob < ApplicationJob
  queue_as :default

  def perform()
    token = "5587814730:AAFci39iNXTgIeDLVTvKpCjULW2a94zbuP8"

    send_m_kb = [
      Telegram::Bot::Types::InlineKeyboardButton.new(text: 'Написать Анри', url: 'https://t.me/andreiperevoshchikov')
    ]
    
    send_markup = Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: send_m_kb)

    Telegram::Bot::Client.run(token) do |bot|
      Passport.all.each do |passport|
        unless passport.bd.blank?
          day = (Date.today + 3).strftime('%d.%m')
          if "#{passport.bd.split('.')[0]}.#{passport.bd.split('.')[1]}" == day
            passports_to_send = Passport.all - [passport]
            passports_to_send.each do |pass|
              bot.api.send_message(chat_id: User.find_by(:passport_id => pass.id).telegram_id,
              text: "\xF0\x9F\x8E\x8A Через 3 дня день рождения у #{passport.nickname} \xF0\x9F\x8E\x8A
              Если хочешь порадовать именниника подарком пиши Анри", reply_markup: send_m_kb)
            end
          end
        end
      end
    end
  end
end