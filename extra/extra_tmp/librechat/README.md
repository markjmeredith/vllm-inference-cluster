# LibreChat

LibreChat is the ultimate open-source app for all your AI conversations, fully customizable and compatible with any AI provider — all in one sleek interface

## Quick Start

The easiest way to deploy the cluster on IBM Cloud is to use IBM Schematics. Specify the URL of
this GitHub repository to create a Workspace. Only 2 variables are required from you to start.

| Variable | Description|
|---|---|
| `ibmcloud_api_key` | An API key to your account with access to create VPC infrastructure.|
| `ibmcloud_region` | The IBM Cloud region you'd like to deploy your cluster. Hint: Unsure? Try `br-sao`.|
| `openai_endpoint_base_url` | This is in the output of the inferencing cluster IaC |
