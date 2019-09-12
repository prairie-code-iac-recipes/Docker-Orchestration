output "wait_on" {
  description = "This output can be passed in another module's waited_on input to force an inter-module dependency."
  value       = "Docker Swarm Initialized"
  depends_on  = [
    null_resource.swarm_manager_registration,
    null_resource.swarm_worker_registration
  ]
}
