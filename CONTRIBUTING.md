# Contributing to the Terraform-Libvirt-KVM Project

First of all, thank you for your interest in contributing! This project aims to simplify local infrastructure provisioning in an efficient and secure way.

## 🛠 Development Prerequisites

To ensure your changes work properly, your local environment should have:
* **Terraform** (v1.0+)
* **Libvirt** installed and the `libvirtd` service running
* **QEMU/KVM** properly configured
* The **Terraform Libvirt Provider** plugin correctly installed

## 🚀 How to Contribute

1. Fork the project.
2. Create a branch for your changes: `git checkout -b feature/my-improvement`.
3. Run the formatting command: `terraform fmt`. **PRs with unformatted code will not be accepted.**
4. Validate your changes: `terraform validate`.
5. If possible, perform a real test: `terraform apply` (be mindful of your host resources).
6. Push your branch and open a Pull Request.

## 📏 Code Standards

* **Variables:** Must always include a `description` field and, if appropriate, a `default`.
* **Outputs:** Always define outputs for useful information (such as VM IP addresses).
* **README:** If you add a new feature or variable, update the relevant README files.

## 🛡 Security
Never commit `.tfvars` files containing sensitive data or private SSH keys. Use the existing `.gitignore` file in the project.

## 💬 Community and Conduct
When interacting in this project, follow standards of respect and technical collaboration.