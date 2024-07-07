# frozen_string_literal: true

# module for getting all bp levels for all players
module GetAllPlayersSumBP
    def get_all_players_sum_bp(message, bot, user)
      if user.admin
        levels = Passport.where("sum_bp_level > 0").select(:nickname, :sum_bp_level)
        levels_message = levels.map { |p| "#{p.nickname}: #{p.sum_bp_level} lvl"}.join("\n")
        bot.api.send_message(chat_id: message.chat.id,
                              text: "Уровни летнего боевого пропуска:\n#{levels_message}")
      else
        bot.api.send_message(chat_id: message.chat.id, text: 'Ты как сюда залез?)')
      end
    end
  end
    