##############################################################################
# Account Variables
##############################################################################

variable "ibmcloud_api_key" {
  description = "The IBM Cloud platform API key needed to deploy IAM enabled resources"
  type        = string
  sensitive   = true
}

variable "ibmcloud_region" {
  description = "IBM Cloud region where all resources will be deployed"
  type        = string

  validation {
    error_message = "Must use an IBM Cloud region. Use `ibmcloud regions` with the IBM Cloud CLI to see valid regions."
    condition = contains([
      "au-syd",
      "jp-tok",
      "eu-de",
      "eu-gb",
      "us-south",
      "us-east",
      "ca-tor",
      "jp-osa",
      "br-sao"
    ], var.ibmcloud_region)
  }
}

variable "vpc_name" {
  description = <<EOD
    Name of existing VPC to create LibreChat in. If this is not the same VPC as
    your vLLM cluster AND the vLLM cluster is not public, you must create a
    Transit Gateway to establish communication. Default is the VPC name used by
    default from the parent terraform's `vpc-inference-cluster`.
  EOD
  type        = string
  default     = "inference-cluster"
}

variable "openai_endpoint_name" {
  description = "Service name in LibreChat UI"
  type        = string
  default     = "vLLM"
}

variable "openai_endpoint_base_url" {
  description = "URL for OpenAI API"
  type        = string
}

variable "openai_endpoint_default_model" {
  description = "Model name served by OpenAI endpoint. This should match `served-model-name` in vLLM config."
  type        = string
  default     = "cluster-model"
}

variable "openai_endpoint_display_name" {
  description = "Model name served by OpenAI endpoint"
  type        = string
  default     = "AI Chatbot"
}

variable "prefix" {
  description = "prefix for all created resources"
  type        = string
  default     = "librechat"
}

variable "subnet_cidr" {
  description = "CIDR for address prefix and subnet for LibreChat."
  type        = string
  default     = "10.134.0.0/29"
}

variable "instance_profile" {
  description = "profile used for LibreChat virtual server instance"
  type        = string
  default     = "bx2-2x8"
}

variable "base_image_name" {
  description = "name to initiate dev instance with"
  type        = string
  default     = "ibm-ubuntu-24-04-6-minimal-amd64-1"
}

variable "ssh_key_name" {
  description = "name of ssh key to install on LibreChat server"
  type        = string
  default     = ""
}
