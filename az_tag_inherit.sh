#   ****************************************
#   Tag inheritance in Azure cloud
#   begin     : Thu 29 Jun 2023
#   copyright : (c) 2023 Václav Dvorský
#   email     : vaclav.dvorsky@hotmail.com
#   $Id: az_tag_inherit.sh, v1.00 29/06/2023
#   ****************************************
#
#   --------------------------------------------------------------------
#   This program is free software; you can redistribute it and/or modify
#   it under the terms of the GNU General Public Licence as published by
#   the Free Software Foundation; either version 2 of the Licence, or
#   (at your option) any later version.
#   --------------------------------------------------------------------
#
# Description:
#   This script is used to tag resources within a resource group according to the 
#   tags and values set on it. It works by inheriting tags from higher layers.

#!/bin/sh

subscription_id="SUBSCRIPTION_ID"
tags="app creator env project"

echo "Získávám seznam resource group pro Subscription ID: $subscription_id ..."

# Uncomment if you want to go through all the RGs
#resource_groups=$(az group list --subscription $subscription_id --query '[].name' -o tsv)
resource_groups="RG1 RG2"

for tag in $tags; do

    for resource_group in $resource_groups; do
    echo "Zpracovávám Resource Group: $resource_group"

    resources=$(az resource list --resource-group $resource_group --subscription $subscription_id --query "[].id" -o tsv)

    echo "$resources" | while IFS= read -r resource_id; do
        echo "Zpracovávám zdroj: $resource_id"

        current_tag_value=$(az resource show --ids $resource_id --query "tags.$tag" -o tsv)

        if [ -z "$current_tag_value" ]; then
        echo "Tag '$tag' nemá žádnou hodnotu. Nastavuji ho na hodnotu z nadřazené skupiny zdrojů."

        parent_tags=$(az group show --name $resource_group --subscription $subscription_id --query "tags" -o json)
        parent_tag_value=$(echo $parent_tags | jq -r ".$tag")

        if [ -n "$parent_tag_value" ]; then
            az resource tag --tags $tag="$parent_tag_value" --ids $resource_id --subscription $subscription_id -o yamlc
        fi
        else
        echo "Tag '$tag' již má hodnotu: $current_tag_value"
        fi
    done

    echo "Hotovo pro Resource Group: $resource_group"
    done
done

echo "Hotovo!"
