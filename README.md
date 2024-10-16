# CloudVMsUsingTerraform
# Azure Virtual Machine Setup with Terraform

## Overview
This project demonstrates how to deploy and configure Azure Virtual Machines (VMs) using Terraform. It includes steps to allow communication between Linux and Windows VMs and access to the internet.

## Importance of Public IP Address
In cloud environments like Azure, VMs are assigned private IP addresses that are only reachable within the same virtual network (VNet). A **public IP address** is essential for accessing these VMs from external networks, such as your local machine or the internet. Without a public IP, you cannot establish a connection to the VM for management, SSH, or Remote Desktop Protocol (RDP) access. Using public IPs allows secure, external communication with your VMs while maintaining private IPs for internal networking.

## Prerequisites
- An **Azure account**.
- **Terraform** installed on your local machine.
- **Azure CLI** installed and configured.

# General context
Azure Virtual Machines Setup

#### Network Configuration:
Both VMs are part of the same Virtual Network (VNet), allowing them to communicate with each other via their private IP addresses.
Each VM has a Network Interface Card (NIC) associated with it, which is connected to their respective NSGs.

#### Network Security Groups (NSGs):
my-linux-vm-nic-0-nsg: Rules allowing SSH and ICMP from all sources.
vm-nsg: Rules allowing RDP from all sources and ICMP traffic.

#### Internet Access:
Both VMs can access the internet due to having public IP addresses and proper NSG rules that allow outbound traffic.

#### Connectivity:
Successfully connected to the Linux VM via SSH and the Windows VM via Remote Desktop Protocol (RDP).
Enabled ICMP traffic for ping requests between the VMs.

## Summary of Current Capabilities:
You can ping and communicate between your Linux and Windows VMs using their private IP addresses.
Both VMs have internet access and can make outbound connections.
Firewall settings on both VMs allow necessary traffic for your use cases (SSH, RDP, and ICMP).

# Usage
## Resource Setup

### 1. Create a Terraform File
Create a file named `main.tf` to define the resources for the VMs you want to launch in Azure.

### 2. Decide VM Types
Choose whether to create Windows or Linux VMs, specifying the predefined image from the cloud.

## Deployment Steps

### 1. List Virtual Machines
To see your current VMs and their IP addresses, run:
```bash
az vm list-ip-addresses --resource-group my-vm-group --output table
```
### 2. Associate a Public IP
To assign a public IP address to your VMs, follow these steps:

Create a Public IP
Run the following command to create a public IP:
```bash
az network public-ip create --resource-group my-vm-group --name myPublicIP --allocation-method Static
```
Verify NIC Configuration
Check the NIC configuration for your Linux VM:
```bash
az network nic show --resource-group my-vm-group --name my-linux-vm-nic-0 --query "ipConfigurations" --output table
```
Associate the Public IP with the NIC
Run the following command to associate the public IP with your Linux VM's NIC:
```bash
az network nic ip-config update --name internal --nic-name my-linux-vm-nic-0 --resource-group my-vm-group --public-ip-address myPublicIP
```
Verify the Association
Check the NIC configuration again to ensure the public IP is associated:
```bash
az network nic show --resource-group my-vm-group --name my-linux-vm-nic-0 --query "ipConfigurations" --output table
```
Check the Public IP Address
To get the public IP address, run:
```bash
az network public-ip show --resource-group my-vm-group --name myPublicIP --query "ipAddress" --output tsv
```

### 3. Connect to VMs
Check Admin Username
Check the admin username for your Linux VM:
```bash
az vm show --resource-group my-vm-group --name my-linux-vm-0 --query "osProfile.adminUsername" --output tsv
```
Ensure the VM is Running
Ensure the VM is running before connecting:
```bash
az vm show --resource-group my-vm-group --name my-linux-vm-0 --query "powerState" --output tsv
```
(or you can check it in Azure portal)
Connect to Linux VM
Use SSH to connect to the Linux VM:
```bash
ssh adminuser@<public-ip>  # e.g., ssh adminuser@52.225.22.138
```

### 4. Connect to Windows VM via Remote Desktop
To connect to your Windows VM using Remote Desktop, follow these steps:

#### 1. Check Public IP Address: Ensure you have the public IP address of your Windows VM by running:
```bash
az vm list-ip-addresses --resource-group my-vm-group --output table
```
#### 2.Open Remote Desktop Connection:
On your local machine, search for "Remote Desktop Connection" or mstsc in the Start menu.
#### 3.Enter IP Address:
In the Remote Desktop Connection window, enter the public IP address of your Windows VM and click "Connect".
#### 4. Enter Credentials:
When prompted for credentials, enter the username and password you specified when creating the VM.
#### 5.Firewall Rule for Remote Desktop:
Ensure that the NSG associated with your Windows VM allows inbound traffic for RDP (TCP port 3389). You can create a new rule if it doesn't exist:
```bash
az network nsg rule create --resource-group my-vm-group --nsg-name vm-nsg --name Allow-RDP --priority 1002 --source-address-prefixes '*' --destination-address-prefixes '*' --destination-port-ranges 3389 --protocol Tcp --access Allow --direction Inbound
```

### 5. If Connection Doesn't Work
Add a new rule to allow SSH:
```bash
az network nsg rule create --resource-group my-vm-group --nsg-name my-linux-vm-nic-0-nsg --name Allow-SSH --priority 1000 --source-address-prefixes '*' --destination-address-prefixes '*' --destination-port-ranges 22 --protocol Tcp --access Allow --direction Inbound
```
#### Test Communication Between VMs
##### List Your VMs
To check IPs for communication:
``` bash
az vm list-ip-addresses --resource-group my-vm-group --output table
```
##### Ping Windows VM from Linux VM
To test connectivity:
```bash
ping <Windows_VM_IP>  
```

## If You Don't Receive Any Response
Ensure NSG associated with Windows VM allows inbound ICMP traffic:
```bash
az network nsg rule create --resource-group my-vm-group --nsg-name <YourNSGName> --name Allow-ICMP --priority 1004 --source-address-prefixes '*' --destination-address-prefixes '*' --destination-port-ranges '*' --protocol Icmp --access Allow --direction Inbound
```
Ensure UFW is active on Linux:
```bash
sudo ufw status
```
Ensure NSG rules for both VMs allow inbound ICMP traffic:
```bash
az network nsg rule create --resource-group my-vm-group --nsg-name vm-nsg --name Allow-ICMP --priority 1004 --source-address-prefixes '*' --destination-address-prefixes '*' --destination-port-ranges '*' --protocol Icmp --access Allow --direction Inbound
```





