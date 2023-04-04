# frozen_string_literal: true

module BotHelper
  def return_buttons(user, bot, chat_id, message_text)
    reply_markup = user.admin ? @admin_markup : @remove_keyboard
    reply_markup = @hamon_markup if user.telegram_id == 448_768_896
    bot.api.send_message(chat_id: chat_id, text: message_text, reply_markup: reply_markup)
  end

  def output_all_passports(bot, chat_id)
    passports_message = ''
    Passport.all.map { |p| passports_message += "#{p.id}: #{p.nickname}\n" }
    bot.api.send_message(chat_id: chat_id, text: passports_message)
  end

  def find_or_build_user(user_obj)
    user = User.find_by(telegram_id: user_obj.id)
    username = ''
    username += user_obj.first_name.to_s
    username += ' ' if user_obj.last_name && user_obj.first_name
    username += user_obj.last_name.to_s
    user || User.create(telegram_id: user_obj.id, username: username)
  end

  def output_passport(passport_id, chat_id)
    passport = Passport.find_by(id: passport_id)
    kvests = ''
    passport.kvests.map do |kvest|
      kvests += "-#{kvest.kvest_name}\n"
    end
    long_kvest_record = Kvest.find_by(id: passport.long_kvest_id)
    long_kvest = 'Нет'
    long_kvest = long_kvest_record.kvest_name if long_kvest_record
    additional_kvest = ''
    additional_kvest += "Свиток задания #{passport.additional_kvest} штук(и)\n" unless passport.additional_kvest.zero?
    kvests = "Кажется игрок еще не выполнил ни одного квеста!\n" if kvests.empty?
    title = passport.main_title_id.nil? ? 'Отсутствует' : Title.find_by(id: passport.main_title_id).title_name
    inventory = passport.inventory.split(' ').join("\n")
    inventory += "\n" if passport.inventory.split(' ').length == 1
    "\xF0\x9F\x97\xA1 ПЕРСОНАЖ:\n\n#{passport.nickname} #{passport.level} lvl
      РАНГ- #{passport.rank}\n
      \xF0\x9F\x8F\xB0 Школа: #{passport.school}\n
      \xF0\x9F\x93\xAF Титул: #{title}\n
      \xE2\x9D\x93 Проходит квест:\n#{long_kvest}\n#{if User.find_by(telegram_id: chat_id).admin && passport.id != User.find_by(telegram_id: chat_id).passport_id
                                                       "\n\xE2\x9D\x94 Пройденные квесты:\n#{kvests}"
                                                     end}
      \xF0\x9F\x93\x9C ОПИСАНИЕ:\n#{passport.description}\n
      \xF0\x9F\x8E\x92 СУМКА:\nКроны - #{passport.crons}\xF0\x9F\xAA\x99"
  end
end
