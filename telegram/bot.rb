# frozen_string_literal: true

require File.expand_path('../config/environment', __dir__)
require 'telegram/bot'
require 'json'

export = %w[AccrueVisitings AssignTitle BotHelper ChangeRecord CreateTitle CompleteKvest RankUp
            SubscriptionInfo SubstractCrons SubstractVisitings CreateKvest]
export_for_user = %w[GetPassport GetSubscription UpdateHistory ChangeInfo LeaveFeedback GetPlayer
                     Birthdays ChooseTitle ChangeDescription]

['./telegram/modules/*.rb', './telegram/modules/user_modules/*.rb'].each { |p| Dir[p].each { |f| require f } }
export.each { |m| include(Kernel.const_get(m)) }
export_for_user.each { |m| include(Kernel.const_get(m)) }

token = '5587814730:AAFci39iNXTgIeDLVTvKpCjULW2a94zbuP8'

cancel_markup = Telegram::Bot::Types::ReplyKeyboardMarkup.new(keyboard: [
                                                                Telegram::Bot::Types::KeyboardButton.new(text: 'Отмена')
                                                              ], resize_keyboard: true)

@admin_markup = Telegram::Bot::Types::ReplyKeyboardMarkup.new(keyboard: [
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
                                                             ], resize_keyboard: true)

passport_markup = Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: [
                                                                   Telegram::Bot::Types::InlineKeyboardButton.new(
                                                                     text: 'Открыть инвентарь', callback_data: 'inventory'
                                                                   )
                                                                 ])

@hamon_markup = Telegram::Bot::Types::ReplyKeyboardMarkup.new(keyboard: [
                                                               Telegram::Bot::Types::KeyboardButton.new(text: 'Изменить описание')
                                                             ], resize_keyboard: true)

get_passport_markup = Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: [
                                                                       Telegram::Bot::Types::InlineKeyboardButton.new(
                                                                         text: 'Открыть паспорт', callback_data: 'passport'
                                                                       )
                                                                     ])

feedback_markup = Telegram::Bot::Types::ReplyKeyboardMarkup.new(keyboard: [
                                                                  Telegram::Bot::Types::KeyboardButton.new(text: 'Анонимно'),
                                                                  Telegram::Bot::Types::KeyboardButton.new(text: 'Открыто'),
                                                                  Telegram::Bot::Types::KeyboardButton.new(text: 'Отмена')
                                                                ], resize_keyboard: true)

@remove_keyboard = Telegram::Bot::Types::ReplyKeyboardRemove.new(remove_keyboard: true)

Telegram::Bot::Client.run(token) do |bot|
  Sidekiq::Cron::Job.create(
    name: 'BirthdayCheck',
    cron: '00 12 * * * Europe/Minsk',
    class: 'BirthdayCheckWorker'
  )

  bot.listen do |message|
    case message
    when Telegram::Bot::Types::PollAnswer
      if user.step == 'create_prerecording'
        create_prerecording(message, bot, user, @vote_message)
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
                                  text: output_passport(user.passport_id, user), reply_markup: passport_markup)
      end
    when Telegram::Bot::Types::Message
      begin
        user = find_or_build_user(message.from)
        # if [822_281_212, 612_352_098].include?(user.telegram_id)
        unless message.text.nil? && !message.text.empty? # && message.document.nil?
          return_buttons(user, bot, message.chat.id, 'Действие отменено') if message.text == 'Отмена'
          case user.step
          when nil, 'start'
            case message.text
            when '/start', '/info'
              bot.api.send_message(chat_id: message.chat.id,
                                  text: "Привет, я бот клуба 'Свое Дело'!\nСписок моих команд находится внизу, "\
                                        "удачи \xE2\x9D\xA4")
            when '/passport'
              get_passport(message, bot, user, passport_markup)
            when '/get_best'
              passport = Passport.order(Arel.sql('CAST(level as integer) DESC')).first
              bot.api.send_message(chat_id: message.chat.id,
                                  text: "\xF0\x9F\x94\xA5 Паспорт лучшего игрока \xF0\x9F\x94\xA5")
              bot.api.send_message(chat_id: message.chat.id,
                                  text: output_passport(passport.id, user))
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
              update_history(message, bot, user, cancel_markup)
            when '/get_kvests'
              if user.passport_id.nil?
                bot.api.send_message(chat_id: message.chat.id,
                                    text: 'Похоже к вам еще не привязан паспорт, используйте кнопку ' \
                                          'Получить свой паспорт')
              else
                message_kvests = user.passport.kvests.map { |kvest| "#{kvest['kvest_name']}\n" }
                bot.api.send_message(chat_id: message.chat.id, text: "Выполненные квесты:\n\n#{message_kvests}")
              end
            when '/change_info'
              change_info(message, bot, user, cancel_markup)
            when '/birthdays'
              birthdays(message.chat.id, bot, user)
            when '/feedback'
              leave_feedback(message, bot, user, feedback_markup)
            when '/choose_title'
              choose_title(message, bot, user, cancel_markup)
            when '/get_player'
              get_player(message, bot, user, cancel_markup)
            when '/mem', "\xF0\x9F\xA4\xA1 Мемчик \xF0\x9F\xA4\xA1"
              meme = (Dir.entries('/home/cloud-user/witcher-bot/witcher-bot/telegram/memes').reject do |f|
                        File.directory? f
                      end).sample
              bot.api.sendPhoto(chat_id: message.chat.id,
                                photo: Faraday::UploadIO.new(
                                  "/home/cloud-user/witcher-bot/witcher-bot/telegram//memes/#{meme}", 'image/jpg'
                                ))
            when '/subscription'
              get_subscription(message, bot, user)
            when 'Создать паспорт'
              if user.admin
                bot.api.send_message(chat_id: message.chat.id, text: 'Введите имя будующего ведьмака:',
                                    reply_markup: cancel_markup)
                user.update(step: 'input_name')
              else
                bot.api.send_message(chat_id: message.chat.id, text: 'Ты как сюда залез?)')
              end
            when 'Изменить запись'
              change_record(message, bot, user, cancel_markup)
            when 'Создать квест'
              create_kvest(message, bot, user, cancel_markup)
            when 'Выполнить квест'
              complete_kvest(message, bot, user, cancel_markup)
            when 'Создать титул'
              create_title(message, bot, user, cancel_markup)
            when 'Назначить титул'
              assign_title(message, bot, user, cancel_markup)
            when 'Списать занятия'
              substract_visitings(message, bot, user, cancel_markup)
            when 'Информация по игроку'
              output_all_passports(bot, message.chat.id)
              bot.api.send_message(chat_id: message.chat.id, text: 'Выберите паспорт', reply_markup: cancel_markup)
              user.update(step: 'input_abon_info')
            when 'Информация по всем абонементам'
              subscription_info(message, bot, user)
            when 'Провести турнир'
              bot.api.send_message(chat_id: message.chat.id, text: "Не протестировано")
            when 'Открыть предзапись'
              open_prerecording(message, bot, user, cancel_markup)
            when 'Закрыть предзапись'
              close_prerecording(message, bot, user)
            when 'Списать кроны'
              substract_crons(message, bot, user, cancel_markup)
            when 'Начислить занятия'
              accrue_visitings(message, bot, user, cancel_markup)
            when 'Повысить ранг'
              rank_up(message, bot, user, cancel_markup)
            when 'Уведомление'
              notification(message, bot, user, cancel_markup)
            when '/remove'
              reply_markup = user.admin ? @admin_markup : @remove_keyboard
              reply_markup = @hamon_markup if user.telegram_id == 448_768_896
              bot.api.send_message(chat_id: message.chat.id, text: 'Кнопки убраны)', reply_markup: reply_markup)
            when 'Изменить описание'
              change_description(message, bot, user, cancel_markup)
            end
          # Passport creation
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
            new_user&.update(passport_id: @passport.id)
            return_buttons(user, bot, message.chat.id, 'Запись создана')
          when 'change_user_description'
            description = message.text
            user.passport.update(description: description)
            return_buttons(user, bot, message.chat.id, 'Описание успешно обновлено')
          # Kvest creation
          when 'input_kvest_name'
            @kvest_name = input_kvest_name(message, bot, user)
          when 'input_crons_reward'
            @crons_reward = input_crons_reward(message, bot, user)
          when 'input_level_reward'
            @level_reward = input_level_reward(message, bot, user)
          when 'input_title_reward'
            @title_reward = input_title_reward(message, bot, user, @kvest_name)
          when 'input_addkvest_reward'
            @addkvest_reward = input_addkvest_reward(message, bot, user)
          when 'input_repeat_kvest_reward'
            @repeat_revard = input_repeat_kvest_reward(message, bot, user)
          when 'input_additional_reward'
            input_additional_reward(message, bot, user, {:kvest_name => @kvest_name, :crons_reward => @crons_reward,
                                                         :level_reward => @level_reward, :title_reward => @title_reward,
                                                         :addkvest => @addkvest_reward, 
                                                         :repeat => @repeat_revard})
          when 'input_passport_number'
            @passport_number = input_passport_number(message, bot, user)
          when 'input_kvest_number'
            input_kvest_number(message, bot, user, @passport_number)
          when 'input_title_name'
            @title_name = input_title_name(message, bot, user)
          when 'input_title_description'
            input_title_description(message, bot, user, @title_name)
          when 'change_history'
            change_history(message, bot, user)
          when 'choose_table'
            @active_table = choose_table(message, bot, user)
          when 'choose_record'
            @record = choose_record(message, bot, user, @active_table)
          when 'choose_field'
            @field = choose_field(message, bot, user, @record)
          when 'update_field_value'
            update_field_value(message, bot, user, @record, @field)
          when 'input_pasport_title'
            @passport_id = input_pasport_title(message, bot, user)
          when 'choose_title'
            choose_title(message, bot, user, @passport_id)
          when 'input_main_title'
            input_main_title(message, bot, user)
          when 'input_substract'
            input_substract(message, bot, user)
          when 'input_bd'
            @bd = input_bd(message, bot, user)
          when 'input_mail'
            @mail = input_mail(message, bot, user)
          when 'input_number'
            input_number(message, bot, user, @bd, @mail)
          when 'input_player_passport_number'
            input_player_passport_number(message, bot, user)
          when 'input_abon_info'
            passport = Passport.find_by(id: message.text)
            if passport.nil?
              return_buttons(user, bot, message.chat.id, 'Некорректный ввод, повторите команду')
            else
              return_buttons(user, bot, message.chat.id,
                             "Имя: #{passport.nickname}\nДень рождения: #{passport.bd}\nНомер телефона: " \
                             "#{passport.number}\nОстаток абонемента: #{passport.subscription}\nДолг:#{passport.debt}")
            end
          when 'input_change_info_field'
            @update_field = input_change_info_field(message, bot, user)
          when 'input_info_value'
            input_info_value(message, bot, user, @update_field)
          when 'input_vote_message'
            @vote_message = input_vote_message(message, bot, user)
          when 'input_descr_passport'
            @change_passport_h = input_descr_passport(message, bot, user)
          when 'input_new_description'
            input_new_description(message, bot, user, @change_passport_h)
          when 'choose_user_visibility'
            @send_feedbacks_author = choose_user_visibility(message, bot, user, cancel_markup)
          when 'enter_feedback'
            enter_feedback(message, bot, user, @send_feedbacks_author)
          when 'input_passport_to_substract'
            @passport_id = input_passport_to_substract(message, bot, user)
          when 'input_crons_to_substract'
            input_crons_to_substract(message, bot, user, @passport_id)
          when 'input_subscription_addition'
            @passport_id = input_subscription_addition(message, bot, user)
          when 'add_subscription'
            add_subscription(message, bot, user, @passport_id)
          when 'input_passport_rank'
            input_passport_rank(message, bot, user)
          when 'input_notification'
            input_notification(message, bot, user)
          end
        end
        # else
        #   bot.api.send_message(chat_id: message.chat.id,
        #                             text: "Ведутся работы, пожалуйста подождите")
        # end
      rescue StandardError
        return_buttons(user, bot, message.chat.id,
                       'Похоже возникла ошибка, проверьте правильность введенных данных и повторите ввод')
      end
    end
  end
end
