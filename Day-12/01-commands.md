# Commands to access Blob from the Virtual Machine

### Fetch the access token 

```
access_token=$(curl 'http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=https%3A%2F%2Fstorage.azure.com%2F' -H Metadata:true | jq -r '.access_token')
```


### Access the blob from Virtual Machine

storage_account_name=""
container_name=""
blob_name=""

```
curl "https://$storage_account_name.blob.core.windows.net/$container_name/$blob_name" -H "x-ms-version: 2017-11-09" -H "Authorization: Bearer $access_token"
```

### Alternatively Access Blob From VM using BASH

If you're requesting an access token for Azure Storage Account access specifically using an Azure VM's Managed Identity, you'll want to ensure that the Managed Identity is granted appropriate permissions on the storage account. Typically, this involves assigning the "Storage Blob Data Reader" role for read-only access, or another role that suits your access needs, through Azure Role-Based Access Control (RBAC).

Here's a step-by-step guide on how to use `curl` from within an Azure VM to obtain an access token for accessing Azure Storage with a Managed Identity:

### Step 1: Assign RBAC Role to the Managed Identity

1. Navigate to the Azure portal.
2. Go to the Storage Account you wish to access.
3. Select "Access control (IAM)" from the sidebar.
4. Click on "Add role assignment".
5. Choose the appropriate role (e.g., "Storage Blob Data Reader" for read-only access to blobs).
6. Select the Managed Identity you're using (either the VM's System Assigned Identity or a specific User Assigned Identity).
7. Save the role assignment.

### Step 2: Obtain an Access Token Using `curl`

Replace `https://storage.azure.com/` with the resource you're requesting an access token for. This is the correct resource URL for Azure Storage.

```bash
#!/bin/bash

# Resource URL for Azure Storage
RESOURCE="https://storage.azure.com/"

# Metadata endpoint and required header
IMDS_ENDPOINT="http://169.254.169.254/metadata/identity/oauth2/token"
API_VERSION="api-version=2018-02-01"
HEADER="Metadata:true"

# Request an access token. Append '&client_id=<your-managed-identity-client-id>' if using a User Assigned Identity
RESPONSE=$(curl "${IMDS_ENDPOINT}?resource=${RESOURCE}&${API_VERSION}" -H "${HEADER}" -s)

# Extract and print the access token from the response
ACCESS_TOKEN=$(echo $RESPONSE | jq -r '.access_token')
echo $ACCESS_TOKEN
```

Make sure `jq` is installed on your VM to parse the JSON response. You can install it with `sudo apt-get install jq` on Ubuntu/Debian or `sudo yum install jq` on RHEL/CentOS.

### Step 3: Use the Access Token to Authenticate to Azure Storage

You can now use the obtained access token as a Bearer token to authenticate your requests to Azure Storage. Here's an example of how you might use it with `curl` to list the blobs in a container:

```bash
STORAGE_ACCOUNT="yourstorageaccount"
CONTAINER_NAME="yourcontainername"

# Replace <access-token> with the actual access token obtained earlier
ACCESS_TOKEN="<access-token>"

# Perform the API call
curl -X GET \
     -H "Authorization: Bearer $ACCESS_TOKEN" \
     -H "x-ms-version: 2017-11-09" \
     "https://$STORAGE_ACCOUNT.blob.core.windows.net/$CONTAINER_NAME?restype=container&comp=list"
```

### Security Notes

- Always ensure that the Managed Identity is given only the permissions it needs to perform its tasks (principle of least privilege).
- The access token should be handled securely and not exposed to unauthorized entities.
- Managed Identities provide a more secure and manageable way to access Azure resources without embedding credentials in your code.


