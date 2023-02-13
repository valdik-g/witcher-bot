# frozen_string_literal: true

require File.expand_path('../config/environment', __dir__)
require 'telegram/bot'
require 'json'

require 'uri'
require 'net/http'
require 'openssl'

token = '5587814730:AAFci39iNXTgIeDLVTvKpCjULW2a94zbuP8'

witcher_name = ''
crons = 0
school = ''
level = 0
rank = ''
additional_kvest = false
elixirs = ''
description = ''
yes = %w[да дп дв жа ла жв жп лп лв]
passport = nil

kvest_name = ''
crons_reward = 0
level_reward = 0
title_reward = ''
additional_reward = ''

title_name = ''
title_description = ''

passport_number = 0

tables = [User, Passport, Kvest, Title]

active_table = nil
record = nil
field = nil
field_array = []

passport_id = nil
change_passport_h = nil

update_field = ''

options = %w[Сб1 Сб2 Вс0 Вс1 Вс2]

cancel_mkb = [
  Telegram::Bot::Types::KeyboardButton.new(text: 'Отмена')
]
cancel_markup = Telegram::Bot::Types::ReplyKeyboardMarkup.new(keyboard: cancel_mkb, resize_keyboard: true)

admin_kb = [
  Telegram::Bot::Types::KeyboardButton.new(text: 'Создать паспорт'),
  Telegram::Bot::Types::KeyboardButton.new(text: 'Создать квест'),
  Telegram::Bot::Types::KeyboardButton.new(text: 'Создать титул'),
  Telegram::Bot::Types::KeyboardButton.new(text: 'Выполнить квест'),
  Telegram::Bot::Types::KeyboardButton.new(text: 'Назначить титул'),
  Telegram::Bot::Types::KeyboardButton.new(text: 'Изменить запись'),
  Telegram::Bot::Types::KeyboardButton.new(text: 'Списать занятия'),
  Telegram::Bot::Types::KeyboardButton.new(text: 'Получить паспорт игрока'),
  Telegram::Bot::Types::KeyboardButton.new(text: 'Информация по игроку'),
  Telegram::Bot::Types::KeyboardButton.new(text: 'Информация по всем абонементам'),
  Telegram::Bot::Types::KeyboardButton.new(text: 'Открыть предзапись'),
  Telegram::Bot::Types::KeyboardButton.new(text: 'Закрыть предзапись')
]

admin_markup = Telegram::Bot::Types::ReplyKeyboardMarkup.new(keyboard: admin_kb, resize_keyboard: true)

passport_kb = [
  Telegram::Bot::Types::InlineKeyboardButton.new(text: 'Открыть инвентарь', callback_data: 'inventory')
]

hamon_kb = [
  Telegram::Bot::Types::KeyboardButton.new(text: 'Изменить описание')
]

hamon_markup = Telegram::Bot::Types::ReplyKeyboardMarkup.new(keyboard: hamon_kb, resize_keyboard: true)

feedback_kb = [
  Telegram::Bot::Types::KeyboardButton.new(text: 'Анонимно'),
  Telegram::Bot::Types::KeyboardButton.new(text: 'Открыто')
]

feedback_markup = Telegram::Bot::Types::ReplyKeyboardMarkup.new(keyboard: feedback_kb, resize_keyboard: true)

passport_markup = Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: passport_kb)

main_admins_ids = [822_281_212, 612_352_098]

def find_or_build_user(user_obj, _chat_id = nil)
  user = User.find_by(telegram_id: user_obj.id)
  username = ''
  username += user_obj.first_name.to_s
  username += ' ' if user_obj.last_name && user_obj.first_name
  username += user_obj.last_name.to_s
  user || User.create(telegram_id: user_obj.id, username: username)
end

def output_passport(passport_id, chat_id, _bot)
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
  passport_text = "\xF0\x9F\x97\xA1 ПЕРСОНАЖ:\n\n#{passport.nickname} #{passport.level} lvl
РАНГ- #{passport.rank}\n
\xF0\x9F\x8F\xB0 Школа: #{passport.school}\n
\xF0\x9F\x93\xAF Титул: #{title}\n
\xE2\x9D\x93 Проходит квест:\n#{long_kvest}\n#{if User.find_by(telegram_id: chat_id).admin && passport.id != User.find_by(telegram_id: chat_id).passport_id
                                                 "\n\xE2\x9D\x94 Пройденные квесты:\n#{kvests}"
                                               end}
\xF0\x9F\x93\x9C ОПИСАНИЕ:\n#{passport.description}\n
\xF0\x9F\x8E\x92 СУМКА:\nКроны - #{passport.crons}\xF0\x9F\xAA\x99"
end

remove_keyboard = Telegram::Bot::Types::ReplyKeyboardRemove.new(remove_keyboard: true)

Telegram::Bot::Client.run(token) do |bot|
  Sidekiq::Cron::Job.create(
    name: 'BirthdayCheck',
    cron: '00 12 * * * Europe/Minsk',
    class: 'BirthdayCheckWorker'
  )

  bot.listen do |message|
    case message
    when Telegram::Bot::Types::PollAnswer
      if message.user.id == 612_352_098
        @choosed_options = message.option_ids.map { |l| options[l.to_i] }
        Prerecording.last.update(choosed_options: (message.option_ids.map { |l| options[l.to_i] }).join(','))
        passports = Passport.where('subscription > 0 and subscription < 1000')
        passports.map do |pass|
          next if User.find_by(passport_id: pass.id).nil? || User.find_by(passport_id: pass.id).telegram_id.nil?

          bot.api.send_message(chat_id: User.find_by(passport_id: pass.id).telegram_id, text: @vote_message)
          poll_message_id = bot.api.send_poll(chat_id: User.find_by(passport_id: pass.id).telegram_id,
                                              question: 'Куда идем?', allows_multiple_answers: true, options: @choosed_options,
                                              is_anonymous: false)
          (UserPrerecording.find_by(passport_id: pass.id) || UserPrerecording.create(passport_id: pass.id))
            .update(message_id: poll_message_id)
        end
      elsif Prerecording.last.closed
        bot.api.send_message(chat_id: message.user.id, text: 'Предзапись уже закрыта, ждите дальнейших новостей')
      else
        UserPrerecording.find_by(passport_id: User.find_by(telegram_id: message.user.id).passport_id).update(days: message.option_ids.join(','))
        # UserPrerecording.find_by(:passport_id =>
        #   User.find_by(:telegram_id => message.user.id).passport_id).update(:days => message.option_ids.map { |l| options[l.to_i] })
      end
    when Telegram::Bot::Types::CallbackQuery
      case message.data
      when 'inventory'
        get_passport_kb = [
          Telegram::Bot::Types::InlineKeyboardButton.new(text: 'Открыть паспорт', callback_data: 'passport')
        ]
        get_passport_markup = Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: get_passport_kb)
        user = find_or_build_user(message.from)
        passport = Passport.find_by(id: user.passport_id)
        inventory = passport.inventory
        inventory += "\n" unless passport.inventory.split("\n").empty?
        additional_kvest = ''
        unless passport.additional_kvest.zero?
          additional_kvest = "\xF0\x9F\x8E\x9F\xEF\xB8\x8F Специальные предметы:\nСвиток задания #{passport.additional_kvest} штук(и)\n\n"
        end
        bot.api.edit_message_text(chat_id: user.telegram_id, message_id: message.message.message_id,
                                  text: "\xF0\x9F\x8E\x92 СУМКА:\n#{inventory}"\
          "#{additional_kvest}\xF0\x9F\xA7\xAA Эликсиры:\n#{passport.elixirs.split(' ').join("\n")}#{if passport.school == 'Школа Змеи'
                                                                                                       "\n\n\xF0\x9F\x91\xBB Фамильяр:\n#{passport.familiar}\n"
                                                                                                     end}",
                                  reply_markup: get_passport_markup)
      when 'passport'
        user = find_or_build_user(message.from)
        bot.api.edit_message_text(chat_id: user.telegram_id, message_id: message.message.message_id,
                                  text: output_passport(user.passport_id, user.telegram_id, bot),
                                  reply_markup: passport_markup)
      end
    when Telegram::Bot::Types::Message
      begin
        user = find_or_build_user(message.from, message.chat.id)
        unless message.text.nil? && !message.text.empty? # && message.document.nil?
          case user.step
          when nil, 'start'
            case message.text
            when '/start', '/info'
              bot.api.send_message(chat_id: message.chat.id,
                                   text: "Привет, я бот клуба 'Свое Дело'!\nСписок моих команд находится внизу, удачи \xE2\x9D\xA4")
            when '/passport', "\xF0\x9F\x93\x9C Получить свой паспорт \xF0\x9F\x93\x9C"
              if user.passport_id.nil?
                passport = Passport.find_by(telegram_nick: user.username)
                if passport.nil?
                  bot.api.send_message(chat_id: message.chat.id,
                                       text: 'Кажется ваш паспорт еще не существует, обратитесь к Анри Виллу')
                else
                  user.update(passport_id: passport.id)
                  user.update(step: 'input_bd')
                  bot.api.send_message(chat_id: message.chat.id,
                                       text: "Мы нашли ваш паспорт, однако предварительно нужно собрать немного ифнормации о вас\nВведите дату рождения(формат 03.09):")
                end
              elsif Passport.find(user.passport_id).bd.empty?
                user.update(step: 'input_bd')
                bot.api.send_message(chat_id: message.chat.id,
                                     text: "Мы нашли ваш паспорт, однако предварительно нужно собрать немного ифнормации о вас\nВведите дату рождения(формат 03.09):")
              else
                bot.api.send_message(chat_id: message.chat.id,
                                     text: output_passport(user.passport_id, message.chat.id, bot), reply_markup: passport_markup)
              end
            when '/get_best', "\xF0\x9F\x94\x9D Получить паспорт лучшего игрока \xF0\x9F\x94\x9D"
              passport = Passport.order('level DESC, crons DESC').first
              bot.api.send_message(chat_id: message.chat.id,
                                   text: "\xF0\x9F\x94\xA5 Паспорт лучшего игрока \xF0\x9F\x94\xA5")
              bot.api.send_message(chat_id: message.chat.id,
                                   text: output_passport(passport.id, message.chat.id, bot), reply_markup: passport_markup)
            when '/get_history', "\xF0\x9F\x97\xBF Получить историю персонажа \xF0\x9F\x97\xBF"
              if user.passport_id.nil?
                bot.api.send_message(chat_id: message.chat.id,
                                     text: 'Похоже к вам еще не привязан паспорт, используйте кнопку Получить свой паспорт')
              else
                history = Passport.find_by(id: user.passport_id).history
                history = 'История вашего персонажа пуста' if history.empty?
                bot.api.send_message(chat_id: message.chat.id, text: history)
              end
            when '/update_history', "\xE2\x9C\x8D Изменить историю персонажа \xE2\x9C\x8D"
              if user.passport_id.nil?
                bot.api.send_message(chat_id: message.chat.id,
                                     text: 'Похоже к вам еще не привязан паспорт, используйте кнопку Получить свой паспорт')
              else
                history = Passport.find_by(id: user.passport_id).history
                if history.empty?
                  history = "История вашего персонажа пуста, самое время это исправить!\nВведите историю вашего персонажа"
                end
                bot.api.send_message(chat_id: message.chat.id, text: history)
                bot.api.send_message(chat_id: message.chat.id, text: 'Введите новую историю',
                                     reply_markup: cancel_markup)
                user.update(step: 'change_history')
              end
            when '/get_kvests'
              if user.passport_id.nil?
                bot.api.send_message(chat_id: message.chat.id,
                                     text: 'Похоже к вам еще не привязан паспорт, используйте кнопку Получить свой паспорт')
              else
                kvests = Passport.find_by(id: user.passport_id).kvests
                message_kvests = ''
                kvests.each do |kvest|
                  message_kvests += "#{kvest['kvest_name']}\n"
                end
                bot.api.send_message(chat_id: message.chat.id, text: message_kvests)
              end
            when '/change_info'
              if user.passport_id.nil?
                bot.api.send_message(chat_id: message.chat.id,
                                     text: 'Похоже к вам еще не привязан паспорт, используйте кнопку Получить свой паспорт')
              else
                passport = Passport.find_by(id: user.passport_id)
                bot.api.send_message(chat_id: message.chat.id,
                                     text: "Личная информация:\n1. Дата рождения: #{passport.bd}\n2. Почта: #{passport.mail}\n3. Телефон: #{passport.number}")
                bot.api.send_message(chat_id: message.chat.id,
                                     text: "Что нужно изменить?\n1. Дата рождения\n2. Почта\n3. Телефон\nВводите цифрой", reply_markup: cancel_markup)
                user.update(step: 'input_change_info_field')
              end
            when '/create_passport', 'Создать паспорт'
              if user.admin
                bot.api.send_message(chat_id: message.chat.id, text: 'Введите имя будующего ведьмака:')
                user.update(step: 'input_name')
              else
                bot.api.send_message(chat_id: message.chat.id, text: 'Ты как сюда залез?)')
              end
            when '/update_field', 'Изменить запись'
              if user.admin
                table_message = ''
                tables.map.with_index do |table, i|
                  table_message += "#{i + 1}: #{table}\n".to_s
                end
                bot.api.send_message(chat_id: message.chat.id,
                                     text: "#{table_message}Выберите таблицу для изменения:")
                user.update(step: 'update_field')
              else
                bot.api.send_message(chat_id: message.chat.id, text: 'Ты как сюда залез?)')
              end
            when '/create_kvest', 'Создать квест'
              if user.admin
                bot.api.send_message(chat_id: message.chat.id, text: 'Введите название квеста:')
                user.update(step: 'input_kvest_name')
              else
                bot.api.send_message(chat_id: message.chat.id, text: 'Ты как сюда залез?)')
              end
            when '/kvest_done', 'Выполнить квест'
              if user.admin
                passports = Passport.all
                passports_message = ''
                passports.map do |passport|
                  passports_message += "#{passport.id}: #{passport.nickname}\n"
                end
                bot.api.send_message(chat_id: message.chat.id, text: passports_message)
                bot.api.send_message(chat_id: message.chat.id,
                                     text: 'Выберите номер паспорта игрока, выполнившего квест')
                user.update(step: 'input_passport_number')
              else
                bot.api.send_message(chat_id: message.chat.id, text: 'Ты как сюда залез?)')
              end
            when '/create_title', 'Создать титул'
              if user.admin
                bot.api.send_message(chat_id: message.chat.id, text: 'Введите название титула')
                user.update(step: 'input_title_name')
              else
                bot.api.send_message(chat_id: message.chat.id, text: 'Ты как сюда залез?)')
              end
            when '/set_title', 'Назначить титул'
              if user.admin
                passports = Passport.all
                passports_message = ''
                passports.map do |passport|
                  passports_message += "#{passport.id}: #{passport.nickname}\n"
                end
                bot.api.send_message(chat_id: message.chat.id, text: passports_message)
                bot.api.send_message(chat_id: message.chat.id, text: 'Выберите номер паспорта игрока')
                user.update(step: 'input_pasport_title')
              else
                bot.api.send_message(chat_id: message.chat.id, text: 'Ты как сюда залез?)')
              end
            when '/choose_title', "\xF0\x9F\x93\xAF Выбрать основной титул \xF0\x9F\x93\xAF"
              titles = Passport.find_by(id: user.passport_id).titles if user.passport_id
              if titles.nil?
                bot.api.send_message(chat_id: message.chat.id, text: 'Похоже у вас нет титулов')
              else
                titles_message = ''
                titles.map do |title|
                  titles_message += "#{title.id}: #{title.title_name}\n"
                end
                bot.api.send_message(chat_id: message.chat.id, text: titles_message)
                bot.api.send_message(chat_id: message.chat.id, text: 'Выберите основной титул, вводите цифрой')
                user.update(step: 'input_main_title')
              end
            when '/get_best_players', 'Получить паспорт игрока'
              passports = Passport.all
              passports_message = ''
              passports.map do |passport|
                passports_message += "#{passport.id}: #{passport.nickname}\n"
              end
              bot.api.send_message(chat_id: message.chat.id, text: passports_message)
              user.update(step: 'input_player_passport_number')
            when '/mem', "\xF0\x9F\xA4\xA1 Мемчик \xF0\x9F\xA4\xA1"
              meme = (Dir.entries('/home/cloud-user/witcher-bot/witcher-bot/telegram/memes').reject do |f|
                        File.directory? f
                      end).sample
              bot.api.sendPhoto(chat_id: message.chat.id,
                                photo: Faraday::UploadIO.new(
                                  "/home/cloud-user/witcher-bot/witcher-bot/telegram//memes/#{meme}", 'image/jpg'
                                ))
            when '/subscription', "\xF0\x9F\x92\xB3 Абонемент \xF0\x9F\x92\xB3"
              if user.passport_id.nil?
                bot.api.send_message(chat_id: message.chat.id,
                                     text: 'Похоже к вам еще не привязан паспорт, используйте кнопку Получить свой паспорт')
              elsif Passport.find_by(id: user.passport_id).subscription.to_i >= 500
                bot.api.send_message(chat_id: message.chat.id,
                                     text: "\xF0\x9F\x8E\x89 Поздравляю! \xF0\x9F\x8E\x89\nТы блатной")
              else
                sale_markup_buttons = [
                  Telegram::Bot::Types::InlineKeyboardButton.new(text: 'Хочу 30%', url: 'tg://user?id=612352098')
                ]
                sale_markup = Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: sale_markup_buttons)
                subscription = Passport.find_by(id: user.passport_id).subscription
                debt = Passport.find_by(id: user.passport_id).debt
                subs_message = "\xF0\x9F\x92\xB3 Абонемент: "
                if subscription.positive?
                  subs_message += "Осталось #{Passport.find_by(id: user.passport_id).subscription} посещений(я)"
                else
                  subs_message += "Кажется у вас нет абонемента.\n Внизу есть кнопочка чтобы получить скидку в 30%, только \xF0\x9F\xA4\xAB"
                end
                subs_message += "\n\xF0\x9F\x92\xB0 Долг: "
                subs_message += if debt.positive?
                                  "#{debt}р"
                                else
                                  "Кажется у вас нет долгов, так держать! \xF0\x9F\x8E\x89"
                                end
                bot.api.send_message(chat_id: message.chat.id, text: subs_message, reply_markup: sale_markup)
              end
            when '/substract', 'Списать занятия'
              bot.api.send_message(chat_id: message.chat.id, text: 'Выберите тех, кто был на тренировке')
              passports = Passport.all
              passports_message = ''
              passports.map do |passport|
                passports_message += "#{passport.id}: #{passport.nickname}\n"
              end
              bot.api.send_message(chat_id: message.chat.id, text: passports_message)
              user.update(step: 'input_substract')
            when '/subscription_info', 'Информация по игроку'
              bot.api.send_message(chat_id: message.chat.id, text: 'Выберите паспорт', reply_markup: cancel_markup)
              passports = Passport.all
              passports_message = ''
              passports.map do |passport|
                passports_message += "#{passport.id}: #{passport.nickname}\n"
              end
              bot.api.send_message(chat_id: message.chat.id, text: passports_message)
              user.update(step: 'input_abon_info')
            when 'Информация по всем абонементам'
              passports = Passport.all
              passports_message = ''
              passports.map do |passport|
                if passport.subscription.to_i < 1000
                  passports_message += "#{passport.nickname}: #{passport.subscription}\n"
                end
              end
              bot.api.send_message(chat_id: message.chat.id, text: passports_message)
            when 'Открыть предзапись'
              (Prerecording.last || Prerecording.create).update(closed: false)
              bot.api.send_message(chat_id: message.chat.id, text: 'Введите сообщение')
              user.update(step: 'input_vote_message')
            when 'Закрыть предзапись'
              Prerecording.last.update(closed: true)
              available_records = {}
              Prerecording.last.choosed_options.split(',') { |l| available_records[l] = 10 }
              # @choosed_options.each { |l| available_records[l] = 10 }
              close_message = ''
              # @choosed_options.each_with_index do |option, i|
              Prerecording.last.choosed_options.split(',').each_with_index do |option, i|
                option_prerecord = UserPrerecording.where('days LIKE ?', "%#{i}%")
                option_prerecord.each { |_prer| available_records[option] -= 1 }
                close_message += option + "\n\n" + (option_prerecord.map do |pr|
                                                      Passport.find(pr.passport_id).nickname
                                                    end).join("\n")
                close_message += "\n\n"
              end
              UserPrerecording.all.each do |pr|
                bot.api.send_message(
                  chat_id: User.find_by(passport_id: pr.passport_id).telegram_id, text: 'Предзапись закрыта'
                )
              end
              output_string = ''
              available_records.each { |l| output_string += "#{l[0]}: #{l[1]}\n" }
              main_admins_ids.each do |id|
                bot.api.send_message(chat_id: id, text: close_message)
                bot.api.send_message(chat_id: id, text: "Количество свободных мест:\n#{output_string}")
              end
              UserPrerecording.update_all(days: '', message_id: nil)
            when '/remove'
              reply_markup = user.admin ? admin_markup : remove_keyboard
              reply_markup = hamon_markup if user.telegram_id == 448_768_896
              bot.api.send_message(chat_id: message.chat.id, text: 'Кнопки убраны)', reply_markup: reply_markup)
            when '/birthdays'
              bot.api.send_message(chat_id: message.chat.id, text: 'Список дней рождений на текущий месяц:')
              birthday_message = ''
              Passport.where("bd like '%.#{format('%02i', DateTime.now.month)}%'").each do |passport|
                bd_array = passport.bd.split('.')
                birthday_message += "#{passport.nickname}: #{bd_array[0]}.#{bd_array[1]}\n"
              end
              bot.api.send_message(chat_id: message.chat.id, text: birthday_message)
            when '/feedback'
              bot.api.send_message(chat_id: message.chat.id,
                                   text: 'Тут можно оставить свои отзывы и пожелания по нашему клубу, ' \
                'пожелания по будующему функционалу бота, ну и так далее, '\
                'сообщение можно отправить как с подписью так и анонимно', reply_markup: feedback_markup)
              user.update(step: 'choose_user_visibility')
            when 'Изменить описание'
              passports = Passport.all
              passports_message = ''
              passports.map do |passport|
                passports_message += "#{passport.id}: #{passport.nickname}\n"
              end
              bot.api.send_message(chat_id: message.chat.id, text: passports_message.to_s)
              bot.api.send_message(chat_id: message.chat.id,
                                   text: 'Жги, выбирай кому поменять описание, вводи циферку')
              user.update(step: 'input_descr_passport')
            end
          # when "input_meme"
          #   file_info = bot.api.getFile(file_id: message.document.file_id)
          #   # https://api.telegram.org/file/bot#{token}/#{file_info.file_path}
          #   # url = URI("https://api.telegram.org/file/bot#{token}/#{file_info["result"]["file_path"]}")

          #   # http = Net::HTTP.new(url.host, url.port)
          #   # http.use_ssl = true

          #   # request = Net::HTTP::Get.new(url)
          #   # # request.body = "{'file_id': '#{message.document.file_id}'}"

          #   # response = http.request(request)
          #   # File.open(response.body, 'w')
          #   # bot.api.sendPhoto(chat_id: message.chat.id, photo: file)
          #   # p file

          #   url = URI("https://api.telegram.org/file/bot#{token}/#{file_info["result"]["file_path"]}")
          #   http = Net::HTTP.new(url.host, url.port)
          #   http.use_ssl = true

          #   request = Net::HTTP::Get.new(url)
          #   response = http.request(request)
          #   file = response.read_body.read
          #   IO.copy_stream(response.read_body, '~/image.png')
          #   # file = # https://api.telegram.org/file/bot<token>/<file_path>
          #   bot.api.sendPhoto(chat_id: message.chat.id, photo: file)
          #   user.update(:step => nil)
          when 'input_name'
            witcher_name = message.text
            bot.api.send_message(chat_id: message.chat.id, text: 'Введите школу:')
            user.update(step: 'input_school')
          when 'input_school'
            school = message.text
            passport = Passport.create(nickname: witcher_name, crons: 0, school: school,
              level: 0, rank: 'Рекрут', additional_kvest: 0, description: 'Отсутствует',
              elixirs: 'Нет')
          #  bot.api.send_message(chat_id: message.chat.id, text: 'Введите ранг')
          #  user.update(step: 'nil')
          # when 'input_rank'
          #   rank = message.text
          #   bot.api.send_message(chat_id: message.chat.id,
          #                        text: 'Есть ли у будующего ведьмака доп квест(Введите количество, 0 если их нет):')
          #   user.update(step: 'input_additional_kvest')
          # when 'input_additional_kvest'
          #   additional_kvest_info = message.text.downcase
          #   additional_kvest = 0 if yes.include?(additional_kvest_info)
          #   bot.api.send_message(chat_id: message.chat.id, text: 'Введите эликсиры (Нет если эликсиры отстутствуют):')
          #   user.update(step: 'input_elixirs')
          # when 'input_elixirs'
          #   elixirs = message.text
          #   bot.api.send_message(chat_id: message.chat.id, text: 'Введите описание:')
          #   user.update(step: 'input_description')
          # when 'input_description'
          #  description = message.text
            
            bot.api.send_message(chat_id: message.chat.id, text: 'Введите ник пользователя в телеграмм')
            user.update(step: 'input_telegram_nick')
          when 'input_telegram_nick'
            telegram_nick = message.text
            passport.update(telegram_nick: telegram_nick)
            update_user = User.find_by(username: telegram_nick)
            update_user&.update(passport_id: passport.id)
            bot.api.send_message(chat_id: message.chat.id, text: 'Запись создана')
            user.update(step: nil)
          when 'change_user_description'
            description = message.text
            Passport.find_by(user_id: user.passport_id).update(description: description)
            bot.api.send_message(chat_id: message.chat.id, text: 'Описание успешно обновлено')
            user.update(step: nil)
          when 'input_kvest_name'
            kvest_name = message.text
            bot.api.send_message(chat_id: message.chat.id, text: 'Введите количество крон:')
            user.update(step: 'input_crons_reward')
          when 'input_crons_reward'
            crons_reward = message.text
            bot.api.send_message(chat_id: message.chat.id,
                                 text: 'Введите количество уровней, получаемых за выполнение квеста:')
            user.update(step: 'input_level_reward')
          when 'input_level_reward'
            level_reward = message.text
            bot.api.send_message(chat_id: message.chatavailable_recordsid, text: 'Введите получаемый титул:')
            user.update(step: 'input_title_reward')
          when 'input_title_reward'
            title_reward = message.text
            if title_reward != 'Нет' && !Title.find_by(title_name: title_reward) && !Title.find_by(title_name: title_reward)
              Title.create(title_name: title_reward,
                           description: "Выдается за выполнение квеста #{kvest_name}")
            end
            bot.api.send_message(chat_id: message.chat.id, text: 'Введите дополнительную награду:')
            user.update(step: 'input_additional_reward')
          when 'input_additional_reward'
            additional_reward = message.text
            title_reward_kvest = nil
            title_reward_kvest = Title.find_by(title_name: title_reward).id unless title_reward == 'Нет'
            kvest = Kvest.create!(kvest_name: kvest_name, crons_reward: crons_reward, level_reward: level_reward, title_id: title_reward_kvest,
                                  additional_reward: additional_reward)
            bot.api.send_message(chat_id: message.chat.id, text: 'Квест успешно создан')
            user.update(step: nil)
          when 'input_passport_number'
            passport_number = message.text
            kvests = Kvest.all
            kvests_message = ''
            kvests.map do |kvest|
              kvests_message += "#{kvest.id}: #{kvest.kvest_name}\n"
            end
            bot.api.send_message(chat_id: message.chat.id, text: kvests_message)
            bot.api.send_message(chat_id: message.chat.id, text: 'Введите номер(а) выполненного квеста')
            user.update(step: 'input_kvest_number')
          when 'input_kvest_number'
            kvest_number = message.text
            kvests_number = kvest_number.split(' ')
            passports_number = passport_number.split(' ')
            passports_number.map do |pass_number|
              passport = Passport.find_by(id: pass_number)
              next unless passport

              kvests_number.map do |number|
                kvest = Kvest.find_by(id: number)
                next unless kvest

                new_crons = kvest.crons_reward + passport.crons
                new_level = kvest.level_reward + passport.level
                passport.update(crons: new_crons, level: new_level)
                passport.titles << Title.find_by(id: kvest.title_id) unless kvest.title_id.nil?
                if kvest.additional_reward != 'Нет'
                  passport.update(inventory: passport.inventory + kvest.additional_reward)
                end
                passport.update(inventory: "#{passport.inventory}\n") if kvest.additional_reward != 'Нет'
                passport.kvests << kvest
                bot.api.send_message(chat_id: message.chat.id,
                                     text: "Квест #{kvest.kvest_name} успешно выполнен игроком #{passport.nickname}")
              end
            end
            user.update(step: nil)
          when 'input_title_name'
            title_name = message.text
            bot.api.send_message(chat_id: message.chat.id, text: 'Введите описание титула')
            user.update(step: 'input_title_description')
          when 'input_title_description'
            title_description = message.text
            Title.create(title_name: title_reward, description: title_description)
            bot.api.send_message(chat_id: message.chat.id, text: "Титул #{title_name} создан")
            user.update(step: nil)
          when 'change_history'
            if message.text == 'Отмена'
              reply_markup = user.admin ? admin_markup : remove_keyboard
              bot.api.send_message(chat_id: message.chat.id, text: 'История не изменена', reply_markup: reply_markup)
            else
              history = message.text
              passport = Passport.find_by(id: user.passport_id).update(history: history)
              reply_markup = user.admin ? admin_markup : remove_keyboard
              bot.api.send_message(chat_id: message.chat.id, text: 'История обновлена', reply_markup: reply_markup)
            end
            user.update(step: nil)
          when 'update_field'
            bot.api.send_message(chat_id: message.chat.id, text: 'Выберите запись для изменения')
            case message.text.to_i
            when 1
              users = User.all
              users_message = ''
              users.map do |user|
                users_message += "#{user.id} - #{user.username}\n"
              end
              bot.api.send_message(chat_id: message.chat.id, text: users_message)
              active_table = User
            when 2
              passports = Passport.all
              passports_message = ''
              passports.map do |passport|
                passports_message += "#{passport.id} - #{passport.nickname}\n"
              end
              bot.api.send_message(chat_id: message.chat.id, text: passports_message)
              active_table = Passport
            when 3
              kvests = Kvest.all
              kvests_message = ''
              kvests.map do |kvest|
                kvests_message += "#{kvest.id} - #{kvest.kvest_name}\n"
              end
              bot.api.send_message(chat_id: message.chat.id, text: kvests_message)
              active_table = Kvest
            when 4
              titles = Title.all
              titles_message = ''
              titles.map do |title|
                titles_message += "#{title.id} - #{title.title_name}\n"
              end
              bot.api.send_message(chat_id: message.chat.id, text: titles_message)
              active_table = Title
            else
              bot.api.send_message(chat_id: message.chat.id, text: 'Неверный ввод, повторите команду снова')
              user.update(step: nil)
            end
            user.update(step: 'choose_record')
          when 'choose_record'
            id = message.text
            record_message = ''
            record = active_table.find_by(id: id)
            if record.nil?
              bot.api.send_message(chat_id: message.chat.id, text: 'Неверный ввод, повторите команду снова')
              user.update(step: nil)
            else
              record.attributes.each do |k, v|
                record_message += "#{k} - #{v}\n" unless %w[created_at updated_at id].include?(k)
                field_array.append(k)
              end
              bot.api.send_message(chat_id: message.chat.id, text: record_message)
              bot.api.send_message(chat_id: message.chat.id, text: 'Выберите поле для изменения')
              user.update(step: 'choose_field')
            end
          when 'choose_field'
            field = message.text
            if field_array.include?(field)
              bot.api.send_message(chat_id: message.chat.id, text: 'Введите новое значение для поля')
              user.update(step: 'update_field_value')
            else
              bot.api.send_message(chat_id: message.chat.id, text: 'Неверный ввод, повторите команду снова')
              user.update(step: nil)
            end
          when 'update_field_value'
            value = message.text
            record.update("#{field}": value)
            bot.api.send_message(chat_id: message.chat.id, text: 'Запись обновлена')
            user.update(step: nil)
          when 'input_pasport_title'
            passport_id = message.text
            titles = Title.all
            titles_message = ''
            titles.map do |title|
              titles_message += "#{title.id} - #{title.title_name}\n"
            end
            bot.api.send_message(chat_id: message.chat.id, text: titles_message)
            bot.api.send_message(chat_id: message.chat.id, text: 'Выберите титул')
            user.update(step: 'choose_title')
          when 'choose_title'
            title_id = message.text
            if Title.find_by(id: title_id)
              if Passport.find_by(id: passport_id).titles.include? Title.find_by(id: title_id)
                bot.api.send_message(chat_id: message.chat.id, text: 'Титул уже назначен пользователю')
              else
                Passport.find_by(id: passport_id).titles << Title.find_by(id: title_id)
                bot.api.send_message(chat_id: message.chat.id, text: 'Титул назначен')
              end
            else
              bot.api.send_message(chat_id: message.chat.id, text: 'Неверный ввод, повторите команду снова')
            end
            user.update(step: nil)
          when 'input_main_title'
            id = message.text
            if Title.find_by(id: id).nil?
              bot.api.send_message(chat_id: message.chat.id, text: 'Неверный ввод, повторите команду снова')
            else
              Passport.find_by(id: user.passport_id).update(main_title_id: id)
              bot.api.send_message(chat_id: message.chat.id, text: 'Основной титул установлен')
            end
            user.update(step: nil)
          when 'input_substract'
            passports_number = message.text.split(' ')
            passports_number.map do |pass_number|
              passport = Passport.find_by(id: pass_number)
              next unless passport

              passport.update(subscription: passport.subscription - 1)
              if passport.subscription <= 3 && passport.subscription != 0
                bot.api.send_message(chat_id: User.find_by(passport_id: passport.id).telegram_id,
                                     text: "У вас осталось #{passport.subscription} занятий в абонементе")
              elsif passport.subscription.zero?
                bot.api.send_message(chat_id: 612_352_098,
                                     text: "\xE2\x9A\xA0\xEF\xB8\x8F У #{passport.nickname} закончился абонемент \xE2\x9A\xA0\xEF\xB8\x8F")
                bot.api.send_message(chat_id: User.find_by(passport_id: passport.id).telegram_id,
                                     text: "Ваш абонемент закончился \xF0\x9F\x98\xA2\nБегом за новым \xF0\x9F\x8F\x83")
              end
            end
            bot.api.send_message(chat_id: message.chat.id, text: 'Занятия вычтены')
            user.update(step: nil)
          when 'input_bd'
            bd = message.text
            Passport.find_by(id: user.passport_id).update(bd: bd)
            user.update(step: 'input_mail')
            bot.api.send_message(chat_id: message.chat.id, text: 'Введите адрес электронной почты:')
          when 'input_mail'
            mail = message.text
            Passport.find_by(id: user.passport_id).update(mail: mail)
            user.update(step: 'input_number')
            bot.api.send_message(chat_id: message.chat.id, text: 'Введите номер:')
          when 'input_number'
            number = message.text
            Passport.find_by(id: user.passport_id).update(number: number)
            bot.api.send_message(chat_id: message.chat.id,
                                 text: output_passport(user.passport_id, message.chat.id, bot), reply_markup: passport_markup)
            user.update(step: nil)
          when 'input_player_passport_number'
            number = message.text
            if Passport.find_by(id: number).nil?
              bot.api.send_message(chat_id: message.chat.id, text: 'Некорректный ввод, повторите команду')
            else
              bot.api.send_message(chat_id: message.chat.id, text: output_passport(number, message.chat.id, bot),
                                   reply_markup: passport_markup)
            end
            user.update(step: nil)
          when 'input_abon_info'
            number = message.text
            reply_markup = user.admin ? admin_markup : remove_keyboard
            if number == 'Отмена'
              bot.api.send_message(chat_id: message.chat.id, text: 'Действие отменено', reply_markup: reply_markup)
              user.update(step: nil)
            else
              passport = Passport.find_by(id: number)
              if passport.nil?
                bot.api.send_message(chat_id: message.chat.id, text: 'Некорректный ввод, повторите команду',
                                     reply_markup: reply_markup)
              else
                bot.api.send_message(chat_id: message.chat.id,
                                     text: "Имя: #{passport.nickname}\nДень рождения: #{passport.bd}\nНомер телефона: #{passport.number}\nОстаток абонемента: #{passport.subscription}\nДолг:#{passport.debt}", reply_markup: reply_markup)
              end
            end
            user.update(step: nil)
          when 'input_change_info_field'
            info_number = message.text
            if info_number == 'Отмена'
              reply_markup = user.admin ? admin_markup : remove_keyboard
              bot.api.send_message(chat_id: message.chat.id, text: 'Действие отменено', reply_markup: reply_markup)
              user.update(step: nil)
            else
              info_message = ''
              case info_number
              when '1'
                update_field = 'bd'
                info_message = 'даты рождения'
              when '2'
                update_field = 'mail'
                info_message = 'почты'
              when '3'
                update_field = 'number'
                info_message = 'номера мобильного телефона'
              end
              if number in ['1', '2', '3']
                bot.api.send_message(chat_id: message.chat.id, text: 'Некорректный ввод, повторите команду')
                user.update(step: nil)
              else
                bot.api.send_message(chat_id: message.chat.id, text: "Введите новое значение для #{info_message}")
                user.update(step: 'input_info_value')
              end

            end
          when 'input_info_value'
            value = message.text
            Passport.find_by(id: user.passport_id).update(update_field => value)
            reply_markup = user.admin ? admin_markup : remove_keyboard
            bot.api.send_message(chat_id: message.chat.id, text: 'Значение обновлено', reply_markup: reply_markup)
            user.update(step: nil)
          when 'input_vote_message'
            @vote_message = message.text
            bot.api.send_poll(chat_id: message.chat.id,
                              question: 'Какие тренировки планируются?', allows_multiple_answers: true, options: options,
                              is_anonymous: false)
            user.update(step: nil)
          when 'input_descr_passport'
            id = message.text.to_i
            change_passport_h = Passport.find_by(id: id)
            bot.api.send_message(chat_id: message.chat.id, text: "Предыдущее описание: #{change_passport_h.description}\n" \
            'Введите новое описание:', reply_markup: cancel_markup)
            user.update(step: 'input_descr_h')
          when 'input_descr_h'
            description = message.text
            reply_markup = hamon_markup if user.telegram_id == 448_768_896
            if message.text == 'Отмена'
              reply_markup = user.admin ? admin_markup : remove_keyboard
              bot.api.send_message(chat_id: message.chat.id, text: 'Описание не изменено', reply_markup: reply_markup)
            else
              change_passport_h.update(description: description)
              bot.api.send_message(chat_id: message.chat.id, text: 'Описание изменено', reply_markup: reply_markup)
            end
            user.update(step: nil)
          when 'choose_user_visibility'
            @send_feedbacks_author = message.text
            bot.api.send_message(chat_id: message.chat.id, text: 'Введите ваш отзыв', reply_markup: reply_markup)
            user.update(step: 'enter_feedback')
          when 'enter_feedback'
            main_admins_ids.each do |id|
              if @send_feedbacks_author == 'Открыто'
                feedback = "Отзыв от #{Passport.find_by(id: user.passport_id).nickname}:\n\n"
              else
                feedback = "Отзыв от кого-то, кто пожелал остаться во мраке ночи:\n\n"
              end
              feedback += message.text
              bot.api.send_message(chat_id: id, text: feedback)
            end
            reply_markup = user.admin ? admin_markup : remove_keyboard
            reply_markup = hamon_markup if user.telegram_id == 448_768_896
            bot.api.send_message(chat_id: message.chat.id, text: 'Отзыв отправлен', reply_markup: reply_markup)
            user.update(step: nil)
          end
        end
      rescue StandardError
        bot.api.send_message(chat_id: message.chat.id,
                             text: 'Похоже возникла ошибка, проверьте правильность введенных данных и повторите ввод')
        user.update(step: nil)
      end
    end
  end
end
