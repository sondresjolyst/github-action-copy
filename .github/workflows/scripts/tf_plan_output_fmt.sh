#!/usr/bin/env bash

path=$1
arg=("${@:2}")
tfplan=$(terraform -chdir="$path" plan "${arg[@]}")

createArr=()
destroyArr=()
updateArr=()

while read -r line; do
  if [[ $line =~ "will be created" ]]; then
    createArr+=("${line//"# "/"+ "}")
  elif [[ $line =~ "will be destroyed" ]]; then
    destroyArr+=("${line//"# "/"- "}")
  elif [[ $line =~ "will be updated in-place" ]]; then
    updateArr+=("${line//"# "/"~ "}")
  fi
done <<<"$tfplan"

numberOfChanges="${#createArr[@]} + ${#destroyArr[@]} + ${#updateArr[@]}"

if [ ${#createArr[@]} -gt 0 ]; then
  printf ""
  printf "The following resources will be created\n"
  printf "  %s\n" "${createArr[@]}"
fi

if [ ${#destroyArr[@]} -gt 0 ]; then
  printf ""
  printf "The following resources will be destroyed\n"
  printf "  %s\n" "${destroyArr[@]}"
fi

if [ ${#updateArr[@]} -gt 0 ]; then
  printf ""
  printf "The following resources will be updated\n"
  printf "  %s\n" "${updateArr[@]}"
fi

if [ ${#numberOfChanges[@]} -eq 0 ]; then
  printf ""
  printf "No changes. Your infrastructure matches the configuration.\n"
fi
printf ""

out=()
out+=(${createArr[@]})
out+=(${destroyArr[@]})
out+=(${updateArr[@]})

JSON="[$(echo $out | sed 's/ /, /g')]"

echo "stdout=$JSON" >> $GITHUB_OUTPUT
