resource "azurerm_resource_group" "resource_group" {
  name     = "${var.organization}-script-rg"
  location = "East US"
}

module "network" {
  source              = "Azure/network/azurerm"
  resource_group_name = azurerm_resource_group.resource_group.name
  address_spaces      = [var.cidr_block]
  subnet_prefixes     = [for i in range(var.subnet_count) : cidrsubnet(var.cidr_block,8,i)]
  subnet_names        = [for i in range(var.subnet_count): "${var.organization}-Subnet${i}"]
  use_for_each        = false
  vnet_name           = "${var.organization}-vnet"
  tags = {
    name = "${var.organization}-vnet"
  }
  depends_on = [azurerm_resource_group.resource_group]
}

resource "azurerm_virtual_machine" "pubvm" {
  name                  = "${var.organization}-public-vm"
  location              = azurerm_resource_group.resource_group.location
  resource_group_name   = azurerm_resource_group.resource_group.name
  vm_size               = "Standard_B2s"
  network_interface_ids = [azurerm_network_interface.nic.id]
  zones                 = ["1"]
  os_profile {
    computer_name  = "publicVM"
    admin_username = "1CHAdministrator"
    admin_password = "Password123!"  # Replace with your desired password
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }

  storage_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  storage_os_disk {
    name              = "${var.organization}-public-vm-osdisk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }
  delete_os_disk_on_termination = true
  delete_data_disks_on_termination = false
}

resource "azurerm_virtual_machine_extension" "cse" {
  name                 = "minikube-extension"
  virtual_machine_id   = azurerm_virtual_machine.pubvm.id
  publisher            = "Microsoft.Azure.Extensions"
  type                 = "CustomScript"
  type_handler_version = "2.0"

  settings = <<SETTINGS
    {
        "script": "${filebase64("script.sh")}"
    }
  SETTINGS
}

resource "azurerm_network_interface" "nic" {
  name                = "public-vm-nic"
  location            = azurerm_resource_group.resource_group.location
  resource_group_name = azurerm_resource_group.resource_group.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = module.network.vnet_subnets[0]
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.public_ip.id
  }

  depends_on = [ azurerm_public_ip.public_ip ]
}

resource "azurerm_public_ip" "public_ip" {
  name                = "acceptanceTestPublicIp1"
  resource_group_name = azurerm_resource_group.resource_group.name
  location            = azurerm_resource_group.resource_group.location
  allocation_method   = "Static"
  sku                 = "Standard"
}

module "network-security-group" {
  source                = "Azure/network-security-group/azurerm"
  resource_group_name   = azurerm_resource_group.resource_group.name
  location              = "EastUS" # Optional; if not provided, will use Resource Group location
  security_group_name   = "nsg"

  custom_rules = [
    {
      name                   = "myssh"
      priority               = 201
      direction              = "Inbound"
      access                 = "Allow"
      protocol               = "Tcp"
      source_port_range      = "*"
      destination_port_range = "50011"
      source_address_prefix  = "*"
      description            = "description-myssh"
    },
    {
      name                    = "http"
      priority                = 200
      direction               = "Inbound"
      access                  = "Allow"
      protocol                = "Tcp"
      source_port_range       = "*"
      destination_port_range  = "80"
      source_address_prefixe  = "*"
      description             = "description-http"
    },
    {
      name                    = "https"
      priority                = 202
      direction               = "Inbound"
      access                  = "Allow"
      protocol                = "Tcp"
      source_port_range       = "*"
      destination_port_range  = "443"
      source_address_prefixe  = "*"
      description             = "description-http"
    },
    {
      name                    = "minikube1"
      priority                = 203
      direction               = "Inbound"
      access                  = "Allow"
      protocol                = "Tcp"
      source_port_range       = "*"
      destination_port_range  = "8443"
      source_address_prefixe  = "*"
      description             = "description-http"
    },
    {
      name                    = "minikube2"
      priority                = 204
      direction               = "Inbound"
      access                  = "Allow"
      protocol                = "Tcp"
      source_port_range       = "*"
      destination_port_range  = "2376"
      source_address_prefixe  = "*"
      description             = "description-http"
    },
    {
      name                    = "minikube3"
      priority                = 205
      direction               = "Inbound"
      access                  = "Allow"
      protocol                = "Tcp"
      source_port_range       = "*"
      destination_port_range  = "10250"
      source_address_prefixe  = "*"
      description             = "description-http"
    },
    {
      name                    = "minikube4"
      priority                = 206
      direction               = "Inbound"
      access                  = "Allow"
      protocol                = "Tcp"
      source_port_range       = "*"
      destination_port_range  = "32000-32767"
      source_address_prefixe  = "*"
      description             = "description-http"
    },
    {
      name                    = "kubectl_port"
      priority                = 207
      direction               = "Inbound"
      access                  = "Allow"
      protocol                = "Tcp"
      source_port_range       = "*"
      destination_port_range  = "8080"
      source_address_prefixe  = "*"
      description             = "description-http"
    },
  ]

  depends_on = [azurerm_resource_group.resource_group]
}

resource "azurerm_network_interface_security_group_association" "example" {
  network_interface_id      = azurerm_network_interface.nic.id
  network_security_group_id = module.network-security-group.network_security_group_id
}
