##############################################################################
# Terraform Outputs
##############################################################################

output "openai_endpoint_base_url" {
  value       = format("http://%s:%s/v1", ibm_is_lb.inference.hostname, ibm_is_lb_listener.inference.port)
  description = "This is the public endpoint of the application load balancer"
}
