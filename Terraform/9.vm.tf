# Create public IPs
resource "azurerm_public_ip" "testvm_pip1" {
  name                = "testvm-pip1"
  location            = azurerm_resource_group.rg1.location
  resource_group_name = azurerm_resource_group.rg1.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

# Create network interface
resource "azurerm_network_interface" "testvm1_nic1" {
  name                = "testvm1-nic1"
  location            = azurerm_resource_group.rg1.location
  resource_group_name = azurerm_resource_group.rg1.name

  ip_configuration {
    name                          = "testvm1-ipconfig"
    subnet_id                     = azurerm_subnet.vnet1-subnet-1.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.testvm_pip1.id
  }
}

# Create virtual machine
resource "azurerm_linux_virtual_machine" "testvm1" {
  name                            = "${var.rg1_name}-testvm-1"
  location                        = azurerm_resource_group.rg1.location
  resource_group_name             = azurerm_resource_group.rg1.name
  network_interface_ids           = [azurerm_network_interface.testvm1_nic1.id]
  size                            = var.vm1_size
  disable_password_authentication = false
  os_disk {
    name                 = "myOsDisk"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  computer_name  = var.vm1_name
  admin_username = var.username
  admin_password = "India@123456"
  lifecycle {
    prevent_destroy = false
    ignore_changes  = [tags]
  }
  depends_on = [azurerm_subnet_network_security_group_association.subnet1]
}

#Testing Create Before Destroy
resource "random_password" "demo1" {
  length           = 17
  special          = true
  override_special = "_%@"
  lifecycle {
    create_before_destroy = true
  }
}

