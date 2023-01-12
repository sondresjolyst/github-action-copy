#!/usr/bin/env bash

path=$1
arg=("${@:2}")
tfplan=$(terraform -chdir="$path" plan "${arg[@]}")
# strArr=("$(IFS=$'\n'; echo $tfplan)")

createArr=()
destroyArr=()
updateArr=()
out=()

while read -r line; do
  if [[ $line =~ "will be created" ]]; then
    createArr+=("${line//"# "/"+ "} \\")
  elif [[ $line =~ "will be destroyed" ]]; then
    destroyArr+=("${line//"# "/"- "} \\")
  elif [[ $line =~ "will be updated in-place" ]]; then
    updateArr+=("${line//"# "/"~ "} \\")
  fi
done <<<"$tfplan"

# numberOfChanges="${#createArr[@]} + ${#destroyArr[@]} + ${#updateArr[@]}"

# if [ ${#createArr[@]} -gt 0 ]; then
#   printf ""
#   printf "The following resources will be created\n"
#   printf "  %s\n" "${createArr[@]}"
# fi

# if [ ${#destroyArr[@]} -gt 0 ]; then
#   printf ""
#   printf "The following resources will be destroyed\n"
#   printf "  %s\n" "${destroyArr[@]}"
# fi

# if [ ${#updateArr[@]} -gt 0 ]; then
#   printf ""
#   printf "The following resources will be updated\n"
#   printf "  %s\n" "${updateArr[@]}"
# fi

# if [ ${#numberOfChanges[@]} -eq 0 ]; then
#   printf ""
#   printf "No changes. Your infrastructure matches the configuration.\n"
# fi
# printf ""


out+=("${createArr[@]}" "${destroyArr[@]}" "${updateArr[@]}")

# rm out.txt
echo "${out[@]}" | tr -d '\n' > out.txt
foo=$(cat out.txt)

# echo "random-id=$(echo $RANDOM)" >> $GITHUB_OUTPUT
# echo "tf-planstdout=aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa" >> $GITHUB_OUTPUT # works
# echo "tf-planstdout=$(echo "+ azurerm_private_dns_zone_virtual_network_link.cluster_link[0] will be created \ ")" >> $GITHUB_OUTPUT # works
echo "tf-planstdout=$(echo $foo)" >> $GITHUB_OUTPUT # works
