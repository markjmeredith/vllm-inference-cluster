##############################################################################
# Account Variables
##############################################################################

variable "ibmcloud_api_key" {
  description = <<EOD
    An IBM Cloud API key that will be used to authenticate the creation of resources needed for the
    inference cluster.

    An application programming interface key (API key) is a unique code that is passed in to an API
    to identify the calling application or user. API keys are used to track and control how the API
    is being used, for example to prevent malicious use or abuse of the API. The API key often acts
    as both a unique identifier and a secret token for authentication, and is assigned a set of
    access that is specific to the identity that is associated with it.

    To learn how to create and manage API keys, please visit the IBM Cloud documentation for
    [Managing user API Keys](https://cloud.ibm.com/docs/account?topic=account-userapikey&interface=ui).
  EOD
  type        = string
  sensitive   = true
}

variable "ibmcloud_region" {
  description = <<EOD
    The IBM Cloud VPC region where the inference cluster resources will be created.

    A region is a specific geographical location where you can deploy apps, services, and other
    IBM Cloud resources. Regions consist of one or more zones, which are physical data centers
    that house the compute, network, and storage resources, with related cooling and power, for
    host services and applications.

    To learn more about IBM Cloud regions, please visit the IBM Cloud documentation for
    [Creating a VPC in a different region](https://cloud.ibm.com/docs/vpc?topic=vpc-creating-a-vpc-in-a-different-region).
  EOD
  type        = string

  validation {
    error_message = "You must specify a valid IBM Cloud VPC Region"
    condition = contains([
      "au-syd",
      "jp-tok",
      "eu-de",
      "eu-gb",
      "us-south",
      "us-east",
      "ca-tor",
      "jp-osa",
      "br-sao",
      "eu-es"
    ], var.ibmcloud_region)
  }
}

variable "subnets" {
  description = <<EOD
    Subnets are created in the VPC to place the inference nodes in. The inference nodes are virtual
    server instances each running vLLM serving the model of your choice either from Hugging Face
    or one of your IBM Cloud Object Storage bucket.

    By default 3 subnets are created, one for each zone in the region. This allows a virtual server
    instance group with 3 inference nodes to span a region equally with 1 node (instance) in each
    zone.

    The schema provided to define subnets allows you to create 0-N subnets in each zone (1-3). Each
    zone is a list of subnet objects. The subnet object must contain a name for the subnet and a
    non-overlapping CIDR in the VPC.
  EOD
  type = object({
    zone-1 = list(object(
      {
        name = string,
        cidr = string
      }
    )),
    zone-2 = list(object(
      {
        name = string,
        cidr = string
      }
    )),
    zone-3 = list(object(
      {
        name = string,
        cidr = string
      }
    ))
  })
  default = {
    zone-1 = [{
      name = "subnet-inference-1"
      cidr = "10.10.10.0/24"
    }],
    zone-2 = [{
      name = "subnet-inference-2"
      cidr = "10.20.10.0/24"
    }],
    zone-3 = [{
      name = "subnet-inference-3"
      cidr = "10.30.10.0/24"
    }],
  }
}

variable "prefix" {
  description = <<EOD
    The prefix, or in some cases the name, for every resource created by this automation.
  EOD
  type        = string
  default     = "inference-cluster"
}

variable "resource_group_name" {
  description = <<EOD
    The name of the Resource Group every resource created by this automation will be added to. The
    API key given for the variable `ibmcloud_api_key` will need to have the Editor or Administrator
    platform access role to create resources.

    By default resources are created in the `Default` Resource Group for the account.
  EOD
  type        = string
  default     = "Default"
}

variable "inference_node_base_image_name" {
  description = <<EOD
    Each inference node is comprised of vLLM running on a virtual server instance. The base image
    name is the name of the IBM Cloud VPC stock image used as the underlying Operating System for
    vLLM to run on. The scripts included with this automation are tested with only the default
    value of this variable.

    It is possible to use another Ubuntu or Debian version provided by IBM Cloud VPC by setting
    this variable to another VPC stock image name. However, it is not supported or tested.
  EOD
  type        = string
  default     = "ibm-ubuntu-24-04-6-minimal-amd64-1"
}

variable "inference_node_instance_profile" {
  description = <<EOD
    The instance profile used to create the instance for each inference node. An instance profile
    is a combination of instance attributes, such as the number of vCPUs, amount of RAM, network
    bandwidth, and GPU type and quantity. The attributes define the size and capabilities of the
    virtual server instance that is provisioned.

    A vLLM inference node must be run by a virtual server with at least one GPU. By default an
    instance profile with a single L40s GPU is used. However, any VPC profile with a Nvidia GPU
    will work.

    Important, review pricing of these profiles before provisioning this automation. You can find
    all the GPU profiles listed in the IBM Cloud documentation for
    [x86-64 instance profiles](https://cloud.ibm.com/docs/vpc?topic=vpc-profiles&interface=ui#gpu).
    Use the [IBM Cloud cost estimator](https://www.ibm.com/cloud/cloud-calculator) to help plan
    your deployment.
  EOD
  type        = string
  default     = "gx3-24x120x1l40s"
}

variable "data_volume_capacity" {
  description = <<EOD
    Each inference node instance has a data volume attached to it. It will contain the files
    required for vLLM and the model downloaded from COS. The default size for this is 100GiB. This
    should be sufficient for most models, although for very large models you may need to increase
    the size of this volume.
  EOD
  type        = number
  default     = 100
}

variable "data_volume_profile" {
  description = <<EOD
    Each inference node instance has a data volume attached to it. It will contain the files
    required for vLLM and the model downloaded from COS. The size for this volume is determined by
    the variable `data_volume_capacity`. This variable is to set the profile of that volume. The
    profile will determine the performance (in IOPS) for it. The default profile `general-purpose`
    is a standard tier of performance. Because the model will be loaded into the GPU memory when
    used for inference, the speed of this volume will only affect the load time into the GPU
    during vLLM startup.
  EOD
  type        = string
  default     = "general-purpose"
}

variable "inference_node_ssh_key_name" {
  description = <<EOD
    Attaching an SSH key to an inference node instance can allow you to debug issues manually. By
    default no key is added to the authorized key file of the instance. Use this only for debug.
    When a key is added, an ingress security group rule is also created for the SSH port (22) from
    the IP address of the machine where the automation was applied from. This should only be used
    when deploying this IaC from your local machine (i.e., not IBM Cloud Schematics or Projects).
  EOD
  type        = string
  default     = ""
}

variable "model_cos_bucket_name" {
  description = <<EOD
    To serve a custom model stored in an IBM Cloud Object Storage bucket, specify the name of the
    bucket where the model is in. Only one model and its associated files should be in the bucket.
    You may not have more than one model in the bucket and serve it simultaneously, or switch to
    it, from the cluster.

    When a COS bucket is used to host the model, a trusted profile rule is created to allow the
    Reader role access to COS from the VPC the inference node instances are in. This allows access
    to the bucket without passing the API key to each of the instances.

    Specifying a COS bucket for the model to serve will supersede any model specified by the
    variable `model_huggingface_name`.
  EOD
  type        = string
  default     = ""
}

variable "model_huggingface_name" {
  description = <<EOD
    To use a model hosted by Hugging Face on HuggingFace.co, specify the repository slug that
    contains the model. This is generally in the format of `<organization>/<model-name>`. You
    should be able to use most text generation models.

    By default the IBM Granite version 3.1 (2B parameter) model is used.
  EOD
  type        = string
  default     = "ibm-granite/granite-3.1-2b-instruct"
}

variable "load_balancer_port" {
  description = <<EOD
    The inference nodes created are all members of a load balancer to distribute requests across
    them equally. The output of this automation `openai_endpoint_base_url` will serve an OpenAI
    compatible API for your application to communicate with. This variable is used to set the
    port number of that endpoint by the load balancer for your application to connect to.

    By default this is set to port `8080`.
  EOD
  type        = string
  default     = "8080"
}

variable "load_balancer_type" {
  description = <<EOD
    The inference nodes created are all members of a load balancer to distribute requests across
    them equally. The load balancer is private by default. This means that only other network
    interfaces that are part of the VPC will be able to access it. You can also create a bridge
    from another VPC or network boundary by using an IBM Transit Gateway.

    To expose the inference cluster to the public internet you can specify this variable as
    `public`. However, this is not recommended. The intended use case for this cluster is to be
    used by another application in IBM Cloud or through a private connection such as a VPN.
  EOD
  type        = string
  default     = "private"
}

variable "inference_node_count" {
  description = <<EOD
    An instance group is used to create N number of instances used for inference nodes. The
    instances created by the group will attempt to be spread equally across all the subnets
    defined by the variable `subnets`.

    This variable is used to request how many instances will be created and maintained by the
    instance group. If a node fails its health check or is otherwise removed, the instance group
    will create another instance to maintain the number requested.
  EOD
  type        = number
  default     = 3
}

variable "vllm_serve_options" {
  description = <<EOD
    The application vLLM is used to run inference jobs against a model and serve an OpenAI
    compatible API from the virtual server. These options are used to adjust parameters for vLLM.
    You may specify any option for the `vllm serve` command.

    See all the available options in the
    [vLLM documentation](https://docs.vllm.ai/en/latest/serving/openai_compatible_server.html#cli-reference)
  EOD
  type        = map(string)
  default = {
    # "dtype"             = "half",           # Use for V100 profiles
    "max-model-len"     = 8192,
    "served-model-name" = "cluster-model"
  }
}
