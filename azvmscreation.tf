provider "azurerm" {
  features {}

  subscription_id = "your subscriptionid"
  client_id       = "client_id"
  client_secret   = "client_secret"
  tenant_id       = "tenant_id"
}

variable "vm_count" {
  description = "Number of VMs to create"
  type        = number
  default     = 3
}

variable "username" {
  description = "Username for accessing the VMs"
  type        = string
  default     = "usernamefor vm"
}

variable "password" {
  description = "Password for accessing the VMs"
  type        = string
  default     = "Test@123"
}

variable "location" {
  description = "Azure region to deploy the resources"
  type        = string
  default     = "West Europe"
}

variable "existing_resource_group_name" {
  description = "Name of the existing resource group"
  type        = string
  default     = "your reource group name"
}

variable "vm_size" {
  description = "Size of the VMs"
  type        = string
  default     = "Standard_B4ms"  # Change default size to "Standard_B4ms"
}

resource "azurerm_virtual_network" "example" {
  name                = "example-network"
  address_space       = ["10.0.0.0/16"]
  location            = var.location
  resource_group_name = var.existing_resource_group_name
}

resource "azurerm_subnet" "example" {
  name                 = "example-subnet"
  resource_group_name  = var.existing_resource_group_name
  virtual_network_name = azurerm_virtual_network.example.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_network_interface" "example" {
  count               = var.vm_count
  name                = "example-nic-${count.index}"
  location            = var.location
  resource_group_name = var.existing_resource_group_name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.example.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_linux_virtual_machine" "example" {
  count                 = var.vm_count
  name                  = "example-vm-${count.index}"
  location              = var.location
  resource_group_name   = var.existing_resource_group_name
  size                  = var.vm_size
  admin_username        = var.username
  admin_password        = var.password
  network_interface_ids = [azurerm_network_interface.example[count.index].id]
  disable_password_authentication = false
  availability_set_id   = null  # Set availability_set_id to null

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts-gen2"
    version   = "latest"
  }

  secure_boot_enabled = true  # Enable secure boot
  vtpm_enabled        = true  # Enable vTPM
}
resource "azurerm_network_security_group" "example" {
  count               = var.vm_count
  name                = "example-nsg-${count.index}"
  location            = var.location
  resource_group_name = var.existing_resource_group_name
}



#resource "azurerm_network_interface_security_group_association" "edge_sg_association" {
#  count               = var.vm_count
#   network_interface_id      = azurerm_network_interface.example.[count.index].id
#  network_security_group_id = azurerm_network_security_group.example.[count.index].id

#}


resource "azurerm_network_interface_security_group_association" "example" {
  for_each = { for i in range(var.vm_count) : i => i }

  network_interface_id = azurerm_network_interface.example[each.key].id
  network_security_group_id = azurerm_network_security_group.example[each.key].id
}
