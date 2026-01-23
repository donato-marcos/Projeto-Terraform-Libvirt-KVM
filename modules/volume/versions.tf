terraform {
  required_version = ">= 1.11.0"
  required_providers {
    libvirt = {
      source  = "dmacvicar/libvirt"
      version = "= 0.9.1"
    }
  }
}