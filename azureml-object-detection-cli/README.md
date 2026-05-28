# Azure ML Object Detection CLI

End-to-end YOLO object detection training on Azure ML using the CLI v2.

## File Structure

```text
azureml-object-detection-cli/
├── azureml/                        # Azure ML resource definitions
│   ├── compute.yaml                # Training compute cluster config
│   ├── dataset.yaml                # Dataset registration config
│   ├── environment.yaml            # Training environment config
│   ├── job.yaml                    # Training job definition
│   └── model.yaml                  # Base model registration config
├── azureml-environment/            # Docker image for the training environment
│   └── Dockerfile
├── datasets/                       # Local datasets (not committed)
│   └── coco128/
├── models/                         # Pre-trained model weights (not committed)
│   └── yolov8n.pt
├── README.md
└── train/                          # Training code (uploaded as job source)
    ├── custom-coco128.yaml         # YOLO dataset config (path patched at runtime)
    ├── experiment_config.yaml      # YOLO training hyperparameters
    └── train.py                    # Training entry script
```

## Prerequisites

Configure your default workspace and resource group so you don't need to pass them on every command:

```bash
az configure --defaults workspace=<your-workspace-name> group=<your-resource-group-name>
```

## Setup

### 1. Create Compute Cluster

Creates a CPU cluster (`od-train-cluster-cpu`, `Standard_D4s_v3`) that scales to 0 when idle:

```bash
az ml compute create -f azureml/compute.yaml
```

### 2. Create Environment

Builds a Docker-based training environment from [azureml-environment/Dockerfile](azureml-environment/Dockerfile):

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
# or pin to an explicit version
az ml environment create -f azureml/environment.yaml --version 2
```

### 3. Register Dataset

Registers the local `datasets/coco128` folder as a versioned Azure ML data asset:

```bash
az ml data create -f azureml/dataset.yaml
```

### 4. Register Base Model

Registers the pre-trained `yolov8n.pt` weights from `models/yolov8n.pt` as a versioned model asset:

```bash
az ml model create -f azureml/model.yaml
```

## Run Training Job

Submit the job and capture the run ID for monitoring:

```bash
run_id=$(az ml job create -f azureml/job.yaml --query name -o tsv)
```

### Monitor the Job

Open the job in Azure ML Studio:

```bash
az ml job show -n $run_id --web
```

Poll the current status (`Queued` → `Running` → `Completed` / `Failed`):

```bash
az ml job show -n $run_id --query status -o tsv
```

Stream live logs to the terminal:

```bash
az ml job stream -n $run_id
```
