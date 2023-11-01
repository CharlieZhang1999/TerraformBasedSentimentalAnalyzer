output "ip" {
  value = data.google_compute_instance.master.network_interface.0.access_config.0.nat_ip
}