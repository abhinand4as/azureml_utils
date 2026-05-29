#!/usr/bin/env bash
set -euo pipefail

# ─── Colours ────────────────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'
log()  { echo -e "${BLUE}[INFO]${NC}  $*"; }
ok()   { echo -e "${GREEN}[ OK ]${NC}  $*"; }
warn() { echo -e "${YELLOW}[WARN]${NC}  $*"; }
err()  { echo -e "${RED}[ERR ]${NC}  $*" >&2; }

# ─── Usage ──────────────────────────────────────────────────────────────────
usage() {
  cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Provision Azure ML infrastructure for a new project:
  1. Resource group
  2. Workspace
  3. Compute cluster
  4. Training environment

Options:
  -c, --config FILE            JSON config file  (default: <script-dir>/config.json)
  -g, --resource-group NAME    Resource group name         (overrides config)
  -w, --workspace NAME         Workspace name              (overrides config)
  -l, --location REGION        Azure region                (overrides config, default: eastus)
  -s, --subscription ID        Subscription ID             (overrides config)
      --compute-yaml FILE      Compute cluster YAML        (overrides config)
      --environment-yaml FILE  Environment YAML            (overrides config)
      --skip-rg                Skip resource group step
      --skip-workspace         Skip workspace step
      --skip-compute           Skip compute step
      --skip-environment       Skip environment step
  -h, --help                   Show this message

Config file keys (JSON):
  subscription_id, resource_group, workspace_name, location,
  compute_yaml, environment_yaml

Examples:
  # Use defaults from config.json
  ./setup.sh

  # Override workspace and region
  ./setup.sh -g my-rg -w my-workspace -l westeurope

  # Bring your own YAML files
  ./setup.sh --compute-yaml path/to/compute.yaml --environment-yaml path/to/env.yaml

  # Skip steps that are already provisioned
  ./setup.sh --skip-rg --skip-workspace
EOF
}

# ─── Defaults ───────────────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

CONFIG_FILE="$SCRIPT_DIR/config.json"
RESOURCE_GROUP=""
WORKSPACE=""
LOCATION=""
SUBSCRIPTION=""
COMPUTE_YAML=""
ENVIRONMENT_YAML=""
SKIP_RG=false
SKIP_WORKSPACE=false
SKIP_COMPUTE=false
SKIP_ENVIRONMENT=false

# ─── Argument parsing ────────────────────────────────────────────────────────
while [[ $# -gt 0 ]]; do
  case "$1" in
    -c|--config)             CONFIG_FILE="$2";       shift 2 ;;
    -g|--resource-group)     RESOURCE_GROUP="$2";    shift 2 ;;
    -w|--workspace)          WORKSPACE="$2";         shift 2 ;;
    -l|--location)           LOCATION="$2";          shift 2 ;;
    -s|--subscription)       SUBSCRIPTION="$2";      shift 2 ;;
    --compute-yaml)          COMPUTE_YAML="$2";      shift 2 ;;
    --environment-yaml)      ENVIRONMENT_YAML="$2";  shift 2 ;;
    --skip-rg)               SKIP_RG=true;           shift ;;
    --skip-workspace)        SKIP_WORKSPACE=true;    shift ;;
    --skip-compute)          SKIP_COMPUTE=true;      shift ;;
    --skip-environment)      SKIP_ENVIRONMENT=true;  shift ;;
    -h|--help)               usage; exit 0 ;;
    *) err "Unknown option: $1"; usage; exit 1 ;;
  esac
done

# ─── Dependency check ────────────────────────────────────────────────────────
for cmd in az jq; do
  if ! command -v "$cmd" &>/dev/null; then
    err "'$cmd' is required but not installed."
    [[ "$cmd" == "jq" ]] && err "  Install with: sudo apt install jq  (or brew install jq)"
    exit 1
  fi
done

# ─── Load config file ────────────────────────────────────────────────────────
# Helper: read a key from the JSON config, return empty string if missing
cfg() { jq -r "$1 // empty" "$CONFIG_FILE" 2>/dev/null || true; }

if [[ -f "$CONFIG_FILE" ]]; then
  log "Loading config: $CONFIG_FILE"
  RESOURCE_GROUP="${RESOURCE_GROUP:-$(cfg '.resource_group')}"
  WORKSPACE="${WORKSPACE:-$(cfg '.workspace_name')}"
  LOCATION="${LOCATION:-$(cfg '.location')}"
  SUBSCRIPTION="${SUBSCRIPTION:-$(cfg '.subscription_id')}"
  COMPUTE_YAML="${COMPUTE_YAML:-$(cfg '.compute_yaml')}"
  ENVIRONMENT_YAML="${ENVIRONMENT_YAML:-$(cfg '.environment_yaml')}"
else
  warn "Config file not found at $CONFIG_FILE — relying on CLI arguments."
fi

# ─── Apply built-in defaults ─────────────────────────────────────────────────
LOCATION="${LOCATION:-eastus}"
COMPUTE_YAML="${COMPUTE_YAML:-$SCRIPT_DIR/azureml/compute.yaml}"
ENVIRONMENT_YAML="${ENVIRONMENT_YAML:-$SCRIPT_DIR/azureml/environment.yaml}"

# ─── Validate ────────────────────────────────────────────────────────────────
missing=()
[[ -z "$RESOURCE_GROUP" ]] && missing+=("resource group (-g / config: resource_group)")
[[ -z "$WORKSPACE" ]]      && missing+=("workspace (-w / config: workspace_name)")
if [[ ${#missing[@]} -gt 0 ]]; then
  for m in "${missing[@]}"; do err "Missing required value: $m"; done
  exit 1
fi

# ─── Summary ─────────────────────────────────────────────────────────────────
echo
log "Provisioning plan:"
log "  Subscription     : ${SUBSCRIPTION:-<current account>}"
log "  Resource Group   : $RESOURCE_GROUP"
log "  Workspace        : $WORKSPACE"
log "  Location         : $LOCATION"
log "  Compute YAML     : $COMPUTE_YAML"
log "  Environment YAML : $ENVIRONMENT_YAML"
echo

# ─── 0. Set subscription ─────────────────────────────────────────────────────
if [[ -n "$SUBSCRIPTION" ]]; then
  log "Setting active subscription..."
  az account set --subscription "$SUBSCRIPTION"
  ok "Subscription: $SUBSCRIPTION"
fi

# ─── 1. Resource group ───────────────────────────────────────────────────────
if [[ "$SKIP_RG" == false ]]; then
  log "Creating resource group '$RESOURCE_GROUP' in '$LOCATION'..."
  az group create \
    --name     "$RESOURCE_GROUP" \
    --location "$LOCATION" \
    --output   none
  ok "Resource group '$RESOURCE_GROUP' ready."
else
  warn "Skipping resource group creation."
fi

# ─── 2. Workspace ────────────────────────────────────────────────────────────
if [[ "$SKIP_WORKSPACE" == false ]]; then
  log "Creating workspace '$WORKSPACE'..."
  az ml workspace create \
    --name           "$WORKSPACE" \
    --resource-group "$RESOURCE_GROUP" \
    --location       "$LOCATION" \
    --output         none
  ok "Workspace '$WORKSPACE' ready."
else
  warn "Skipping workspace creation."
fi

# Set CLI defaults so subsequent commands don't need --workspace / --resource-group
az configure --defaults workspace="$WORKSPACE" group="$RESOURCE_GROUP"
log "CLI defaults set: workspace=$WORKSPACE, group=$RESOURCE_GROUP"

# ─── 3. Compute ──────────────────────────────────────────────────────────────
if [[ "$SKIP_COMPUTE" == false ]]; then
  [[ ! -f "$COMPUTE_YAML" ]] && { err "Compute YAML not found: $COMPUTE_YAML"; exit 1; }
  log "Creating compute cluster from $COMPUTE_YAML..."
  az ml compute create \
    --file           "$COMPUTE_YAML" \
    --resource-group "$RESOURCE_GROUP" \
    --workspace-name "$WORKSPACE" \
    --output         none
  ok "Compute cluster ready."
else
  warn "Skipping compute creation."
fi

# ─── 4. Environment ──────────────────────────────────────────────────────────
if [[ "$SKIP_ENVIRONMENT" == false ]]; then
  [[ ! -f "$ENVIRONMENT_YAML" ]] && { err "Environment YAML not found: $ENVIRONMENT_YAML"; exit 1; }
  log "Creating environment from $ENVIRONMENT_YAML..."
  az ml environment create \
    --file           "$ENVIRONMENT_YAML" \
    --resource-group "$RESOURCE_GROUP" \
    --workspace-name "$WORKSPACE" \
    --output         none
  ok "Environment ready."
else
  warn "Skipping environment creation."
fi

# ─── Done ────────────────────────────────────────────────────────────────────
echo
ok "Azure ML setup complete."
log "  Studio URL : https://ml.azure.com/workspaces/$WORKSPACE/overview?wsid=/subscriptions/${SUBSCRIPTION:-<subscription-id>}/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.MachineLearningServices/workspaces/$WORKSPACE"
