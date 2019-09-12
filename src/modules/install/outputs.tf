output "wait_on" {
  description = "This output can be passed in another module's waited_on input to force an inter-module dependency."
  value       = "Certificate and Software Installs Completed"
  depends_on  = [
    null_resource.apply_states
  ]
}
