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
  if [[ -z $line ]]; then 
    echo "empty"
    continue
  fi
  if [[ $line =~ "will be created" ]]; then
    echo "${line}"
    createArr+=("${line//"# "/"+ "}")
    echo "--createArr loop--"
    echo "${createArr[@]}"
    echo "--"
  elif [[ $line =~ "will be destroyed" ]]; then
    destroyArr+=("${line//"# "/"- "}")
  elif [[ $line =~ "will be updated in-place" ]]; then
    updateArr+=("${line//"# "/"~ "}")
  fi
done < <(echo "${tfplan}")

echo "--createArr--"
echo "${createArr[@]}"
echo "--"

echo "--tfplan--"
echo "${tfplan}"
echo "--"

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

# # rm out.txt
# echo "${test[@]}" | tr -d '\n' > out.txt
# # echo "SAAB900Turbo 1985" > out.txt
# foo=$(cat out.txt)

# echo "--"
# echo "${foo}"

# echo "--"
# ls

# echo "--"
# ls ..

# echo "--"
# ls /

# echo "--"
# echo "tfplan ${tfplan}"

# echo "random-id=$(echo $RANDOM)" >> $GITHUB_OUTPUT
# echo "tf-plan-output=aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa" >> $GITHUB_OUTPUT # works
# echo "tf-plan-output=$(echo "+ azurerm_private_dns_zone_virtual_network_link.cluster_link[0] will be created \ ")" >> $GITHUB_OUTPUT # works
# echo "tf-plan-output=$(echo "+ azurerm_private_dns_zone_virtual_network_link.cluster_link[0] will be created + azurerm_private_dns_zone_virtual_network_link.cluster_link[1] will be created + azurerm_private_dns_zone_virtual_network_link.cluster_link[2] will be created + azurerm_private_dns_zone_virtual_network_link.cluster_link[3] will be created + azurerm_private_dns_zone_virtual_network_link.cluster_link[4] will be created + azurerm_private_dns_zone_virtual_network_link.cluster_link[5] will be created + azurerm_private_dns_zone_virtual_network_link.cluster_link[6] will be created + azurerm_private_dns_zone_virtual_network_link.cluster_link[7] will be created + azurerm_private_dns_zone_virtual_network_link.cluster_link[8] will be created + azurerm_private_dns_zone_virtual_network_link.cluster_link[9] will be created + azurerm_private_dns_zone_virtual_network_link.cluster_link[10] will be created + azurerm_private_dns_zone_virtual_network_link.cluster_link[11] will be created + azurerm_private_dns_zone_virtual_network_link.cluster_link[12] will be created + azurerm_private_dns_zone_virtual_network_link.cluster_link[13] will be created + azurerm_private_dns_zone_virtual_network_link.cluster_link[14] will be created + azurerm_private_dns_zone_virtual_network_link.cluster_link[15] will be created + azurerm_private_dns_zone_virtual_network_link.cluster_link[16] will be created + azurerm_redis_cache.redis_cache_web_console[0] will be created + azurerm_redis_cache.redis_cache_web_console[1] will be created + null_resource.add_whitelist_acr will be created + null_resource.delete_whitelist_acr will be created + module.aks.azurerm_kubernetes_cluster.kubernetes_cluster will be created + module.aks.azurerm_kubernetes_cluster_node_pool.nodepools[0] will be created + module.aks.azurerm_kubernetes_cluster_node_pool.nodepools[1] will be created + module.aks.azurerm_kubernetes_cluster_node_pool.nodepools[2] will be created + module.aks.azurerm_kubernetes_cluster_node_pool.nodepools[3] will be created + module.aks.azurerm_network_security_group.nsg_cluster will be created + module.aks.azurerm_public_ip.pip_ingress will be created + module.aks.azurerm_subnet.subnet_cluster will be created + module.aks.azurerm_virtual_network.vnet_cluster will be created + module.aks.azurerm_virtual_network_peering.cluster_to_hub will be created + module.aks.azurerm_virtual_network_peering.hub_to_cluster will be created + module.aks.random_id.four_byte will be created")" >> $GITHUB_OUTPUT
echo "tf-plan-output=$(echo $foo)" >> $GITHUB_OUTPUT
