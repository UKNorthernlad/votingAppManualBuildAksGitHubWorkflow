# Taken from https://learn.microsoft.com/en-us/azure/aks/kubernetes-action
# Authenticate with Azure Container Registry (ACR) from Azure Kubernetes Service (AKS)


$resourceGroup = "containers"
$acr="eboracr"
$aksClusterName = "eborcluster99"

az group create -n $resourceGroup -l "westeurope"
az acr create -n $acr -g $resourceGroup --sku basic
az aks create -n $aksClusterName -g $resourceGroup --generate-ssh-keys --attach-acr $acr
az aks get-credentials -g $resourceGroup -n $aksClusterName

# Import the Cat & Dog Voting application
az acr import  -n $acr --source mcr.microsoft.com/oss/bitnami/redis:6.0.8 --image azure-vote-back:v1
az acr import  -n $acr --source mcr.microsoft.com/azuredocs/azure-vote-front:v1 --image azure-vote-front:v1

# Create the k8s application manifest
'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: azure-vote-back
spec:
  replicas: 1
  selector:
    matchLabels:
      app: azure-vote-back
  template:
    metadata:
      labels:
        app: azure-vote-back
    spec:
      nodeSelector:
        "kubernetes.io/os": linux
      containers:
      - name: azure-vote-back
        image: eboracr.azurecr.io/azure-vote-back:v1
        env:
        - name: ALLOW_EMPTY_PASSWORD
          value: "yes"
        resources:
          requests:
            cpu: 100m
            memory: 128Mi
          limits:
            cpu: 250m
            memory: 256Mi
        ports:
        - containerPort: 6379
          name: redis
---
apiVersion: v1
kind: Service
metadata:
  name: azure-vote-back
spec:
  ports:
  - port: 6379
  selector:
    app: azure-vote-back
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: azure-vote-front
spec:
  replicas: 1
  selector:
    matchLabels:
      app: azure-vote-front
  template:
    metadata:
      labels:
        app: azure-vote-front
    spec:
      nodeSelector:
        "kubernetes.io/os": linux
      containers:
      - name: azure-vote-front
        image: eboracr.azurecr.io/azure-vote-front:v1
        resources:
          requests:
            cpu: 100m
            memory: 128Mi
          limits:
            cpu: 250m
            memory: 256Mi
        ports:
        - containerPort: 80
        env:
        - name: REDIS
          value: "azure-vote-back"
---
apiVersion: v1
kind: Service
metadata:
  name: azure-vote-front
spec:
  type: LoadBalancer
  ports:
  - port: 80
  selector:
    app: azure-vote-front
' >> application.yaml


kubectl apply -f application.yaml

kubectl get service/azure-vote-front --watch
