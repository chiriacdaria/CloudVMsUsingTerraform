terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.73.0"
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id = "your_subcription_id" #command to find subscription_id: az account show --query "{subscriptionId:id}" --output tsv
  skip_provider_registration = true
}

# Resource group
resource "azurerm_resource_group" "vm_group" {
  name     = "my-vm-group"
  location = "West US"
}

# Virtual network
resource "azurerm_virtual_network" "my_vnet" {
  name                = "my-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.vm_group.location
  resource_group_name = azurerm_resource_group.vm_group.name
}

resource "azurerm_subnet" "my_subnet" {
  name                 = "my-subnet"
  resource_group_name  = azurerm_resource_group.vm_group.name
  virtual_network_name = azurerm_virtual_network.my_vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Variables to manage the count of each VM type
variable "linux_vm_count" {
  description = "Number of Linux VMs"
  default     = 0
}

variable "windows_vm_count" {
  description = "Number of Windows VMs"
  default     = 0
}

# Network Interface for Linux VMs
resource "azurerm_network_interface" "linux_vm_nic" {
  count               = var.linux_vm_count
  name                = "my-linux-vm-nic-${count.index}"
  location            = azurerm_resource_group.vm_group.location
  resource_group_name = azurerm_resource_group.vm_group.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.my_subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

# Network Interface for Windows VMs
resource "azurerm_network_interface" "windows_vm_nic" {
  count               = var.windows_vm_count
  name                = "my-windows-vm-nic-${count.index}"
  location            = azurerm_resource_group.vm_group.location
  resource_group_name = azurerm_resource_group.vm_group.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.my_subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

# Network Security Group
resource "azurerm_network_security_group" "nsg" {
  name                = "vm-nsg"
  location            = azurerm_resource_group.vm_group.location
  resource_group_name = azurerm_resource_group.vm_group.name

  security_rule {
    name                       = "AllowSSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowRDP"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# Linux Virtual Machines
resource "azurerm_virtual_machine" "linux_vm" {
  count               = var.linux_vm_count
  name                = "my-linux-vm-${count.index}"
  location            = azurerm_resource_group.vm_group.location
  resource_group_name = azurerm_resource_group.vm_group.name
  network_interface_ids = [azurerm_network_interface.linux_vm_nic[count.index].id]
  vm_size             = "Standard_B1ls"

  storage_os_disk {
    name              = "my-linux-vm-os-disk-${count.index}"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  os_profile {
    computer_name  = "my-linux-vm-${count.index}"
    admin_username = "adminuser"
    admin_password = "AdminPassw0rd!"
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }
}

# Windows Virtual Machines
resource "azurerm_virtual_machine" "windows_vm" {
  count               = var.windows_vm_count
  name                = "my-windows-vm-${count.index}"
  location            = azurerm_resource_group.vm_group.location
  resource_group_name = azurerm_resource_group.vm_group.name
  network_interface_ids = [azurerm_network_interface.windows_vm_nic[count.index].id]
  vm_size             = "Standard_B1ls"

  storage_os_disk {
    name              = "my-windows-vm-os-disk-${count.index}"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  storage_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-Datacenter"
    version   = "latest"
  }

  os_profile {
    computer_name  = "my-windows-vm-${count.index}"
    admin_username = "adminuser"
    admin_password = "AdminPassw0rd!"
  }

  os_profile_windows_config {
    enable_automatic_upgrades = true
  }
}
