# We first specify the terraform provider. 
# Terraform will use the provider to ensure that we can work with Microsoft Azure

terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "2.92.0"
    }
  }
}

# Here we need to mention the Azure AD Application Object credentials to allow us to work with 
# our Azure account

provider "azurerm" {
  subscription_id = "afe50e4c-141c-4971-866a4da438"
  client_id       = "cdcb390c-687c-4e8665e018"
  client_secret   = "H2T8Q~SjCzeHi.GsuMhbKo"
  tenant_id       = "b9cae6b6db29a985"
  features {}
}



locals {
  resource_group="rgdemo"
  location="East US"
}

data "azurerm_subnet" "SubnetA" {
  name                 = "default"
  virtual_network_name = "Vnet"
  resource_group_name  = "rgdemo"
}


resource "azurerm_virtual_network" "app_network" {
  name                = "Vnet"
  location            = "East US"
  resource_group_name = "rgdemo"
  address_space       = ["10.0.0.0/16"]

  subnet {
    name           = "Default"
    address_prefix = "10.0.1.0/24"
  }  
}

resource "azurerm_network_interface" "app_interface" {
  name                = "app-interface"
  location            = "East US"
  resource_group_name = "rgdemo"

  ip_configuration {
    name                          = "internal"
    subnet_id                     = data.azurerm_subnet.SubnetA.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id = azurerm_public_ip.app_public_ip.id
  }

  depends_on = [
    azurerm_virtual_network.app_network,
    azurerm_public_ip.app_public_ip
  ]
}

resource "azurerm_windows_virtual_machine" "app_vm" {
  name                = "appvm"
  resource_group_name = "rgdemo"
  location            = "East US"
  size                = "Standard_D2s_v3"
  admin_username      = "demouser"
  admin_password      = "Azure@123"
  network_interface_ids = [
    azurerm_network_interface.app_interface.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-Datacenter"
    version   = "latest"
  }

  depends_on = [
    azurerm_network_interface.app_interface
  ]
}

resource "azurerm_public_ip" "app_public_ip" {
  name                = "app-public-ip"
  resource_group_name = "rgdemo"
  location            = "East US"
  allocation_method   = "Static"
}
