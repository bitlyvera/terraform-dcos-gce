resource "google_compute_firewall" "dcos-internal" {
  name    = "${var.name}-dcos-internal"
  network = "${google_compute_network.dcos-global-net.name}"

  allow {
    protocol = "tcp"
    ports    = ["1-65535"]
  }

  allow {
    protocol = "udp"
    ports    = ["1-65535"]
  }

  allow {
    protocol = "icmp"
  }

  source_ranges = ["${google_compute_subnetwork.dcos-net.ip_cidr_range}"]
}

resource "google_compute_firewall" "dcos-http" {
  name    = "${var.name}-${var.region}-dcos-http"
  network = "${google_compute_network.dcos-global-net.name}"

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  target_tags   = ["http"]
  source_ranges = ["0.0.0.0/0"]
}

resource "google_compute_firewall" "dcos-https" {
  name    = "${var.name}-${var.region}-dcos-https"
  network = "${google_compute_network.dcos-global-net.name}"

  allow {
    protocol = "tcp"
    ports    = ["443"]
  }

  target_tags   = ["http"]
  source_ranges = ["0.0.0.0/0"]
}

resource "google_compute_firewall" "dcos-ssh" {
  name    = "${var.name}-${var.region}-dcos-ssh"
  network = "${google_compute_network.dcos-global-net.name}"

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  target_tags   = ["ssh"]
  source_ranges = ["0.0.0.0/0"]
}

resource "google_compute_firewall" "vpn" {
  name    = "${var.name}-${var.region}-vpn"
  network = "${google_compute_network.dcos-global-net.name}"

  allow {
    protocol = "udp"
    ports    = ["1194"]
  }

  target_tags   = ["vpn"]
  source_ranges = ["0.0.0.0/0"]
}
