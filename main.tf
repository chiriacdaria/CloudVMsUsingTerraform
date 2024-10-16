terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"  # Source of the Azure RM provider
      version = "3.73.0"             # Specify the provider version
    }
  }
}

provider "azurerm" {
  features {}                      # Enable provider features
  subscription_id = "your_subcription_id" # Specify your Azure subscription ID
  skip_provider_registration = true # Skip automatic provider registration
}

# Resource group
resource "azurerm_resource_group" "vm_group" {
  name     = "my-vm-group"        # Name of the resource group
  location = "West US"            # Azure region for the resource group
}

# Virtual network
resource "azurerm_virtual_network" "my_vnet" {
  name                = "my-vnet"             # Name of the virtual network
  address_space       = ["10.0.0.0/16"]       # Address space for the virtual network
  location            = azurerm_resource_group.vm_group.location # Location based on resource group
  resource_group_name = azurerm_resource_group.vm_group.name    # Resource group name
}

resource "azurerm_subnet" "my_subnet" {
  name                 = "my-subnet"               # Name of the subnet
  resource_group_name  = azurerm_resource_group.vm_group.name # Resource group name
  virtual_network_name = azurerm_virtual_network.my_vnet.name # Virtual network name
  address_prefixes     = ["10.0.1.0/24"]           # Address prefix for the subnet
}

# Variables to manage the count of each VM type
variable "linux_vm_count" {
  description = "Number of Linux VMs"   # Description for Linux VM count variable
  default     = 0                        # Default count for Linux VMs
}

variable "windows_vm_count" {
  description = "Number of Windows VMs"  # Description for Windows VM count variable
  default     = 0                        # Default count for Windows VMs
}

# Network Interface for Linux VMs
resource "azurerm_network_interface" "linux_vm_nic" {
  count               = var.linux_vm_count       # Count based on Linux VM variable
  name                = "my-linux-vm-nic-${count.index}" # NIC name with index
  location            = azurerm_resource_group.vm_group.location # Location based on resource group
  resource_group_name = azurerm_resource_group.vm_group.name    # Resource group name

  ip_configuration {
    name                          = "internal"                # Name of the IP configuration
    subnet_id                     = azurerm_subnet.my_subnet.id # Reference to subnet ID
    private_ip_address_allocation = "Dynamic"                # Dynamic allocation of private IP
  }
}

# Network Interface for Windows VMs
resource "azurerm_network_interface" "windows_vm_nic" {
  count               = var.windows_vm_count      # Count based on Windows VM variable
  name                = "my-windows-vm-nic-${count.index}" # NIC name with index
  location            = azurerm_resource_group.vm_group.location # Location based on resource group
  resource_group_name = azurerm_resource_group.vm_group.name    # Resource group name

  ip_configuration {
    name                          = "internal"                # Name of the IP configuration
    subnet_id                     = azurerm_subnet.my_subnet.id # Reference to subnet ID
    private_ip_address_allocation = "Dynamic"                # Dynamic allocation of private IP
  }
}

# Network Security Group
resource "azurerm_network_security_group" "nsg" {
  name                = "vm-nsg"                # Name of the Network Security Group
  location            = azurerm_resource_group.vm_group.location # Location based on resource group
  resource_group_name = azurerm_resource_group.vm_group.name    # Resource group name

  security_rule {
    name                       = "AllowSSH"         # Name of the security rule to allow SSH
    priority                   = 1001               # Priority for the rule
    direction                  = "Inbound"          # Direction of traffic
    access                     = "Allow"            # Allow traffic
    protocol                   = "Tcp"              # Protocol for the rule
    source_port_range          = "*"                # Source port range
    destination_port_range     = "22"               # Destination port for SSH
    source_address_prefix      = "*"                # Source address prefix
    destination_address_prefix = "*"                # Destination address prefix
  }

  security_rule {
    name                       = "AllowRDP"         # Name of the security rule to allow RDP
    priority                   = 1002               # Priority for the rule
    direction                  = "Inbound"          # Direction of traffic
    access                     = "Allow"            # Allow traffic
    protocol                   = "Tcp"              # Protocol for the rule
    source_port_range          = "*"                # Source port range
    destination_port_range     = "3389"             # Destination port for RDP
    source_address_prefix      = "*"                # Source address prefix
    destination_address_prefix = "*"                # Destination address prefix
  }
}

# Linux Virtual Machines
resource "azurerm_virtual_machine" "linux_vm" {
  count               = var.linux_vm_count         # Count based on Linux VM variable
  name                = "my-linux-vm-${count.index}" # VM name with index
  location            = azurerm_resource_group.vm_group.location # Location based on resource group
  resource_group_name = azurerm_resource_group.vm_group.name    # Resource group name
  network_interface_ids = [azurerm_network_interface.linux_vm_nic[count.index].id] # NIC ID

  storage_os_disk {
    name              = "my-linux-vm-os-disk-${count.index}" # Name of the OS disk
    caching           = "ReadWrite"                           # Caching option for the disk
    create_option     = "FromImage"                           # Create disk from image
    managed_disk_type = "Standard_LRS"                       # Type of managed disk
  }

  storage_image_reference {
    publisher = "Canonical"          # Publisher for the image
    offer     = "UbuntuServer"       # Offer for the image
    sku       = "18.04-LTS"          # SKU for the image
    version   = "latest"             # Version of the image
  }

  os_profile {
    computer_name  = "my-linux-vm-${count.index}" # Computer name for the VM
    admin_username = "adminuser"                    # Admin username
    admin_password = "AdminPassw0rd!"               # Admin password
  }

  os_profile_linux_config {
    disable_password_authentication = false        # Allow password authentication
  }
}

# Windows Virtual Machines
resource "azurerm_virtual_machine" "windows_vm" {
  count               = var.windows_vm_count         # Count based on Windows VM variable
  name                = "my-windows-vm-${count.index}" # VM name with index
  location            = azurerm_resource_group.vm_group.location # Location based on resource group
  resource_group_name = azurerm_resource_group.vm_group.name    # Resource group name
  network_interface_ids = [azurerm_network_interface.windows_vm_nic[count.index].id] # NIC ID

  storage_os_disk {
    name              = "my-windows-vm-os-disk-${count.index}" # Name of the OS disk
    caching           = "ReadWrite"                           # Caching option for the disk
    create_option     = "FromImage"                           # Create disk from image
    managed_disk_type = "Standard_LRS"                       # Type of managed disk
  }

  storage_image_reference {
    publisher = "MicrosoftWindowsServer"  # Publisher for the image
    offer     = "WindowsServer"            # Offer for the image
    sku       = "2019-Datacenter"          # SKU for the image
    version   = "latest"                   # Version of the image
  }

  os_profile {
    computer_name  = "my-windows-vm-${count.index}" # Computer name for the VM
    admin_username = "adminuser"                    # Admin username
    admin_password = "AdminPassw0rd!"               # Admin password
  }

  os_profile_windows_config {
    enable_automatic_upgrades = true  # Enable automatic upgrades for Windows
  }
}
