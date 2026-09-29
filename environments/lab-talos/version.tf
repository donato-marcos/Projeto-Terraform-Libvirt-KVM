terraform {
  required_version = ">= 1.11.0, < 2.0.0"
  required_providers {
    libvirt = {
      source  = "dmacvicar/libvirt"
      version = ">= 0.9.1, < 1.0.0"
    }
  }
}