# Security Policy

## Supported Versions
We currently provide security updates for the following versions:

| Version | Supported        |
| ------- | ---------------- |
| 1.0.x   | ✅ Yes           |
| < 1.0   | ❌ No            |

## Reporting a Vulnerability
The security of this project is taken seriously. If you discover a vulnerability, please **do not open a public Issue**.

Instead, follow the steps below:
1. Send an email to **[YOUR-EMAIL-HERE]** with the technical details.
2. Describe the potential impact and how to reproduce the issue.
3. You will receive a response within 48 hours acknowledging receipt.

## Best Practices
Since this project handles local infrastructure provisioning:
- Never commit `.tfstate` or `.tfvars` files that contain secrets.
- Ensure that the user running Terraform has only the necessary permissions in Libvirt.