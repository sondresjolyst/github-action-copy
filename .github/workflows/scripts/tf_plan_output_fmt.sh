#!/usr/bin/env bash

path=$1
arg=("${@:2}")
tfplan=$(terraform -chdir="$path" plan "${arg[@]}")

createArr=()
destroyArr=()
updateArr=()

red=$'\e[1;31m'
grn=$'\e[1;32m'
yel=$'\e[1;33m'
normal=$(tput sgr0)

while read -r line; do
  if [[ $line =~ "will be created" ]]; then
    createArr+=("${line//"# "/"${grn}+ ${normal}"}")
  elif [[ $line =~ "will be destroyed" ]]; then
    destroyArr+=("${line//"# "/"${red}- ${normal}"}")
  elif [[ $line =~ "will be updated in-place" ]]; then
    updateArr+=("${line//"# "/"${yel}~ ${normal}"}")
  fi
done <<<"$tfplan"

numberOfChanges="${#createArr[@]} + ${#destroyArr[@]} + ${#updateArr[@]}"

if [ ${#createArr[@]} -gt 0 ]; then
  printf ""
  printf "%sThe following resources will be created%s\n" "${grn}" "${normal}"
  printf "  %s\n" "${createArr[@]}"
fi

if [ ${#destroyArr[@]} -gt 0 ]; then
  printf ""
  printf "  %sThe following resources will be destroyed%s\n" "${red}" "${normal}"
  "${destroyArr[@]}"
fi

if [ ${#updateArr[@]} -gt 0 ]; then
  printf ""
  printf "  %sThe following resources will be updated%s\n" "${yel}" "${normal}"
  "${updateArr[@]}"
fi

if [ ${#numberOfChanges[@]} -eq 0 ]; then
  printf ""
  printf "%sNo changes. Your infrastructure matches the configuration.%s\n" "${grn}" "${normal}"
fi
printf ""
