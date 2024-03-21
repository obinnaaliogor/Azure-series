#!/bin/bash
#az group create --name myResourceGroup --location eastus This will create a rs group for you.
# create Bash shell variable
export vmName=testvm
export resourceGroup=test-rg
az vm create \
  --resource-group $resourceGroup \
  --name $vmName \
  --image Ubuntu2204 \
  --vnet-name test_vnet \
  --subnet test_subnet \
  --generate-ssh-keys \
  --output json \
  --verbose 
