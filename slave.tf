resource "google_compute_instance" "dcos-slave" {
  count        = "${var.slaves}"
  name         = "${var.name}-dcos-slave-${count.index}"
  machine_type = "${var.slave_machine_type}"
  zone         = "${var.zone}"
  tags         = ["dcos-slave", "http", "https", "ssh"]

  disk {
    image = "${var.image}"
    type  = "pd-ssd"
    size  = "64"
  }

  metadata {
    mastercount     = "${var.masters}"
    clustername     = "${var.name}"
    domain          = "${var.domain}"
    slave_resources = "${var.slave_resources}"
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

  # install dcos, haproxy and docker
  provisioner "remote-exec" {
    scripts = [
      "${path.module}/scripts/common_install_redhat.sh",
    ]
  }
}
