# Taken from https://learn.microsoft.com/en-us/azure/aks/kubernetes-action
# Authenticate with Azure Container Registry (ACR) from Azure Kubernetes Service (AKS)

$resourceGroup = "containers"
$acr="eboracr"
$aksClusterName = "eborcluster99"
$subscriptionId = "XXXXXX"

az group create -n $resourceGroup -l "westeurope"
az acr create -n $acr -g $resourceGroup --sku basic
az aks create -n $aksClusterName -g $resourceGroup --generate-ssh-keys --attach-acr $acr  --network-plugin azure
az aks get-credentials -g $resourceGroup -n $aksClusterName

# Import the Cat & Dog Voting application
az acr import  -n $acr --source mcr.microsoft.com/oss/bitnami/redis:6.0.8 --image azure-vote-back:v1
az acr import  -n $acr --source mcr.microsoft.com/azuredocs/azure-vote-front:v1 --image azure-vote-front:v1

# Import the k8s application manifest
kubectl apply -f .\application.yaml
#kubectl get service/azure-vote-front --watch

# Install Calico Operator
# https://docs.tigera.io/calico/latest/getting-started/kubernetes/managed-public-cloud/aks
kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.27.0/manifests/tigera-operator.yaml

# Configure the Calico installation.
kubectl create -f .\calicoInstallation.yaml


###################################################
# Setup AAD Service Principal for GH authentication
###################################################

# https://learn.microsoft.com/en-us/azure/developer/github/connect-from-azure?tabs=azure-cli%2Clinux
# Use GitHub Actions to connect to Azure

# Create an AAD Application for authentication
$appId = az ad app create --display-name GitHubActionsApp  --query "appId" --output tsv 
$spId = az ad sp create --id $appId --query "id" --output tsv 

az role assignment create --role contributor --subscription $subscription --assignee-object-id  $spId --assignee-principal-type ServicePrincipal --scope /subscriptions/$subscriptionId/resourceGroups/$resourceGroup

# Now create the following Secret in a new environment called "Testing"

AZURE_CREDENTIALS
{
    "clientSecret":   "XXXX",
    "subscriptionId": "XXXX",
    "tenantId":       "XXXX",
    "clientId":       "XXXX",
}





# Network policies replacment??
# https://learn.microsoft.com/en-us/azure/aks/use-pod-security-policies




