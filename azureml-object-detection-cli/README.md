# Azure ML Object Detection CLI

## Prerequisites

```bash
az configure --defaults workspace=<your-workspace-name> group=<your-resource-group-name>
```

## Setup

### 1. Create Compute Cluster

```bash
az ml compute create -f azureml/compute.yaml
```

### 2. Create Environment

```bash
az ml environment create -f azureml/environment.yaml
```

#### If no quota available for serverless image build

Create a dedicated cluster for image builds:

```bash
az ml compute create \
  --name image-build-cluster \
  --type amlcompute \
  --size Standard_DS3_v2 \
  --min-instances 0 \
  --max-instances 1
```

Point the workspace to use it:

```bash
az ml workspace update \
  --name <your-workspace> \
  --resource-group <your-rg> \
  --image-build-compute image-build-cluster
```

Then retry:

```bash
az ml environment create -f azureml/environment.yaml
# or with an explicit version
az ml environment create -f azureml/environment.yaml --version 2
```

### 3. Register Dataset

```bash
az ml data create -f azureml/dataset.yaml
```

### 4. Register Base Model

```bash
az ml model create -f azureml/model.yaml
```

## Run Training Job

```bash
az ml job create -f azureml/job.yaml
```
