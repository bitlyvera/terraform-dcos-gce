resource "google_compute_instance" "dcos-bootstrap" {
  name         = "${var.name}-dcos-bootstrap"
  machine_type = "${var.bootstrap_machine_type}"
  zone         = "${var.zone}"
  tags         = ["dcos-bootstrap", "http", "https", "ssh"]

  disk {
    image = "${var.image}"
    type  = "pd-ssd"
    size  = "200"
  }

  metadata {
    mastercount = "${var.masters}"
    clustername = "${var.name}"
    domain      = "${var.domain}"
    master_ips  = "${join("\n- ", google_compute_instance.dcos-master.*.network_interface.0.address)}"
    master_ip   = "${google_compute_instance.dcos-master.0.network_interface.0.address}"
    slave_ips   = "${join("\n- ", google_compute_instance.dcos-slave.*.network_interface.0.address)}"
    user        = "${var.gce_ssh_user}"
  }

  service_account {
    scopes = ["userinfo-email", "compute-ro", "storage-ro"]
  }

  network_interface {
    subnetwork = "${google_compute_subnetwork.dcos-net.name}"

    access_config {
      //Ephemeral IP
    }
  }

  # define default connection for remote provisioners
  connection {
    type        = "ssh"
    user        = "${var.gce_ssh_user}"
    private_key = "${file(var.gce_ssh_private_key_file)}"
  }

  provisioner "file" {
    source      = "${var.gce_ssh_private_key_file}"
    destination = "/home/${var.gce_ssh_user}/ssh_key"
  }

  provisioner "remote-exec" {
    scripts = [
      "${path.module}/scripts/common_install_redhat.sh",
      "${path.module}/scripts/bootstrap_config.sh",
    ]
  }
}

output "bootstrap_ip" {
  value = "${google_compute_instance.dcos-bootstrap.network_interface.0.access_config.0.assigned_nat_ip}"
}

output "bootstrap" {
  value = "${var.gce_ssh_user}@${google_compute_instance.dcos-bootstrap.network_interface.0.access_config.0.assigned_nat_ip}"
}
