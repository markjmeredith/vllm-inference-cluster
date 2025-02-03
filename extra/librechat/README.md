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

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >=1.5 |
| <a name="requirement_http"></a> [http](#requirement\_http) | 3.4.1 |
| <a name="requirement_ibm"></a> [ibm](#requirement\_ibm) | 1.60.1 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [ibm_is_floating_ip.libre](https://registry.terraform.io/providers/IBM-Cloud/ibm/1.60.1/docs/resources/is_floating_ip) | resource |
| [ibm_is_instance.libre](https://registry.terraform.io/providers/IBM-Cloud/ibm/1.60.1/docs/resources/is_instance) | resource |
| [ibm_is_security_group.libre](https://registry.terraform.io/providers/IBM-Cloud/ibm/1.60.1/docs/resources/is_security_group) | resource |
| [ibm_is_security_group_rule.in_chat](https://registry.terraform.io/providers/IBM-Cloud/ibm/1.60.1/docs/resources/is_security_group_rule) | resource |
| [ibm_is_security_group_rule.in_ssh](https://registry.terraform.io/providers/IBM-Cloud/ibm/1.60.1/docs/resources/is_security_group_rule) | resource |
| [ibm_is_security_group_rule.out](https://registry.terraform.io/providers/IBM-Cloud/ibm/1.60.1/docs/resources/is_security_group_rule) | resource |
| [ibm_is_subnet.libre](https://registry.terraform.io/providers/IBM-Cloud/ibm/1.60.1/docs/resources/is_subnet) | resource |
| [ibm_is_vpc_address_prefix.libre](https://registry.terraform.io/providers/IBM-Cloud/ibm/1.60.1/docs/resources/is_vpc_address_prefix) | resource |
| [http_http.pubip](https://registry.terraform.io/providers/hashicorp/http/3.4.1/docs/data-sources/http) | data source |
| [ibm_is_image.libre](https://registry.terraform.io/providers/IBM-Cloud/ibm/1.60.1/docs/data-sources/is_image) | data source |
| [ibm_is_ssh_key.inference](https://registry.terraform.io/providers/IBM-Cloud/ibm/1.60.1/docs/data-sources/is_ssh_key) | data source |
| [ibm_is_vpc.existing](https://registry.terraform.io/providers/IBM-Cloud/ibm/1.60.1/docs/data-sources/is_vpc) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_base_image_name"></a> [base\_image\_name](#input\_base\_image\_name) | name to initiate dev instance with | `string` | `"ibm-ubuntu-24-04-6-minimal-amd64-1"` | no |
| <a name="input_ibmcloud_api_key"></a> [ibmcloud\_api\_key](#input\_ibmcloud\_api\_key) | The IBM Cloud platform API key needed to deploy IAM enabled resources | `string` | n/a | yes |
| <a name="input_ibmcloud_region"></a> [ibmcloud\_region](#input\_ibmcloud\_region) | IBM Cloud region where all resources will be deployed | `string` | n/a | yes |
| <a name="input_instance_profile"></a> [instance\_profile](#input\_instance\_profile) | profile used for LibreChat virtual server instance | `string` | `"bx2-2x8"` | no |
| <a name="input_openai_endpoint_base_url"></a> [openai\_endpoint\_base\_url](#input\_openai\_endpoint\_base\_url) | URL for OpenAI API | `string` | n/a | yes |
| <a name="input_openai_endpoint_default_model"></a> [openai\_endpoint\_default\_model](#input\_openai\_endpoint\_default\_model) | Model name served by OpenAI endpoint. This should match `served-model-name` in vLLM config. | `string` | `"cluster-model"` | no |
| <a name="input_openai_endpoint_display_name"></a> [openai\_endpoint\_display\_name](#input\_openai\_endpoint\_display\_name) | Model name served by OpenAI endpoint | `string` | `"AI Chatbot"` | no |
| <a name="input_openai_endpoint_name"></a> [openai\_endpoint\_name](#input\_openai\_endpoint\_name) | Service name in LibreChat UI | `string` | `"vLLM"` | no |
| <a name="input_prefix"></a> [prefix](#input\_prefix) | prefix for all created resources | `string` | `"librechat"` | no |
| <a name="input_ssh_key_name"></a> [ssh\_key\_name](#input\_ssh\_key\_name) | name of ssh key to install on LibreChat server | `string` | `""` | no |
| <a name="input_subnet_cidr"></a> [subnet\_cidr](#input\_subnet\_cidr) | CIDR for address prefix and subnet for LibreChat. | `string` | `"10.134.0.0/29"` | no |
| <a name="input_vpc_name"></a> [vpc\_name](#input\_vpc\_name) | Name of existing VPC to create LibreChat in. If this is not the same VPC as<br/>    your vLLM cluster AND the vLLM cluster is not public, you must create a<br/>    Transit Gateway to establish communication. Default is the VPC name used by<br/>    default from the parent terraform's `vpc-inference-cluster`. | `string` | `"inference-cluster"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_librechat_url"></a> [librechat\_url](#output\_librechat\_url) | URL of LibreChat UI |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
