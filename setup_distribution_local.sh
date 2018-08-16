#!/usr/bin/env bash
IF=en0
HOST=$(ifconfig ${IF} | grep 'inet ' | cut -d ' ' -f 2)
NAME="observer@${HOST}"
# use the same cookie value
COOKIE="banana_chocolate_chip_nut_butter"
printf "NAME='${NAME}'\nCOOKIE='${COOKIE}'\n"
iex --name "${NAME}" --cookie "${COOKIE}" --hidden -e ":observer.start"
# OR
#erl -name "${NAME}" -setcookie "${COOKIE}" -hidden -run observer
