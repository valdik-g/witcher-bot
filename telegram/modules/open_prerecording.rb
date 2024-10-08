# frozen_string_literal: true

# module for open prerecording for users
module OpenPrerecording
  TRAINING_OPTIONS = ["Сб0\xE2\x9A\x94",  "Сб1\xE2\x9A\x94", "Сб2\xE2\x9A\x94", "Сб2\xf0\x9f\x8f\xb9",
    "Сб3\xf0\x9f\x8f\xb9", "Сб4\xf0\x9f\x8f\xb9", "Вс0\xE2\x9A\x94", "Вс1\xE2\x9A\x94", "Вс2\xE2\x9A\x94", 
    "Вс3\xf0\x9f\x8f\xb9"]

  # "Сб0\xf0\x9f\x8f\xb9",  "Сб1\xf0\x9f\x8f\xb9", "Сб2\xf0\x9f\x8f\xb9",
  # "Сб3\xf0\x9f\x8f\xb9", "Сб4\xf0\x9f\x8f\xb9", "Вс0\xE2\x9A\x94", "Вс1\xE2\x9A\x94", "Вс2\xE2\x9A\x94", 
  # "Вс3\xf0\x9f\x8f\xb9"

  def open_prerecording(message, bot, user)
    if user.admin
      (Prerecording.last || Prerecording.create).update(closed: false)
      UserPrerecording.update_all(days: '', voted: false)
      Prerecording.last.update(:choosed_options => '', :available_trainings => '', :closed_prerecordings => '')
      bot.api.send_message(chat_id: message.chat.id, text: 'Введите сообщение', reply_markup: cancel_markup)
      user.update(step: 'input_vote_message')
    else
      bot.api.send_message(chat_id: message.chat.id, text: 'Ты как сюда залез?)')
    end
  end

  def input_vote_message(message, bot, user)
    bot.api.send_poll(chat_id: message.chat.id, question: 'Какие тренировки планируются?', 
                      allows_multiple_answers: true, options: TRAINING_OPTIONS, is_anonymous: false)
    user.update(step: 'create_prerecording')
    message.text
  end

  def create_prerecording(message, bot, user, vote_message)
    choosed_options = message.option_ids.map { |l| TRAINING_OPTIONS[l.to_i] }
    available_trainings = choosed_options.map { |c| c.include?("\xf0\x9f\x8f\xb9") ? 5 : 10 }
    Prerecording.last.update(choosed_options: choosed_options.join(','), 
                             available_trainings: available_trainings.join(','))
    passports = Passport.where('subscription > 0 and subscription < 300')
    passports.each do |pass|
      unless pass.user.nil? || pass.user.telegram_id.nil?
        begin
          bot.api.send_message(chat_id: pass.user.telegram_id, text: vote_message)
          bot.api.send_poll(chat_id: pass.user.telegram_id,
                                              question: 'Куда идем?', allows_multiple_answers: true,
                                              options: choosed_options, is_anonymous: false)
        rescue
          p "Пользователь #{pass.user.username} заблокировал бота"
        end
      end
    end
    return_buttons(user, bot, message.user.id, 'Предзапись создана')
  end

  def prerecord_user(bot, message, user)
    prerec = Prerecording.last
    user_prerec = user.passport.user_prerecording
    closed_trainings = prerec.closed_prerecordings.split(',')
    if user_prerec
      if user_prerec.voted
        # TODO ???
        user_prerec.days.split(',').each do |option|
          available_trainings = prerec.available_trainings.split(',').map(&:to_i)
          if available_trainings[option.to_i] == 0
            UserPrerecording.where(voted: false).each do |up|
              us_passport = up.passport
              if us_passport&.user && ((us_passport&.subscription > 0 && us_passport&.subscription < 200) || us_passport&.id == 2)
                begin
                  bot.api.send_message(chat_id: us_passport&.user.telegram_id,
                                      text: "!!! Предзапись на тренировку #{prerec.choosed_options.split(',')[option.to_i]}" \
                                            " снова открыта, скорее забирайте !!!")
                rescue
                  p "Пользователь #{pass.user.username} заблокировал бота"
                end
              end
            end
          end
          available_trainings[option.to_i] += 1
          prerec.update(available_trainings: available_trainings.join(','))
        end
      end
      user_prerec.update(days: message.option_ids.excluding(closed_trainings.map(&:to_i)).join(','), voted: true)
    end
    message.option_ids.excluding(closed_trainings.map(&:to_i)).each do |option|
      available_trainings = prerec.available_trainings.split(',').map(&:to_i)
      available_trainings[option.to_i] -= 1
      if available_trainings[option.to_i].zero?
        prerec.update(closed_prerecordings: (closed_trainings << option.to_i).join(','))
        UserPrerecording.where(voted: false).each do |up|
          if up.passport
            if up.passport.user && ((up.passport.subscription > 0 && up.passport.subscription < 200) || up.passport.id == 2)
              begin
                bot.api.send_message(chat_id: up.passport.user.telegram_id,
                                    text: "!!! Предзапись на тренировку #{prerec.choosed_options.split(',')[option.to_i]}" \
                                          " закрыта, в случае голосавания голос не будет учтен !!!")
              rescue
                p "Пользователь #{pass.user.username} заблокировал бота"
              end
            end
          end
        end
      end
      prerec.update(available_trainings: available_trainings.join(','))
    end
  end
end
