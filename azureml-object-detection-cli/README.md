# Azure ML Object Detection CLI

## Setup

### Configure Defaults

```bash
az configure --defaults workspace=<your-workspace-name> group=<your-resource-group-name>
```

### Create Environment

```bash
az ml environment create -f azureml/environment.yaml
```

## If No Quota Available for Serverless Run

Create a dedicated compute cluster for image builds:

```bash
az ml compute create \
  --name image-build-cluster \
  --type amlcompute \
  --size Standard_DS3_v2 \
  --min-instances 0 \
  --max-instances 1
```

Update the workspace to use this cluster for image builds:

```bash
az ml workspace update \
  --name <your-workspace> \
  --resource-group <your-rg> \
  --image-build-compute image-build-cluster
```

Then create the environment:

```bash
az ml environment create -f environment.yaml
```

Or with an explicit version:

```bash
az ml environment create -f environment.yaml --version 2
```
