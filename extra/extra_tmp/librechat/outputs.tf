output "librechat_url" {
  description = "URL of LibreChat UI"
  value       = format("http://%s:3080", ibm_is_floating_ip.libre.address)
}
