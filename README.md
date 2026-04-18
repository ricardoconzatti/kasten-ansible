These are a set of Ansible playbooks used to deploy a single-node Kubernetes cluster with local storage, configure CSI drivers, set up a Veeam Kasten instance, create an immutable bucket for Kasten backups, and finally deploy sample applications for testing purposes.

## stack
- K3s v1.33
- Longhorn 1.9.x
- CSI driver (snapshot controller) 6.2.1
- Veeam Kasten 8.5.6
- MinIO 1.4.4 (needs to be deployed in advance)

## demo applications
- [Homer demo](https://github.com/ricardoconzatti/demo/tree/main/homer-demo): Apache, PHP 8.4, and PostgreSQL 16 database
- [World Dev demo](https://github.com/ricardoconzatti/demo/tree/main/world-dev): Node.js 20, MySQL 9 database, and Redis 7

---

If you’d like to access the installation and configuration step-by-step guide, just visit [this link](https://conzatech.com/testando-veeam-kasten-com-k3s-longhorn-parte-1) (it’s in Portuguese, but you can use the side menu to translate it).

### Disclaimer
The goal of this project is to provide a simple and quick way to deploy K3s with Longhorn and use Veeam Kasten to protect workloads running on Kubernetes. It’s important to highlight that all design and architecture choices described here were made to keep things as simple as possible, with the clear objective of having a functional environment for testing Veeam’s Kubernetes data protection solution. **I do not recommend following these steps for production environments.**
