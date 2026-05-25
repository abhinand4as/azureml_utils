# Import required libraries.
from azure.ai.ml import MLClient
from azure.ai.ml.entities import Workspace
from azure.identity import DefaultAzureCredential
from azure.ai.ml.entities import AmlCompute

# Enter details of your subscription.
subscription_id = "00069229-bfd4-4b9b-9871-5fb492a4ac2f"
resource_group = "rg-ml-dev"

# Get a handle to the subscription.
ml_client = MLClient(DefaultAzureCredential(), subscription_id, resource_group)

# All other examples require that the connection include a workspace name.
workspace_name = "mlw-DIG-dev"  # change this if your workspace has a different name
ml_client = MLClient(DefaultAzureCredential(), subscription_id, resource_group, workspace_name)