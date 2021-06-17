terraform {
  required_providers {
    hyperv = {
      source  = "taliesins/hyperv"
      version = "1.0.3"
    }
  }
}

# Configure HyperV
provider "hyperv" {
  user            = var.user
  password        = var.password
  host            = var.host
  port            = 5986
  https           = true
  insecure        = false
  use_ntlm        = true
  script_path     = "C:/Temp/terraform_%RAND%.cmd"
  timeout         = "30s"
}

variable "user" {
 
}
variable "password" {
  
}
variable "host" {
  
}


data "hyperv_network_switch" "internal" {
  name = "internal" 
}

resource "hyperv_vhd" "web_server_g1_vhd" {
  path = "j:\\hyper-h\\web_server_g1.vhdx" #Needs to be absolute path
  size = 10737418240 #10GB
}

resource "hyperv_machine_instance" "web_server_g1" {
  name = "web_server_g1"
  generation = 1
  processor_count = 4
  static_memory = true
  memory_startup_bytes = 629145600
  wait_for_state_timeout = 10
  wait_for_ips_timeout = 10

  vm_processor {
    expose_virtualization_extensions = true
    hw_thread_count_per_core = 1
  }

  network_adaptors {
      name = "wan"
      switch_name = data.hyperv_network_switch.internal.name
      wait_for_ips = false
  }

  hard_disk_drives {
    controller_type = "Ide"
    path = hyperv_vhd.web_server_g1_vhd.path
    controller_number = 0
    controller_location = 0
  }

  dvd_drives {
    controller_number = 0
    controller_location = 1
    #path = "ubuntu.iso"
  }
}
