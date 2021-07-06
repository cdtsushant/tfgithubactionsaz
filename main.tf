# Configure the Microsoft Azure Provider
provider "azurerm" {
  # skip_provider_registration = true
  features {}
  client_id       = "fb823935-66d4-4e98-a22e-b4d663adf9af"
  client_secret   = "tqwNY_F.-0a9MEbBGt8z.4-E41_OZn_13c"
  tenant_id       = "1c8672ad-d9cc-4f59-b839-90be132d96ab"
  subscription_id = "655f9ac4-9389-4393-a57f-3449083f6212"
}

terraform {
  backend "azurerm" {
    resource_group_name  = "AzureBackupRG_centralus_1"
    storage_account_name = "gitstorageacccount"
    container_name       = "tfstate"
    key                  = "prod.terraform.tfstate"
  }
}
#Resources which will be created
# Create a resource group
resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = "East US"
}


resource "azurerm_virtual_network" "main" {
  name                = var.vnet_name
  address_space       = ["10.30.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  dns_servers         = ["10.0.1.4"]
}

resource "azurerm_subnet" "internal" {
  name                 = "internal"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.30.2.0/24"]
}

# Public IP to reach the VM from the internet
resource "azurerm_public_ip" "public_ip" {
  name                = "public_ip"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"

}

resource "azurerm_network_security_group" "nsg" {
  name                = "TestSecurityGroup1"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "port_22"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}


# Network interface to attach the VM to the network
resource "azurerm_network_interface" "interface" {
  name                = "network_interface"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "ip_configuration"
    subnet_id                     = azurerm_subnet.internal.id
    private_ip_address_allocation = "dynamic"
    public_ip_address_id          = azurerm_public_ip.public_ip.id
  }

}

resource "azurerm_network_interface_security_group_association" "nsg_associate" {
  network_interface_id      = azurerm_network_interface.interface.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

resource "azurerm_virtual_machine" "server" {
  name                  = var.server_name
  location              = azurerm_resource_group.rg.location
  resource_group_name   = azurerm_resource_group.rg.name
  network_interface_ids = [azurerm_network_interface.interface.id]
  vm_size               = "Standard_B2s"

  delete_os_disk_on_termination = true

  # Use a Ubuntu image
  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  # Use the managed disk for storing the OS disk
  storage_os_disk {
    name              = "web_os_disk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = "server"
    admin_username = "student"
    admin_password = "Azure@654321"
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }

  depends_on = [azurerm_network_interface.interface]
}

