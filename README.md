These are a set of Ansible playbooks used to deploy a single-node Kubernetes cluster with local storage, configure CSI drivers, set up a Veeam Kasten instance, create an immutable bucket for Kasten backups, and finally deploy sample applications for testing purposes. Additionally, the repository includes PowerCLI scripts for VMware environments, enabling automated virtual machine provisioning and lab lifecycle management.

## Stack
- Ubuntu 24.04
- K3s/Kubernetes 1.33.0+k3s1
- Longhorn 1.9.0
- CSI driver (snapshot controller) 6.2.1
- Veeam Kasten 8.5.6
- MinIO 1.4.4

<sup>New versions may come up as I continue the validation process.</sup>

## Demo Applications
- [Homer demo](https://github.com/ricardoconzatti/demo/tree/main/homer-demo): Apache, PHP 8.4, and PostgreSQL 16 database
- [World Dev demo](https://github.com/ricardoconzatti/demo/tree/main/world-dev): Node.js 20, MySQL 9 database, and Redis 7

## Access & Lab Lifecycle
Access to the lab is provisioned on demand. When a user requests access, an automated workflow generates a unique Lab ID and deploys the entire environment from scratch. Once provisioning is complete, access details are sent via email. The process takes about 12 minutes to conclude. Each lab environment is temporary. When the allocated time expires, the environment is fully deprovisioned, including all associated resources and data. This process is irreversible — it is not possible to recover a lab once it has been removed. Resources are not unlimited. At the moment, I can support **up to 3 labs running simultaneously**. If there is no availability when you submit your request, please wait a few minutes and try again.

**Please note that this lab runs 100% on my personal homelab infrastructure. Feel free to use it to learn and improve your knowledge of Veeam Kasten, but use it responsibly and avoid unnecessary resource consumption. This helps ensure the lab remains available and responsive for everyone.**

**[Request Lab Access](https://kasten-lab.conza.xyz)** (Beta testers token KASTEN-WM86-R9US)

---

If you’d like to access the installation and configuration step-by-step guide, just visit [this link](https://conzatech.com/testando-veeam-kasten-com-k3s-longhorn-parte-1) (it’s in Portuguese, but you can use the side menu to translate it).

### Disclaimer
The goal of this project is to provide a simple and quick way to deploy K3s with Longhorn and use Veeam Kasten to protect workloads running on Kubernetes. It’s important to highlight that all design and architecture choices described here were made to keep things as simple as possible, with the clear objective of having a functional environment for testing Veeam’s Kubernetes data protection solution. **I do not recommend following these steps for production environments.**
