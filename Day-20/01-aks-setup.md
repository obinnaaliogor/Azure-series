# AKS setup using CLI

## Create Azure Resource Group

```
az group create --name keyvault-demo --location eastus
```

## AKS Creation and Configuration

### Create an AKS cluster with Azure Key Vault provider for Secrets Store CSI Driver support

```
az aks create --name keyvault-demo-cluster -g keyvault-demo --node-count 1 --enable-addons azure-keyvault-secrets-provider --enable-oidc-issuer --enable-workload-identity
```
The command you've provided is an Azure CLI (Command-Line Interface) command used to create a new Azure Kubernetes Service (AKS) cluster with specific configurations. Here's a detailed breakdown of the command and its components:

```
az aks create --name keyvault-demo-cluster -g keyvault-demo --node-count 1 --enable-addons azure-keyvault-secrets-provider --enable-oidc-issuer --enable-workload-identity
```

### Command Breakdown

- `az`: This is the Azure CLI command prefix used for all commands that interact with Azure resources.

- `aks create`: This subcommand tells the Azure CLI to create a new AKS cluster.

- `--name keyvault-demo-cluster`: Specifies the name of the AKS cluster to be created. In this case, the cluster will be named `keyvault-demo-cluster`.

- `-g keyvault-demo`: Specifies the resource group under which the AKS cluster will be created. Resource groups in Azure act as logical containers into which Azure resources like VMs, networks, and AKS clusters are deployed and managed. Here, the specified resource group is `keyvault-demo`.

- `--node-count 1`: This option sets the number of nodes (VMs) in the default node pool of the cluster to 1. The node count determines the number of VMs that will be provisioned to run your containerized applications.

- `--enable-addons azure-keyvault-secrets-provider`: Enables the Azure Key Vault Secrets Provider add-on for the AKS cluster. This add-on allows AKS applications to access secrets, keys, and certificates stored in Azure Key Vault directly using the Kubernetes Secrets Store CSI driver. This is a crucial feature for managing sensitive configurations and data securely outside of your application's code and configurations.

- `--enable-oidc-issuer`: Enables the OIDC (OpenID Connect) issuer in the AKS cluster. This feature configures the Kubernetes API server to issue OIDC tokens. These tokens can be used for various purposes, including integrating with external identity providers and services that support OIDC for authentication and authorization. It's especially useful for setting up federated authentication schemes.

- `--enable-workload-identity`: This option enables the Workload Identity feature in the AKS cluster. Workload Identity allows Kubernetes service accounts to be linked with Azure Active Directory (AAD) identities, facilitating secure access to Azure resources based on Azure RBAC (Role-Based Access Control). This is an essential feature for scenarios where your Kubernetes workloads need to interact with other Azure services securely without managing credentials within your applications.

### Summary

This command creates a new AKS cluster named `keyvault-demo-cluster` in the `keyvault-demo` resource group, with a single node and several advanced features enabled for security and identity management. These features include integration with Azure Key Vault for secrets management, OIDC issuer for authentication, and Workload Identity for secure Azure service access. This setup is well-suited for applications that require secure handling of secrets and identities, and direct integration with other Azure services.



### Get the Kubernetes cluster credentials (Update kubeconfig)

```
az aks get-credentials --resource-group keyvault-demo --name keyvault-demo-cluster
```

#### Verify that each node in your cluster's node pool has a Secrets Store CSI Driver pod and a Secrets Store Provider Azure pod running

```
kubectl get pods -n kube-system -l 'app in (secrets-store-csi-driver,secrets-store-provider-azure)' -o wide
```

## Keyvault creation and configuration

- Create a key vault with Azure role-based access control (Azure RBAC).

```
az keyvault create -n aks-demo-abhi -g keyvault-demo -l eastus --enable-rbac-authorization
```