#!/bin/bash
count=$(ps -ef | grep telegram | grep -v grep | wc -l)
if [ $count != 1 ]; then
        ruby /home/cloud-user/witcher-bot/witcher-bot/telegram/bot.rb &
fi
