# frozen_string_literal: true

require File.expand_path('../config/environment', __dir__)
require 'telegram/bot'
require 'json'

require 'uri'
require 'net/http'
require 'openssl'

Dir["./telegram/modules/*.rb"].each {|file| require file }
include BotHelper
include CreateTitle
include RankUp
include CompleteKvest

token = '5587814730:AAFci39iNXTgIeDLVTvKpCjULW2a94zbuP8'

tables = [User, Passport, Kvest, Title]

record = nil
field = nil
field_array = []

passport_id = nil

update_field = ''

options = %w[Пт Сб1 Сб2 Вс0 Вс1 Вс2]

cancel_kb = [
  Telegram::Bot::Types::KeyboardButton.new(text: 'Отмена')
]
cancel_markup = Telegram::Bot::Types::ReplyKeyboardMarkup.new(keyboard: cancel_kb, resize_keyboard: true)

admin_kb = [
  Telegram::Bot::Types::KeyboardButton.new(text: 'Создать паспорт'),
  Telegram::Bot::Types::KeyboardButton.new(text: 'Создать квест'),
  Telegram::Bot::Types::KeyboardButton.new(text: 'Создать титул'),
  Telegram::Bot::Types::KeyboardButton.new(text: 'Выполнить квест'),
  Telegram::Bot::Types::KeyboardButton.new(text: 'Назначить титул'),
  Telegram::Bot::Types::KeyboardButton.new(text: 'Изменить запись'),
  Telegram::Bot::Types::KeyboardButton.new(text: 'Списать занятия'),
  Telegram::Bot::Types::KeyboardButton.new(text: 'Начислить занятия'),
  Telegram::Bot::Types::KeyboardButton.new(text: 'Информация по игроку'),
  Telegram::Bot::Types::KeyboardButton.new(text: 'Информация по всем абонементам'),
  Telegram::Bot::Types::KeyboardButton.new(text: 'Списать кроны'),
  Telegram::Bot::Types::KeyboardButton.new(text: 'Повысить ранг'),
  Telegram::Bot::Types::KeyboardButton.new(text: 'Уведомление'),
  Telegram::Bot::Types::KeyboardButton.new(text: 'Провести турнир'),
  Telegram::Bot::Types::KeyboardButton.new(text: 'Открыть предзапись'),
  Telegram::Bot::Types::KeyboardButton.new(text: 'Закрыть предзапись')
]
@admin_markup = Telegram::Bot::Types::ReplyKeyboardMarkup.new(keyboard: admin_kb, resize_keyboard: true)

yes_no_kb = [
  Telegram::Bot::Types::KeyboardButton.new(text: 'Да'),
  Telegram::Bot::Types::KeyboardButton.new(text: 'Нет')
]

reward_types_kb = [
  Telegram::Bot::Types::KeyboardButton.new(text: 'Кроны'),
  Telegram::Bot::Types::KeyboardButton.new(text: 'Свитки повтора'),
  Telegram::Bot::Types::KeyboardButton.new(text: 'Свитки доп квеста')
]
reward_types_markup = Telegram::Bot::Types::ReplyKeyboardMarkup.new(keyboard: admin_kb, resize_keyboard: true)

passport_kb = [
  Telegram::Bot::Types::InlineKeyboardButton.new(text: 'Открыть инвентарь', callback_data: 'inventory')
]
passport_markup = Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: passport_kb)

hamon_kb = [
  Telegram::Bot::Types::KeyboardButton.new(text: 'Изменить описание')
]
@hamon_markup = Telegram::Bot::Types::ReplyKeyboardMarkup.new(keyboard: hamon_kb, resize_keyboard: true)

get_passport_kb = [
  Telegram::Bot::Types::InlineKeyboardButton.new(text: 'Открыть паспорт', callback_data: 'passport')
]
get_passport_markup = Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: get_passport_kb)

feedback_kb = [
  Telegram::Bot::Types::KeyboardButton.new(text: 'Анонимно'),
  Telegram::Bot::Types::KeyboardButton.new(text: 'Открыто'),
  Telegram::Bot::Types::KeyboardButton.new(text: 'Отмена')
]
feedback_markup = Telegram::Bot::Types::ReplyKeyboardMarkup.new(keyboard: feedback_kb, resize_keyboard: true)

@remove_keyboard = Telegram::Bot::Types::ReplyKeyboardRemove.new(remove_keyboard: true)

tournament_markup = [
  Telegram::Bot::Types::KeyboardButton.new(text: 'Случайное распределение пар'),
  Telegram::Bot::Types::KeyboardButton.new(text: 'Вручную')
]

main_admins_ids = [822_281_212, 612_352_098]

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

def get_pairs
  pair_list = ''
  pair_id_list = ''
  while members.length.positive?
    sample = members.sample
    pair1 = Passport.find(sample)
    members.delete(sample)
    if members.length.positive?
      sample = members.sample
      pair2 = Passport.find(sample)
      members.delete(sample)
      pair_list += "#{pair1.titles.find(pair1.main_title_id)} #{pair1.nickname}" \
      " - #{pair2.titles.find(pair2.main_title_id)} #{pair2.nickname} \n"
      pair_id_list += "#{pair1.id} #{pair2.id}\n"
    else
      pair_list += "#{pair1.titles.find(pair1.main_title_id)} #{pair1.nickname} \n"
    end
  end
  Tournament.last.update(pairs: pair_id_list)
end

def create_tournament_choise(pair)
  fight_order_kb = [
    Telegram::Bot::Types::KeyboardButton.new(text: pair[0]),
    Telegram::Bot::Types::KeyboardButton.new(text: pair[1])
  ]
  Telegram::Bot::Types::ReplyKeyboardMarkup.new(keyboard: fight_order_kb)
end

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
                                              question: 'Куда идем?', allows_multiple_answers: true,
                                              options: @choosed_options, is_anonymous: false)
          (UserPrerecording.find_by(passport_id: pass.id) || UserPrerecording.create(passport_id: pass.id))
            .update(message_id: poll_message_id)
        end
      elsif Prerecording.last.closed
        bot.api.send_message(chat_id: message.user.id, text: 'Предзапись уже закрыта, ждите дальнейших новостей')
      else
        UserPrerecording.find_by(passport_id: User.find_by(telegram_id: message.user.id).passport_id).update(days: message.option_ids.join(','))
      end
    when Telegram::Bot::Types::CallbackQuery
      case message.data
      when 'inventory'
        user = find_or_build_user(message.from)
        passport = user.passport
        inventory = passport.inventory
        inventory += "\n" unless passport.inventory.split("\n").empty?
        additional_kvest = ''
        unless passport.additional_kvest.zero?
          additional_kvest = "\xF0\x9F\x8E\x9F\xEF\xB8\x8F Специальные предметы:\nСвиток дополнительного " \
                             "квеста #{passport.additional_kvest} штук(и)\n\n"
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
                                  text: output_passport(user.passport, user.telegram_id),
                                  reply_markup: passport_markup)
      end
    when Telegram::Bot::Types::Message
      begin
        user = find_or_build_user(message.from)
        # if main_admins_ids.include?(user.telegram_id)
          unless message.text.nil? && !message.text.empty? # && message.document.nil?
            if message.text == 'Отмена'
              user.update(step: nil)
              return_buttons(user, bot, message.chat.id, 'Действие отменено')
            end
            case user.step
            when nil, 'start'
              case message.text
              when '/start', '/info'
                bot.api.send_message(chat_id: message.chat.id,
                                    text: "Привет, я бот клуба 'Свое Дело'!\nСписок моих команд находится внизу, "\
                                          "удачи \xE2\x9D\xA4")
              when '/passport'
                if user.passport_id.nil?
                  passport = Passport.find_by(telegram_nick: user.username)
                  if passport.nil?
                    bot.api.send_message(chat_id: message.chat.id,
                                        text: 'Кажется ваш паспорт еще не существует, обратитесь к Анри Виллу')
                  else
                    user.update(passport_id: passport.id)
                    user.update(step: 'input_bd')
                    bot.api.send_message(chat_id: message.chat.id,
                                        text: 'Мы нашли ваш паспорт, однако предварительно нужно собрать ' \
                                              "немного ифнормации о вас\nВведите дату рождения(формат 03.12):")
                  end
                elsif user.passport.bd.empty?
                  user.update(step: 'input_bd')
                  bot.api.send_message(chat_id: message.chat.id,
                                      text: 'Мы нашли ваш паспорт, однако предварительно нужно собрать ' \
                          "немного ифнормации о вас\nВведите дату рождения(формат 03.12):")
                else
                  bot.api.send_message(chat_id: message.chat.id,
                                      text: output_passport(user.passport_id, message.chat.id),
                                      reply_markup: passport_markup)
                end
              when '/get_best'
                passport = Passport.order(Arel.sql('CAST(level as integer) DESC')).first
                bot.api.send_message(chat_id: message.chat.id,
                                    text: "\xF0\x9F\x94\xA5 Паспорт лучшего игрока \xF0\x9F\x94\xA5")
                bot.api.send_message(chat_id: message.chat.id,
                                    text: output_passport(passport.id, message.chat.id))
              when '/get_history'
                if user.passport_id.nil?
                  bot.api.send_message(chat_id: message.chat.id,
                                      text: 'Похоже к вам еще не привязан паспорт, используйте кнопку ' \
                                            'Получить свой паспорт')
                else
                  history = user.passport.history
                  history = 'История вашего персонажа пуста' if history.empty?
                  bot.api.send_message(chat_id: message.chat.id, text: history)
                end
              when '/update_history'
                if user.passport_id.nil?
                  bot.api.send_message(chat_id: message.chat.id,
                                      text: 'Похоже к вам еще не привязан паспорт, используйте кнопку ' \
                                            'Получить свой паспорт')
                else
                  history = user.passport.history
                  if history.empty?
                    history = "История вашего персонажа пуста, самое время это исправить!\n" \
                              'Введите историю вашего персонажа'
                  end
                  bot.api.send_message(chat_id: message.chat.id, text: history)
                  bot.api.send_message(chat_id: message.chat.id, text: 'Введите новую историю',
                                      reply_markup: cancel_markup)
                  user.update(step: 'change_history')
                end
              when '/get_kvests'
                if user.passport_id.nil?
                  bot.api.send_message(chat_id: message.chat.id,
                                      text: 'Похоже к вам еще не привязан паспорт, используйте кнопку ' \
                                            'Получить свой паспорт')
                else
                  kvests = user.passport.kvests
                  message_kvests = "Выполненные квесты:\n\n"
                  kvests.each do |kvest|
                    message_kvests += "#{kvest['kvest_name']}\n"
                  end
                  bot.api.send_message(chat_id: message.chat.id, text: message_kvests)
                end
              when '/change_info'
                if user.passport_id.nil?
                  bot.api.send_message(chat_id: message.chat.id,
                                      text: 'Похоже к вам еще не привязан паспорт, используйте кнопку ' \
                                            'Получить свой паспорт')
                else
                  passport = user.passport
                  bot.api.send_message(chat_id: message.chat.id,
                                      text: "Личная информация:\n1. Дата рождения: #{passport.bd}\n2. Почта: #{passport.mail}\n3. Телефон: #{passport.number}")
                  bot.api.send_message(chat_id: message.chat.id,
                                      text: "Что нужно изменить?\n1. Дата рождения\n2. Почта\n3. Телефон\nВводите цифрой", reply_markup: cancel_markup)
                  user.update(step: 'input_change_info_field')
                end
              when '/birthdays'
                bot.api.send_message(chat_id: message.chat.id, text: 'Список дней рождений на следующие сорок дней:')
                birthday_message = ''
                Passport.all.select(:nickname, :bd).sort_by { |pass| pass.bd.split('.').reverse.join('.') }.each do |pass|
                  next if pass.bd.blank?

                  bd = pass.bd.split('.')
                  next unless (bd[0] > format('%02i',
                                              DateTime.now.day) && bd[1] == format('%02i',
                                                                                  DateTime.now.month)) || (bd[0] < format('%02i',
                                                                                                                          (DateTime.now + 40).day) && bd[1] == format(
                                                                                                                            '%02i', (DateTime.now + 40).month
                                                                                                                          ))

                  birthday_message += "#{pass.nickname}: #{bd[0]}.#{bd[1]}\n"
                end
                bot.api.send_message(chat_id: message.chat.id, text: birthday_message)
              when '/feedback'
                bot.api.send_message(chat_id: message.chat.id,
                                    text: 'Тут можно оставить свои отзывы и пожелания по нашему клубу, ' \
                  'пожелания по будующему функционалу бота, ну и так далее, '\
                  'сообщение можно отправить как с подписью так и анонимно', reply_markup: feedback_markup)
                user.update(step: 'choose_user_visibility')
              when '/choose_title'
                titles = user.passport.titles if user.passport_id
                if titles.nil? || titles.empty?
                  bot.api.send_message(chat_id: message.chat.id, text: 'Похоже у вас нет титулов')
                else
                  titles_message = ''
                  titles.map do |title|
                    titles_message += "#{title.id}: #{title.title_name}\n"
                  end
                  bot.api.send_message(chat_id: message.chat.id, text: titles_message)
                  bot.api.send_message(chat_id: message.chat.id, text: 'Выберите основной титул, вводите цифрой',
                                      reply_markup: cancel_markup)
                  user.update(step: 'input_main_title')
                end
              when '/get_player'
                output_all_passports(bot, message.chat.id)
                bot.api.send_message(chat_id: message.chat.id, text: 'Выберите номер паспорта игрока',
                                    reply_markup: cancel_markup)
                user.update(step: 'input_player_passport_number')
              when '/mem', "\xF0\x9F\xA4\xA1 Мемчик \xF0\x9F\xA4\xA1"
                meme = (Dir.entries('/home/cloud-user/witcher-bot/witcher-bot/telegram/memes').reject do |f|
                          File.directory? f
                        end).sample
                bot.api.sendPhoto(chat_id: message.chat.id,
                                  photo: Faraday::UploadIO.new(
                                    "/home/cloud-user/witcher-bot/witcher-bot/telegram//memes/#{meme}", 'image/jpg'
                                  ))
              when '/subscription'
                if user.passport_id.nil?
                  bot.api.send_message(chat_id: message.chat.id,
                                      text: 'Похоже к вам еще не привязан паспорт, используйте кнопку ' \
                                            'Получить свой паспорт')
                elsif user.passport.subscription.to_i >= 500
                  bot.api.send_message(chat_id: message.chat.id,
                                      text: "\xF0\x9F\x8E\x89 Поздравляю! \xF0\x9F\x8E\x89\nТы блатной")
                else
                  sale_markup_buttons = [
                    Telegram::Bot::Types::InlineKeyboardButton.new(text: 'Хочу 30%', url: 'tg://user?id=612352098')
                  ]
                  sale_markup = Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: sale_markup_buttons)
                  subscription = user.passport.subscription
                  debt = user.passport.debt
                  subs_message = "\xF0\x9F\x92\xB3 Абонемент: "
                  subs_message += if subscription != 0
                                    "Осталось #{subscription} посещений(я)"
                                  else
                                    "Кажется у вас нет абонемента.\n Внизу есть кнопочка чтобы получить скидку в 30%, " \
                                                    "только \xF0\x9F\xA4\xAB"
                                  end
                  subs_message += "\n\xF0\x9F\x92\xB0 Долг: "
                  subs_message += if debt.positive?
                                    "#{debt}р"
                                  else
                                    "Кажется у вас нет долгов, так держать! \xF0\x9F\x8E\x89"
                                  end
                  bot.api.send_message(chat_id: message.chat.id, text: subs_message, reply_markup: sale_markup)
                end
              when 'Создать паспорт'
                if user.admin
                  bot.api.send_message(chat_id: message.chat.id, text: 'Введите имя будующего ведьмака:',
                                      reply_markup: cancel_markup)
                  user.update(step: 'input_name')
                else
                  bot.api.send_message(chat_id: message.chat.id, text: 'Ты как сюда залез?)')
                end
              when 'Изменить запись'
                if user.admin
                  table_message = ''
                  tables.map.with_index do |table, i|
                    table_message += "#{i + 1}: #{table}\n".to_s
                  end
                  bot.api.send_message(chat_id: message.chat.id,
                                      text: "#{table_message}Выберите таблицу для изменения:",
                                      reply_markup: cancel_markup)
                  user.update(step: 'update_field')
                else
                  bot.api.send_message(chat_id: message.chat.id, text: 'Ты как сюда залез?)')
                end
              when 'Создать квест'
                if user.admin
                  bot.api.send_message(chat_id: message.chat.id, text: 'Введите название квеста:',
                                      reply_markup: cancel_markup)
                  user.update(step: 'input_kvest_name')
                else
                  bot.api.send_message(chat_id: message.chat.id, text: 'Ты как сюда залез?)')
                end
              when 'Выполнить квест'
                complete_kvest(message, bot, user, cancel_markup)
              when 'Создать титул'
                create_title(message, bot, user, cancel_markup)
              when 'Назначить титул'
                if user.admin
                  output_all_passports(bot, message.chat.id)
                  bot.api.send_message(chat_id: message.chat.id, text: 'Выберите номер паспорта игрока',
                                      reply_markup: cancel_markup)
                  user.update(step: 'input_pasport_title')
                else
                  bot.api.send_message(chat_id: message.chat.id, text: 'Ты как сюда залез?)')
                end
              when 'Списать занятия'
                if user.admin
                  output_all_passports(bot, message.chat.id)
                  bot.api.send_message(chat_id: message.chat.id, text: 'Выберите тех, кто был на тренировке',
                                      reply_markup: cancel_markup)
                  user.update(step: 'input_substract')
                else
                  bot.api.send_message(chat_id: message.chat.id, text: 'Ты как сюда залез?)')
                end
              when 'Информация по игроку'
                output_all_passports(bot, message.chat.id)
                bot.api.send_message(chat_id: message.chat.id, text: 'Выберите паспорт', reply_markup: cancel_markup)
                user.update(step: 'input_abon_info')
              when 'Информация по всем абонементам'
                if user.admin
                  passports = Passport.all
                  passports_message = ''
                  passports.map do |passport|
                    if passport.subscription.to_i < 1000
                      passports_message += "#{passport.nickname}: #{passport.subscription}\n"
                    end
                  end
                  bot.api.send_message(chat_id: message.chat.id, text: passports_message)
                else
                  bot.api.send_message(chat_id: message.chat.id, text: 'Ты как сюда залез?)')
                end
              when 'Провести турнир'
                if user.admin
                  bot.api.send_message(chat_id: message.chat.id, text: 'Введите тип награды',
                                      reply_markup: reward_types_markup)
                  user.update(step: 'input_tournament_reward_type')
                else
                  bot.api.send_message(chat_id: message.chat.id, text: 'Ты как сюда залез?)')
                end
              when 'Открыть предзапись'
                if user.admin
                  (Prerecording.last || Prerecording.create).update(closed: false)
                  bot.api.send_message(chat_id: message.chat.id, text: 'Введите сообщение', reply_markup: cancel_markup)
                  user.update(step: 'input_vote_message')
                else
                  bot.api.send_message(chat_id: message.chat.id, text: 'Ты как сюда залез?)')
                end
              when 'Закрыть предзапись'
                if user.admin
                  Prerecording.last.update(closed: true)
                  available_records = {}
                  Prerecording.last.choosed_options.split(',') { |l| available_records[l] = 10 }
                  close_message = ''
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
                  main_admins_ids.each do |admin|
                    bot.api.send_message(chat_id: admin, text: close_message)
                    bot.api.send_message(chat_id: admin, text: "Количество свободных мест:\n#{output_string}")
                  end
                  UserPrerecording.update_all(days: '', message_id: nil)
                else
                  bot.api.send_message(chat_id: message.chat.id, text: 'Ты как сюда залез?)')
                end
              when 'Списать кроны'
                if user.admin
                  output_all_passports(bot, message.chat.id)
                  bot.api.send_message(chat_id: message.chat.id, text: 'Кому спишем кроны?',
                                      reply_markup: cancel_markup)
                  user.update(step: 'input_crons_substract')
                else
                  bot.api.send_message(chat_id: message.chat.id, text: 'Ты как сюда залез?)')
                end
              when 'Начислить занятия'
                if user.admin
                  output_all_passports(bot, message.chat.id)
                  bot.api.send_message(chat_id: message.chat.id,
                                      text: 'Выберите того, кому необходимо начислить занятия',
                                      reply_markup: cancel_markup)
                  user.update(step: 'input_subscription_addition')
                else
                  bot.api.send_message(chat_id: message.chat.id, text: 'Ты как сюда залез?)')
                end
              when 'Повысить ранг'
                rank_up(message, bot, user, cancel_markup)
              when 'Уведомление'
                if user.admin
                  bot.api.send_message(chat_id: message.chat.id, text: 'Введите уведомление', reply_markup: cancel_markup)
                  user.update(step: 'input_notification')
                else
                  bot.api.send_message(chat_id: message.chat.id, text: 'Ты как сюда залез?)')
                end
              when '/remove'
                reply_markup = user.admin ? @admin_markup : @remove_keyboard
                reply_markup = @hamon_markup if user.telegram_id == 448_768_896
                bot.api.send_message(chat_id: message.chat.id, text: 'Кнопки убраны)', reply_markup: reply_markup)

              when 'Изменить описание'
                output_all_passports(bot, message.chat.id)
                bot.api.send_message(chat_id: message.chat.id,
                                    text: 'Жги, выбирай кому поменять описание, вводи циферку',
                                    reply_markup: cancel_markup)
                user.update(step: 'input_descr_passport')
              end
            when 'input_name'
              @witcher_name = message.text
              bot.api.send_message(chat_id: message.chat.id, text: 'Введите школу:')
              user.update(step: 'input_school')
            when 'input_school'
              school = message.text
              @passport = Passport.create(nickname: @witcher_name, crons: 0, school: school,
                                        level: 0, rank: 'Рекрут', additional_kvest: 0, description: 'Отсутствует',
                                        elixirs: 'Нет')
              bot.api.send_message(chat_id: message.chat.id, text: 'Введите ник пользователя в телеграмм')
              user.update(step: 'input_telegram_nick')
            when 'input_telegram_nick'
              telegram_nick = message.text
              @passport.update(telegram_nick: telegram_nick)
              new_user = User.find_by(username: telegram_nick)
              new_user.update(passport_id: @passport.id) unless new_user.nil?
              return_buttons(user, bot, message.chat.id, 'Запись создана')
              user.update(step: nil)
            when 'change_user_description'
              description = message.text
              user.passport.update(description: description)
              return_buttons(user, bot, message.chat.id, 'Описание успешно обновлено')
              user.update(step: nil)
            when 'input_kvest_name'
              @kvest_name = message.text
              bot.api.send_message(chat_id: message.chat.id, text: 'Введите количество крон:')
              user.update(step: 'input_crons_reward')
            when 'input_crons_reward'
              @crons_reward = message.text
              bot.api.send_message(chat_id: message.chat.id,
                                  text: 'Введите количество уровней, получаемых за выполнение квеста:')
              user.update(step: 'input_level_reward')
            when 'input_level_reward'
              @level_reward = message.text
              bot.api.send_message(chat_id: message.chat.id, text: 'Введите получаемый титул:')
              user.update(step: 'input_title_reward')
            when 'input_title_reward'
              @title_reward = message.text
              if title_reward != 'Нет' && !Title.find_by(title_name: @title_reward) && !Title.find_by(title_name: @title_reward)
                Title.create(title_name: @title_reward,
                            description: "Выдается за выполнение квеста #{@kvest_name}")
              end
              bot.api.send_message(chat_id: message.chat.id, text: 'Введите дополнительную награду:')
              user.update(step: 'input_additional_reward')
            when 'input_additional_reward'
              additional_reward = message.text
              title_reward_kvest = nil
              title_reward_kvest = Title.find_by(title_name: @title_reward).id unless @title_reward == 'Нет'
              kvest = Kvest.create!(kvest_name: @kvest_name, crons_reward: @crons_reward, level_reward: @level_reward,
                                    title_id: title_reward_kvest, additional_reward: additional_reward)
              return_buttons(user, bot, message.chat.id, 'Квест успешно создан')
              user.update(step: nil)
            when 'input_passport_number'
              @passport_number = input_passport_number(message, bot, user)
            when 'input_kvest_number'
              p message
              input_kvest_number(message, bot, user, @passport_number)
            when 'input_title_name'
              @title_name = input_title_name(message, bot, user)
            when 'input_title_description'
              input_title_description(message, bot, user, @title_name)
            when 'change_history'
              history = message.text
              user.passport.update(history: history)
              return_buttons(user, bot, message.chat.id, 'История обновлена')
              user.update(step: nil)
            when 'update_field'
              bot.api.send_message(chat_id: message.chat.id, text: 'Выберите запись для изменения')
              case message.text.to_i
              when 1
                users_message = ''
                User.all.map { |u| users_message += "#{u.id} - #{u.username}\n" }
                bot.api.send_message(chat_id: message.chat.id, text: users_message)
                @active_table = User
              when 2
                output_all_passports(bot, message.chat.id)
                @active_table = Passport
              when 3
                kvests_message = ''
                Kvest.all.map { |k| kvests_message += "#{k.id} - #{k.kvest_name}\n" }
                bot.api.send_message(chat_id: message.chat.id, text: kvests_message)
                @active_table = Kvest
              when 4
                titles_message = ''
                Title.all.map { |t| titles_message += "#{t.id} - #{t.title_name}\n" }
                bot.api.send_message(chat_id: message.chat.id, text: titles_message)
                @active_table = Title
              else
                return_buttons(user, bot, message.chat.id, 'Неверный ввод, повторите команду снова')
                user.update(step: nil)
              end
              user.update(step: 'choose_record')
            when 'choose_record'
              id = message.text
              record_message = ''
              record = @active_table.find_by(id: id)
              if record.nil?
                return_buttons(user, bot, message.chat.id, 'Неверный ввод, повторите команду снова')
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
                return_buttons(user, bot, message.chat.id, 'Неверный ввод, повторите команду снова')
                user.update(step: nil)
              end
            when 'update_field_value'
              value = message.text
              record.update("#{field}": value)
              return_buttons(user, bot, message.chat.id, 'Запись обновлена')
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
                return_buttons(user, bot, message.chat.id, 'Неверный ввод, повторите команду снова')
              end
              user.update(step: nil)
            when 'input_main_title'
              id = message.text
              if Title.find_by(id: id).nil?
                return_buttons(user, bot, message.chat.id, 'Неверный ввод, повторите команду снова')
              else
                user.passport.update(main_title_id: id)
                return_buttons(user, bot, message.chat.id, 'Основной титул установлен')
              end
              user.update(step: nil)
            when 'input_substract'
              passports_number = message.text.split(' ')
              passports_number.map do |pass_number|
                passport = Passport.find_by(id: pass_number)
                next unless passport

                passport.update(subscription: passport.subscription - 1)
                if passport.subscription <= 3 && passport.subscription != 0
                  unless User.find_by(passport_id: passport.id).nil?
                    bot.api.send_message(chat_id: User.find_by(passport_id: passport.id).telegram_id,
                                        text: "У вас осталось #{passport.subscription} занятий в абонементе")
                  end
                elsif passport.subscription.zero?
                  bot.api.send_message(chat_id: 612_352_098,
                                      text: "\xE2\x9A\xA0\xEF\xB8\x8F У #{passport.nickname} закончился абонемент \xE2\x9A\xA0\xEF\xB8\x8F")
                  bot.api.send_message(chat_id: User.find_by(passport_id: passport.id).telegram_id,
                                      text: "Ваш абонемент закончился \xF0\x9F\x98\xA2\nБегом за новым \xF0\x9F\x8F\x83")
                end
              end
              return_buttons(user, bot, message.chat.id, 'Занятия вычтены')
              user.update(step: nil)
            when 'input_bd'
              bd = message.text
              user.passport.update(bd: bd)
              user.update(step: 'input_mail')
              bot.api.send_message(chat_id: message.chat.id, text: 'Введите адрес электронной почты:')
            when 'input_mail'
              mail = message.text
              user.passport.update(mail: mail)
              user.update(step: 'input_number')
              bot.api.send_message(chat_id: message.chat.id, text: 'Введите номер:')
            when 'input_number'
              number = message.text
              user.passport.update(number: number)
              bot.api.send_message(chat_id: message.chat.id, text: output_passport(user.passport_id, message.chat.id),
                                  reply_markup: passport_markup)
              user.update(step: nil)
            when 'input_player_passport_number'
              number = message.text
              if Passport.find_by(id: number).nil?
                return_buttons(user, bot, message.chat.id, 'Некорректный ввод, повторите команду')
              else
                return_buttons(user, bot, message.chat.id, output_passport(number, message.chat.id))
              end
              user.update(step: nil)
            when 'input_abon_info'
              number = message.text
              passport = Passport.find_by(id: number)
              if passport.nil?
                return_buttons(user, bot, message.chat.id, 'Некорректный ввод, повторите команду')
              else
                return_buttons(user, bot, message.chat.id,
                              "Имя: #{passport.nickname}\nДень рождения: #{passport.bd}\nНомер телефона: " \
                              "#{passport.number}\nОстаток абонемента: #{passport.subscription}\nДолг:#{passport.debt}")
              end
              user.update(step: nil)
            when 'input_change_info_field'
              info_number = message.text
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
                return_buttons(user, bot, message.chat.id, 'Некорректный ввод, повторите команду')
                user.update(step: nil)
              else
                bot.api.send_message(chat_id: message.chat.id, text: "Введите новое значение для #{info_message}")
                user.update(step: 'input_info_value')
              end
            when 'input_info_value'
              value = message.text
              user.passport.update(update_field => value)
              return_buttons(user, bot, message.chat.id, 'Значение обновлено')
              user.update(step: nil)
            when 'input_vote_message'
              @vote_message = message.text
              bot.api.send_poll(chat_id: message.chat.id,
                                question: 'Какие тренировки планируются?', allows_multiple_answers: true, options: options,
                                is_anonymous: false)
              user.update(step: nil)
            when 'input_descr_passport'
              id = message.text.to_i
              @change_passport_h = Passport.find_by(id: id)
              bot.api.send_message(chat_id: message.chat.id,
                                  text: "Предыдущее описание: #{@change_passport_h.description}\n" \
              'Введите новое описание:', reply_markup: cancel_markup)
              user.update(step: 'input_descr_h')
            when 'input_descr_h'
              description = message.text
              reply_markup = @hamon_markup if user.telegram_id == 448_768_896
              @change_passport_h.update(description: description)
              bot.api.send_message(chat_id: message.chat.id, text: 'Описание изменено', reply_markup: reply_markup)
              user.update(step: nil)
            when 'choose_user_visibility'
              @send_feedbacks_author = message.text
              bot.api.send_message(chat_id: message.chat.id, text: 'Введите ваш отзыв', reply_markup: reply_markup)
              user.update(step: 'enter_feedback')
            when 'enter_feedback'
              main_admins_ids.each do |_admin|
                feedback = if @send_feedbacks_author == 'Открыто'
                            "Отзыв от #{user.passport.nickname}:\n\n"
                          else
                            "Отзыв от кого-то, кто пожелал остаться во мраке ночи:\n\n"
                          end
                feedback += message.text
                bot.api.send_message(chat_id: id, text: feedback)
              end
              return_buttons(user, bot, message.chat.id, 'Отзыв отправлен')
              user.update(step: nil)
            when 'input_crons_substract'
              @passport_id = message.text
              bot.api.send_message(chat_id: message.chat.id, text: 'Сколько?', reply_markup: cancel_markup)
              user.update(step: 'substract_crons')
            when 'substract_crons'
              @crons = message.text
              passport = Passport.find(@passport_id)
              passport.update(crons: passport.crons - @crons.to_i)
              return_buttons(user, bot, message.chat.id, 'Кроны списаны')
              user.update(step: nil)
            when 'input_subscription_addition'
              @passport_id = message.text
              bot.api.send_message(chat_id: message.chat.id, text: 'Сколько?', reply_markup: cancel_markup)
              user.update(step: 'add_subscription')
            when 'add_subscription'
              @value = message.text
              passport = Passport.find(@passport_id)
              passport.update(subscription: passport.subscription + @value.to_i)
              return_buttons(user, bot, message.chat.id, 'Занятия начислены')
              unless User.find_by(passport_id: passport.id).nil?
                bot.api.send_message(chat_id: User.find_by(passport_id: passport.id).telegram_id,
                                    text: "Вам начислено #{@value} занятия(ий)")
              end
              user.update(step: nil)
            when 'input_passport_rank'
              input_passport_rank(message, bot, user)
            when 'input_notification'
              User.all.each { |u| bot.api.send_message(chat_id: u.telegram_id, text: message.text) }
              return_buttons(user, bot, message.chat.id, 'Сообщение отправлено')
              user.update(step: nil)
              # when 'input_tournament_reward_type'
              #   @reward_type = message.text
              #   bot.api.send_message(chat_id: message.chat.id, text: 'Сколько?', reply_markup: cancel_markup)
              #   user.update(step: 'input_reward_count')
              # when 'input_reward_count'
              #   @reward_count = message.text
              #   if @tournament.nil?
              #     @tournament = Tournament.create(@reward_type: @reward_count)
              #   else
              #     Tournament.last.update(@reward_type: @reward_count)
              #   end
              #   bot.api.send_message(chat_id: message.chat.id, text: 'Еще награды?', reply_markup: yes_no_kb)
              #   user.update(step: 'input_reward_repeat')
              # when 'input_reward_repeat'
              #   if message.text == 'Да'
              #     bot.api.send_message(chat_id: message.chat.id, text: 'Введите тип награды', reply_markup: reward_types_markup)
              #     user.update(:step => 'input_tournament_reward_type')
              #   else
              #     bot.api.send_message(chat_id: message.chat.id, text: 'Введите участников турнира', reply_markup: cancel_markup)
              #     output_all_passports(bot, message.chat.id)
              #     user.update(:step => 'input_tournament_members')
              #   end
              # when 'input_tournament_members'
              #   Tournament.last.update(:members => message.text)
              #   Tournament.last.members.each { |id|  bot.api.send_message(chat_id: User.find_by(:passport_id => id).telegram_id, text: 'Вы участник турнира, приготовьтесь!')}
              #   bot.api.send_message(chat_id: message.chat.id, text: 'Выберите распредление участников', reply_markup: tournament_markup)
              #   user.update('input_distribution')
              # when 'input_distribution'
              #   members = Tournament.last.members
              #   if message.text == 'Случайное распределение пар'
              #     pairs_list = ''
              #     pair_id_list = ''
              #     while members.length.positive?
              #       sample = members.sample
              #       pair1 = Passport.find(sample)
              #       members.delete(sample)
              #       if members.length > 0
              #         sample = members.sample
              #         pair2 = Passport.find(sample)
              #         members.delete(sample)
              #         pair_list += "#{pair1.titles.find(pair1.main_title_id)} #{pair1.nickname}" \
              #         " - #{pair2.titles.find(pair2.main_title_id)} #{pair2.nickname} \n"
              #         pair_id_list += "#{pair1.id} #{pair2.id}\n"
              #       else
              #         pair_list += "#{pair1.titles.find(pair1.main_title_id)} #{pair1.nickname} \n"
              #       end
              #     end
              #     Tournament.last.update(:pairs => pair_id_list)
              #     Tournament.last.members.split(' ').each do |member|
              #       bot.api.send_message(chat_id: User.find_by(:passport_id => member).telegram_id, text: "Список пар: ")
              #       bot.api.send_message(chat_id: User.find_by(:passport_id => member).telegram_id, text: pair_list)
              #       @pair = pair_id_list.split('\n')[0].split(' ')
              #       @pair[0] = @pair[0] + ":" + Passport.find(@pair[0]).nickname
              #       @pair[1] = @pair[1] + ":" + Passport.find(@pair[1]).nickname
              #       User.find_by(:passport_id => member).update(:step => 'fights') if pair.include?(member)
              #     end
              #   else
              #     # TODO write user pairs creation
              #   end
              #   #TODO do something with buttons
              #   create_tournament_choise(@pair)
              #   bot.api.send_message(chat_id: message.chat.id, text: 'Введите победителя')
              #   user.update('fight_winner')
              # when 'fight_winner'
              #   Tournament.last.update(:pairs => Tournament.last.pairs.split("\n").drop(1).join("\n"))
              #   loser = message.text  # Find id of loser
              #   members = Tournament.last.members
              #   members.split(" ").delete(loser)
              #   Tournament.last.update(members: members.join(" "))
              #   if members.length == 1
              #     user.update(:step => nil)
              #   else
              #     get_pairs() if Tournament.last.pairs.empty?
              #     bot.api.send_message(chat_id: message.chat.id, text: 'Введите победителя', reply_markup: create_tournament_choise(Tournament.last.pairs.split("\n")[0]))
              #   end
              # when 'fights'
              # fight_order_kb = [
              #   Telegram::Bot::Types::KeyboardButton.new(text: Tournament.last.pairs.split("\n")[Tournament.last.iteration]),
              #   Telegram::Bot::Types::KeyboardButton.new(text: 'Отмена')
              # ]
              # feedback_markup = Telegram::Bot::Types::ReplyKeyboardMarkup.new(keyboard: feedback_kb, resize_keyboard: true)
              # Tournament.last.members.split(' ').excluding().each do |member|
              #   bot.api.send_message(chat_id: User.find_by(:passport_id => member).telegram_id, text: "Ваша ставка," \
              #   "на кого и сколько (обязательная ставка 1 крона, в случае отсутствия выбора, ИИ этого крутого бота сделает все за вас)?")
              #   bot.api.send_message(chat_id: User.find_by(:passport_id => member).telegram_id, text: pair_list)
              # end
            end
          end
        # else
        #   bot.api.send_message(chat_id: message.chat.id,
        #                             text: "Ведутся работы, пожалуйста подождите")
        # end
      rescue StandardError
        return_buttons(user, bot, message.chat.id,
                       'Похоже возникла ошибка, проверьте правильность введенных данных и повторите ввод')
        user.update(step: nil)
      end
    end
  end
end
