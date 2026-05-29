# Azure ML Setup

One-shot provisioning script for a new Azure ML project: resource group, workspace, compute cluster, and training environment.

## File Structure

```text
setup/
├── setup.sh                  # Provisioning script
├── config.json               # Project-level config (names, region, YAML paths)
└── azureml/
    ├── compute.yaml          # Default CPU compute cluster
    └── environment.yaml      # Default Python 3.10 training environment
```

## Prerequisites

- [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli) with the ML extension:
  ```bash
  az extension add --name ml
  ```
- [`jq`](https://jqlang.github.io/jq/) for config file parsing:
  ```bash
  sudo apt install jq   # Ubuntu/Debian
  brew install jq       # macOS
  ```
- An active Azure subscription logged in:
  ```bash
  az login
  ```

## Configuration

Edit `config.json` before running the script:

```json
{
    "subscription_id": "<your-subscription-id>",
    "resource_group": "<resource-group-name>",
    "workspace_name": "<workspace-name>",
    "location": "eastus",
    "compute_yaml": "setup/azureml/compute.yaml",
    "environment_yaml": "setup/azureml/environment.yaml"
}
```

| Key                | Description                                              |
|--------------------|----------------------------------------------------------|
| `subscription_id`  | Azure subscription ID                                    |
| `resource_group`   | Resource group to create or use                         |
| `workspace_name`   | Azure ML workspace name                                  |
| `location`         | Azure region (e.g. `eastus`, `westeurope`, `westus3`)   |
| `compute_yaml`     | Path to compute cluster YAML                            |
| `environment_yaml` | Path to training environment YAML                       |

All config values can be overridden with CLI flags — see [Options](#options) below.

## Usage

```bash
# Provision everything using config.json
./setup/setup.sh

# Override resource group and workspace from the command line
./setup/setup.sh -g my-rg -w my-workspace -l westeurope

# Point to a different config file
./setup/setup.sh --config /path/to/other-config.json

# Bring your own YAML files
./setup/setup.sh --compute-yaml my-compute.yaml --environment-yaml my-env.yaml

# Skip steps that are already provisioned
./setup/setup.sh --skip-rg --skip-workspace
```

## Options

| Flag                      | Description                                          |
|---------------------------|------------------------------------------------------|
| `-c, --config FILE`       | JSON config file (default: `setup/config.json`)      |
| `-g, --resource-group`    | Resource group name                                  |
| `-w, --workspace`         | Workspace name                                       |
| `-l, --location`          | Azure region                                         |
| `-s, --subscription`      | Subscription ID                                      |
| `--compute-yaml FILE`     | Compute cluster YAML                                 |
| `--environment-yaml FILE` | Training environment YAML                            |
| `--skip-rg`               | Skip resource group creation                         |
| `--skip-workspace`        | Skip workspace creation                              |
| `--skip-compute`          | Skip compute cluster creation                        |
| `--skip-environment`      | Skip environment creation                            |
| `-h, --help`              | Show help                                            |

## What Gets Provisioned

### 1. Resource Group

Created in the specified region using `az group create`.

### 2. Workspace

Azure ML workspace created with `az ml workspace create`. After creation, the script sets CLI defaults so subsequent `az ml` commands don't need `--workspace` / `--resource-group`.

### 3. Compute Cluster (`azureml/compute.yaml`)

A CPU auto-scaling cluster (`Standard_D4s_v3`) that scales down to 0 when idle to avoid unnecessary costs. Adjust `size` and `max_instances` for your workload.

```yaml
size: Standard_D4s_v3
min_instances: 0          # Always keep at 0 to avoid idle costs
max_instances: 4
idle_time_before_scale_down: 120
```

For GPU training, replace `size` with e.g. `Standard_NC6s_v3`.

### 4. Environment (`azureml/environment.yaml`)

A base Python 3.10 environment built on Microsoft's official AzureML image. Includes `azureml-core`, `azureml-mlflow`, and `mlflow`.

To use a custom Docker image instead, replace the `image` + `conda_file` block with:

```yaml
build:
  path: ../azureml-environment   # directory containing your Dockerfile
```
