# Microsoft Learn references

These links are the Microsoft material I would keep next to the labs. They give the concepts, product documentation and exam scope; this repository gives you a compact environment to practice the commands and failure cases.

Links checked in September 2026.

## AZ-802 course and exam

- [Course AZ-802T00-A: Administer Windows Server](https://learn.microsoft.com/en-us/training/courses/az-802t00)
- [Exam AZ-802: Administering Windows Server](https://learn.microsoft.com/en-us/credentials/certifications/exams/az-802/)
- [Study guide for Exam AZ-802](https://learn.microsoft.com/en-us/credentials/certifications/resources/study-guides/az-802)
- [MicrosoftLearning AZ-802 lab repository](https://github.com/MicrosoftLearning/AZ-802-Windows-Server-Administrator-Associate)

The current AZ-802 study guide groups the exam around AD DS, hybrid Windows Server management, virtual machines, networking, storage/file services, security, and monitoring/troubleshooting. The folders in this repository follow the same broad shape, with an extra foundation module for initial configuration.

## Module mapping

| Repository module | Microsoft Learn |
| --- | --- |
| Environment preparation | [Windows Server deployment, configuration, and administration](https://learn.microsoft.com/en-us/training/paths/windows-server-deployment-configuration-administration/) · [Get started with Windows PowerShell](https://learn.microsoft.com/en-us/training/paths/get-started-windows-powershell/) |
| Module 1: Initial configuration | [Windows Server deployment, configuration, and administration](https://learn.microsoft.com/en-us/training/paths/windows-server-deployment-configuration-administration/) · [Get started with Windows PowerShell](https://learn.microsoft.com/en-us/training/paths/get-started-windows-powershell/) |
| Module 2: Active Directory | [Deploy and manage Active Directory Domain Services](https://learn.microsoft.com/en-us/training/paths/deploy-manage-active-directory-domain-services/) · [Active Directory Domain Services](https://learn.microsoft.com/en-us/training/paths/active-directory-domain-services/) |
| Module 3: Remote administration | [Manage Windows Server instances and workloads in a hybrid environment](https://learn.microsoft.com/en-us/training/paths/manage-windows-server-instances-workloads-hybrid-environment/) · [Administer remote computers by using Windows PowerShell](https://learn.microsoft.com/en-us/training/paths/administer-remote-computers-use-windows-powershell/) · [OpenSSH for Windows](https://learn.microsoft.com/en-us/windows-server/administration/openssh/openssh_install_firstuse) |
| Module 4: Hyper-V | [Manage Virtual Machines](https://learn.microsoft.com/en-us/training/paths/manage-virtual-machines/) · [Windows Server Hyper-V and Virtualization](https://learn.microsoft.com/en-us/training/paths/windows-server-hyper-v-virtualization/) |
| Module 5: Network services | [Windows Server Network Infrastructure](https://learn.microsoft.com/en-us/training/paths/windows-server-network-infrastructure/) · [Implement and operate an on-premises and hybrid networking infrastructure](https://learn.microsoft.com/en-us/training/paths/implement-operate-premises-hybrid/) · [Administer Internet Information Services](https://learn.microsoft.com/en-us/training/paths/administer-internet-information-services/) |
| Module 6: Storage and file services | [Manage storage and file services](https://learn.microsoft.com/en-us/training/paths/manage-storage-file-services/) · [Windows Server high availability](https://learn.microsoft.com/en-us/training/paths/windows-server-high-availability/) |
| Module 7: Security, monitoring and IR | [Secure Windows Server infrastructure](https://learn.microsoft.com/en-us/training/paths/secure-windows-server-infrastructure/) · [Monitor and Troubleshoot Windows Server Environments](https://learn.microsoft.com/en-us/training/paths/monitor-troubleshoot-windows-server-environments/) |

## How to use the links

For a new topic, read the matching Learn module first or keep it open while you run the lab. When the repository script uses a command you do not recognize, use `Get-Help` and the product documentation rather than treating the script as a black box.

Microsoft can change exam objectives and training content. For exam preparation, the current AZ-802 study guide is the source to check for the latest measured skills.
