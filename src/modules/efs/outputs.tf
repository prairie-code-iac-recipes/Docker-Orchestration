output "wait_on" {
  description = "This output can be passed in another module's waited_on input to force an inter-module dependency."
  value       = "EFS File System Created and Mounted"
  depends_on  = [
    null_resource.mount_efs
  ]
}
