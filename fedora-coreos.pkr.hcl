variable "iso_url" {
  type        = string
  description = "The URL of the Fedora CoreOS stable ISO image."

  validation {
    condition     = can(regex("^https://builds.coreos.fedoraproject.org.*.x86_64.iso", var.iso_url))
    error_message = "The iso_url value must be a x86_64 Fedora CoreOS ISO URL."
  }
}

variable "iso_checksum" {
  type        = string
  description = "The checksum of the Fedora CoreOS stable ISO image."

  validation {
    condition     = length(var.iso_checksum) == 64
    error_message = "The iso_checksum value must be a checksum of the Fedora CoreOS stable ISO image."
  }
}

variable "release" {
  type    = string
  description = "The Fedora CoreOS release number."
}

variable "os_name" {
  type    = string
  description = "The Fedora CoreOS OS name."
}

variable "cpus" {
  type    = string
  default = "1"
}

variable "disk_size" {
  type    = string
  default = "73728"
}

variable "headless" {
  type    = bool
  default = false
}

variable "http_proxy" {
  type    = string
  default = "${env("http_proxy")}"
}

variable "https_proxy" {
  type    = string
  default = "${env("https_proxy")}"
}

variable "memory" {
  type    = string
  default = "1024"
}

variable "no_proxy" {
  type    = string
  default = "${env("no_proxy")}"
}

variable "build_directory" {
  type = string
  default = "builds"
}

locals {
  http_directory = "${path.root}/http"
  workdirpacker  = "${var.build_directory}/packer-${var.os_name}-${var.release}-virtualbox"
}

source "virtualbox-iso" "fedora-coreos" {
  boot_command            = ["curl -LO http://{{ .HTTPIP }}:{{ .HTTPPort }}/config.ign.json<enter><wait>", "sudo coreos-installer install /dev/sda --ignition-file config.ign.json && sudo reboot<enter>", "<wait3m>"]
  boot_wait               = "45s"
  cpus                    = "${var.cpus}"
  disk_size               = "${var.disk_size}"
  export_opts             = ["--manifest", "--vsys", "0", "--description", "${var.os_name} ${var.release}", "--version", "${var.release}"]
  guest_additions_mode    = "disable"
  guest_os_type           = "Linux_64"
  hard_drive_interface    = "sata"
  headless                = "${var.headless}"
  http_directory          = "${local.http_directory}"
  iso_checksum            = "sha256:${var.iso_checksum}"
  iso_url                 = "${var.iso_url}"
  keep_registered         = false
  memory                  = "${var.memory}"
  output_directory        = "${local.workdirpacker}"
  shutdown_command        = "sudo shutdown -h now"
  ssh_port                = 22
  ssh_private_key_file    = "${path.root}/files/vagrant-id_rsa"
  ssh_timeout             = "10000s"
  ssh_username            = "vagrant"
  vboxmanage              = [["modifyvm", "{{ .Name }}", "--graphicscontroller", "vmsvga"], ["modifyvm", "{{ .Name }}", "--vram", "9"]]
  virtualbox_version_file = ""
}

build {
  sources = ["source.virtualbox-iso.fedora-coreos"]

  provisioner "shell" {
    environment_vars  = ["http_proxy=${var.http_proxy}", "https_proxy=${var.https_proxy}", "no_proxy=${var.no_proxy}"]
    execute_command   = "sudo -E env {{ .Vars }} bash '{{ .Path }}'"
    expect_disconnect = false
    scripts           = ["${path.root}/provision/provision.sh"]
  }

  post-processors {
    post-processor "artifice" {
      files = ["${var.build_directory}/packer-${var.os_name}-virtualbox/info.json"]
    }
    post-processor "shell-local" {
      inline = ["echo '{\"os_name\": \"${var.os_name}\", \"release\": \"${var.release}\"}' > ${local.workdirpacker}/info.json"]
    }
  }
  post-processor "vagrant" {
    compression_level    = 9
    include              = "${local.workdirpacker}/info.json"
    output               = "${var.build_directory}/${var.os_name}-${var.release}_<no value>.box"
    provider_override    = "virtualbox"
    vagrantfile_template = "${path.root}/files/vagrantfile"
  }
}
