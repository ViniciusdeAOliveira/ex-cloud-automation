resource "azurerm_public_ip" "ip-exercise-cloud" {
  name                = "ip-exercise-cloud"
  resource_group_name = azurerm_resource_group.rg-exercise-cloud.name
  location            = azurerm_resource_group.rg-exercise-cloud.location
  allocation_method   = "Static"

  tags = {
    environment = "Production"
  }
}

resource "azurerm_network_interface" "nic-exercise-cloud" {
  name                = "nic-exercise-cloud"
  location            = azurerm_resource_group.rg-exercise-cloud.location
  resource_group_name = azurerm_resource_group.rg-exercise-cloud.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.sub-exercise-cloud.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.ip-exercise-cloud.id
  }
}

resource "azurerm_linux_virtual_machine" "vm-exercise-cloud" {
  name                            = "vm-exercise-cloud"
  resource_group_name             = azurerm_resource_group.rg-exercise-cloud.name
  location                        = azurerm_resource_group.rg-exercise-cloud.location
  size                            = "Standard_DS1_v2"
  admin_username                  = "adminuser"
  admin_password                  = "Teste!1234@"
  disable_password_authentication = false
  network_interface_ids = [
    azurerm_network_interface.nic-exercise-cloud.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }
}

resource "azurerm_network_interface_security_group_association" "nic-nsg-exercise-cloud" {
  network_interface_id      = azurerm_network_interface.nic-exercise-cloud.id
  network_security_group_id = azurerm_network_security_group.nsg-exercise-cloud.id
}


resource "null_resource" "install-nginx" {
  connection {
    type     = "ssh"
    host     = azurerm_public_ip.ip-exercise-cloud.ip_address
    user     = "adminuser"
    password = "Teste!1234@"
  }

  provisioner "remote-exec" {
    inline = ["sudo apt update",
      "sudo apt install -y nginx"
    ]
  }

  depends_on = [
    azurerm_linux_virtual_machine.vm-exercise-cloud
  ]
}
