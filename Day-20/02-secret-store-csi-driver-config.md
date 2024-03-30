# Connect your Azure ID to the Azure Key Vault Secrets Store CSI Driver

### Configure workload identity

```
export SUBSCRIPTION_ID=223b3de2-144c-49ec-93dc-765b9cebf465
export RESOURCE_GROUP=keyvault-demo
export UAMI=azurekeyvaultsecretsprovider-keyvault-demo-cluster-mi
export KEYVAULT_NAME=aks-demo-key-vault
export CLUSTER_NAME=keyvault-demo-cluster

az account set --subscription $SUBSCRIPTION_ID
where UAMI = user assigned managed identity.
```

### Create a managed identity

```
az identity create --name $UAMI --resource-group $RESOURCE_GROUP

export USER_ASSIGNED_CLIENT_ID="$(az identity show -g $RESOURCE_GROUP --name $UAMI --query 'clientId' -o tsv)"
export IDENTITY_TENANT=$(az aks show --name $CLUSTER_NAME --resource-group $RESOURCE_GROUP --query identity.tenantId -o tsv)
```

### Create a role assignment that grants the workload ID access the key vault

```
export KEYVAULT_SCOPE=$(az keyvault show --name $KEYVAULT_NAME --query id -o tsv)

az role assignment create --role "Key Vault Administrator" --assignee $USER_ASSIGNED_CLIENT_ID --scope $KEYVAULT_SCOPE
```

### Get the AKS cluster OIDC Issuer URL

```
export AKS_OIDC_ISSUER="$(az aks show --resource-group $RESOURCE_GROUP --name $CLUSTER_NAME --query "oidcIssuerProfile.issuerUrl" -o tsv)"
echo $AKS_OIDC_ISSUER
```
To check if OIDC (OpenID Connect) is enabled on your Azure Kubernetes Service (AKS) cluster, you can use the Azure CLI. OIDC is a critical component for integrating Kubernetes clusters with external identity providers, enabling scenarios such as using Azure Active Directory for user authentication or integrating with services that rely on OIDC for identity assertions.

Here’s how you can verify the OIDC issuer URL for your AKS cluster, which indicates OIDC is enabled:

1. **Open your terminal or command prompt.**

2. **Ensure you have the Azure CLI installed and you're logged in to your Azure account.** You can log in using `az login` if you haven't done so already.

3. **Run the following command to get details about your AKS cluster, including the OIDC issuer URL:**

   ```bash
   az aks show --resource-group <your-resource-group> --name <your-cluster-name> --query "oidcIssuerProfile"
   ```

   Replace `<your-resource-group>` with the name of the resource group containing your AKS cluster, and `<your-cluster-name>` with the name of your AKS cluster.

4. **Check the output.** If OIDC is enabled, the command will output details about the OIDC issuer profile, including the issuer URL. If the OIDC issuer profile is not displayed or the issuer URL is absent, OIDC may not be enabled on your cluster.

The presence of an issuer URL in the response indicates that OIDC is enabled. Here is an example of what the output might look like if OIDC is enabled:

```json
{
  "issuerUrl": "https://oidc.aks.azure.com/id/12345678-1234-1234-1234-1234567890ab"
}
```

If you find that OIDC is not enabled and you wish to enable it, you can update your AKS cluster to enable OIDC with the following Azure CLI command:

```bash
az aks update --resource-group <your-resource-group> --name <your-cluster-name> --enable-oidc-issuer
```

Remember to replace `<your-resource-group>` and `<your-cluster-name>` with your specific values.

**Note:** Enabling OIDC on an existing AKS cluster should not disrupt existing workloads, but it's always a good practice to test changes in a non-production environment first.


### Create the service account for the pod

```
export SERVICE_ACCOUNT_NAME="workload-identity-sa"
export SERVICE_ACCOUNT_NAMESPACE="default"
```

```
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ServiceAccount
metadata:
  annotations:
    azure.workload.identity/client-id: ${USER_ASSIGNED_CLIENT_ID}
  name: ${SERVICE_ACCOUNT_NAME}
  namespace: ${SERVICE_ACCOUNT_NAMESPACE}
EOF
```

### Setup Federation

```
export FEDERATED_IDENTITY_NAME="aksfederatedidentity"

az identity federated-credential create --name $FEDERATED_IDENTITY_NAME --identity-name $UAMI --resource-group $RESOURCE_GROUP --issuer ${AKS_OIDC_ISSUER} --subject system:serviceaccount:${SERVICE_ACCOUNT_NAMESPACE}:${SERVICE_ACCOUNT_NAME}
```

### Create the Secret Provider Class

```
cat <<EOF | kubectl apply -f -
# This is a SecretProviderClass example using workload identity to access your key vault
apiVersion: secrets-store.csi.x-k8s.io/v1
kind: SecretProviderClass
metadata:
  name: azure-kvname-wi # needs to be unique per namespace
spec:
  provider: azure
  parameters:
    usePodIdentity: "false"
    clientID: "${USER_ASSIGNED_CLIENT_ID}" # Setting this to use workload identity
    keyvaultName: ${KEYVAULT_NAME}       # Set to the name of your key vault
    cloudName: ""                         # [OPTIONAL for Azure] if not provided, the Azure environment defaults to AzurePublicCloud
    objects:  |
      array:
        - |
          objectName: secret1             # Set to the name of your secret
          objectType: secret              # object types: secret, key, or cert
          objectVersion: ""               # [OPTIONAL] object versions, default to latest if empty
        - |
          objectName: key1                # Set to the name of your key
          objectType: key
          objectVersion: ""
    tenantId: "${IDENTITY_TENANT}"        # The tenant ID of the key vault
EOF
```

