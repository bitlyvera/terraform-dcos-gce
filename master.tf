resource "google_compute_instance" "mesos-master" {
  count        = "${var.masters}"
  name         = "${var.name}-mesos-master-${count.index}"
  machine_type = "${var.master_machine_type}"
  zone         = "${var.zone}"
  tags         = ["mesos-master", "http", "https", "ssh", "vpn"]

  disk {
    image = "${var.image}"
    type  = "pd-ssd"
    size  = "64"
  }

  # declare metadata for configuration of the node
  metadata {
    mastercount = "${var.masters}"
    clustername = "${var.name}"
    myid        = "${count.index}"
    domain      = "${var.domain}"
    subnetwork  = "${var.subnetwork}"
  }

  service_account {
    scopes = ["userinfo-email", "compute-ro", "storage-ro"]
  }

  # network interface
  network_interface {
    subnetwork = "${google_compute_subnetwork.mesos-net.name}"

    access_config {
      // ephemeral address
    }
  }

  # define default connection for remote provisioners
  connection {
    type        = "ssh"
    user        = "${var.gce_ssh_user}"
    private_key = "${file(var.gce_ssh_private_key_file)}"
  }

  # install mesos, haproxy, docker, openvpn, and configure the node
  provisioner "remote-exec" {
    scripts = [
      "${path.module}/scripts/common_install_redhat.sh",
      "${path.module}/scripts/openvpn_install_redhat.sh",
    ]

    #"${path.module}/scripts/master_config.sh"
  }
}

output "openvpn" {
  value = "${var.gce_ssh_user}@${google_compute_instance.mesos-master.0.network_interface.0.access_config.0.assigned_nat_ip}:/home/${var.gce_ssh_user}/openvpn/client.ovpn"
}
