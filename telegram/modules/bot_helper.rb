# frozen_string_literal: true

# module with help functions for bot
module BotHelper
  def return_buttons(user, bot, chat_id, message_text = 'Неверный ввод, повторите команду снова')
    reply_markup = user.admin ? admin_markup : remove_markup
    reply_markup = hamon_markup if user.telegram_id == 448_768_896
    bot.api.send_message(chat_id: chat_id, text: message_text, reply_markup: reply_markup)
    user.update(step: nil)
  end

  def output_all_passports(bot, chat_id)
    schools = ['Ⲱⲕⲟⲗⲁ Ⲃⲟⲗⲕⲁ', 'Ⲱⲕⲟⲗⲁ Ⲙⲁⲏⲧυⲕⲟⲣы', 'Ⲱⲕⲟⲗⲁ Ⲕⲟⲧⲁ', 'Ⲱⲕⲟⲗⲁ Ⳅⲙⲉυ', 'Ⲱⲕⲟⲗⲁ Ⲙⲉⲇⲃⲉⲇя', 'Ⲱⲕⲟⲗⲁ Ⲅⲣυⲫⲟⲏⲁ', 'Ⲱⲕⲟⲗⲁ Ⲗυⲥⲁ']
    passports_message = ''
    schools.each do |school|
      passports_message += school + ":\n\n"
      passports_message += Passport.where(school: school).map { |p| "#{p.id}: #{p.nickname}\n" }.join
      passports_message += "\n"
    end
    unknown = Passport.where(school: 'Неизвестно').map { |p| "#{p.id}: #{p.nickname}\n" }
    unless unknown.empty?
      passports_message += "Не определились:\n\n"
      passports_message += unknown.join
    end
    bot.api.send_message(chat_id: chat_id, text: passports_message)
  end

  def output_all_passport_kvests(bot, chat_id, passport_id)
    passport = Passport.find_by(id: passport_id)
    kvests_message = passport.kvests.map { |p| "#{p.id}: #{p.kvest_name}\n" }.join
    bot.api.send_message(chat_id: chat_id, text: kvests_message)
  end

  def find_or_build_user(user_obj)
    user = User.find_by(telegram_id: user_obj.id)
    username = ''
    username += user_obj.first_name.to_s
    username += ' ' if user_obj.last_name && user_obj.first_name
    username += user_obj.last_name.to_s
    user || User.create(telegram_id: user_obj.id, username: username)
  end

  def get_buffs(passport_id)
    buffs = Passport.find(passport_id).buffs.map { |b| "#{b.buff_name}:\n#{b.buff_description}\n" }.join("\n")
    buffs.empty? ? "\n" : "\n\n\xE2\x86\x95Ⳝⲁⲫⲫы/Ⲇⲉⳝⲁⲫⲫы:\n" + buffs
  end

  def output_passport(passport_id, user)
    passport = Passport.find(passport_id)
    "\xF0\x9F\x97\xA1 ⲠⲈⲢⲤⲞⲎⲀⲮ:\n\n#{passport.nickname} #{passport.level} ⳑⳳⳑ\nⲢⲀⲎⲄ - #{passport.rank}\nⲨⲣⲟⲃⲉⲏь ⳝⲟⲉⲃⲟⲅⲟ ⲡⲣⲟⲡⲩⲥⲕⲁ - #{passport.bp_level} ⳑⳳⳑ\n
\xF0\x9F\x8F\xB0 Ⲱⲕⲟⲗⲁ: #{passport.school}\nⲒⲆ - #{passport.id}\n\n#{passports_title(passport)}
#{long_kvest(passport)}#{completed_kvests(user, passport)}\xF0\x9F\x93\x9C ⲞⲠⳘⲤⲀⲎⳘⲈ:\n#{passport.description}#{get_buffs(passport_id)}
\xF0\x9F\x8E\x92 ⲤⲨⲘⲔⲀ:\nⲔⲣⲟⲏы - #{passport.crons}\xF0\x9F\xAA\x99"
  end

  def passports_title(passport)
    title = passport.main_title_id.nil? ? 'Отсутствует' : Title.find_by(id: passport.main_title_id).title_name
    "\xF0\x9F\x93\xAF Титул: #{title}\n"
  end

  def long_kvest(passport)
    long_kvest = passport.long_kvest_id.nil? ? 'Нет' : Kvest.find_by(id: passport.long_kvest_id).kvest_name
    "\xE2\x9D\x93 Ⲡⲣⲟⲭⲟⲇυⲧ ⲕⲃⲉⲥⲧ:\n#{long_kvest}\n\n"
  end

  def completed_kvests(user, passport)
    if (user.admin && passport.id != user.passport_id) || (user.telegram_id == 792485579 && passport.id != user.passport_id)
      kvests = passport.kvests.map { |kvest| "-#{kvest.kvest_name}" }.join("\n")
      "\xE2\x9D\x94 Пройденные квесты:\n#{kvests || "Кажется игрок еще не выполнил ни одного квеста!"}\n\n"
    else
      ''
    end
  end

  def admin_markup
    Telegram::Bot::Types::ReplyKeyboardMarkup.new(keyboard: admin_buttons.map do |button|
      Telegram::Bot::Types::KeyboardButton.new(text:button)
    end)
  end

  def admin_buttons
    ['Создать паспорт', 'Создать квест', 'Создать титул', 'Выполнить квест', 'Повторить квест', 'Снять квест',
     'Назначить титул', 
     'Изменить запись', 'Списать занятия', 'Начислить занятия', 'Добавить предмет', 'Информация по игроку', 
     'Информация по всем абонементам', 'Списать кроны', 'Повысить ранг', 'Уведомление', 'Провести турнир', 
     'Управление магазином', 'Изменить инвентарь', 'Создать уровень БП', 'Повысить уровень БП', 'Отобразить уровни БП',
     'Открыть предзапись', 'Закрыть предзапись']
  end

  def no_markup
    Telegram::Bot::Types::ReplyKeyboardMarkup.new(keyboard: [
      Telegram::Bot::Types::KeyboardButton.new(text: 'Нет')
    ], resize_keyboard: true)
  end

  def hamon_markup
    Telegram::Bot::Types::ReplyKeyboardMarkup.new(keyboard: [
      Telegram::Bot::Types::KeyboardButton.new(text: 'Изменить описание')
    ], resize_keyboard: true)
  end

  def remove_markup
    Telegram::Bot::Types::ReplyKeyboardRemove.new(remove_keyboard: true)
  end

  def cancel_markup
    Telegram::Bot::Types::ReplyKeyboardMarkup.new(keyboard: [
      Telegram::Bot::Types::KeyboardButton.new(text: 'Отмена')
    ], resize_keyboard: true)
  end

  def feedback_markup
    Telegram::Bot::Types::ReplyKeyboardMarkup.new(keyboard: [
      Telegram::Bot::Types::KeyboardButton.new(text: 'Анонимно'),
      Telegram::Bot::Types::KeyboardButton.new(text: 'Открыто'),
      Telegram::Bot::Types::KeyboardButton.new(text: 'Отмена')
    ], resize_keyboard: true)
  end
end
