#!/usr/bin/env bash
IF=en0
HOST=$(ifconfig ${IF} | grep 'inet ' | cut -d ' ' -f 2)
NAME="demo@${HOST}"
COOKIE="banana_chocolate_chip_nut_butter"
printf "NAME='${NAME}'\nCOOKIE='${COOKIE}'\n"
iex --name "${NAME}" --cookie "${COOKIE}"
# OR
#erl -name "${NAME}" -setcookie "${COOKIE}"

