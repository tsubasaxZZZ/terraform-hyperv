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

  # for HTTPS
  #port            = 5986
  #https           = true
  # for HTTP
  port            = 5985
  https           = false

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

resource "hyperv_vhd" "server1" {
  path = "F:\\hyper-v\\hoge.vhdx"
  parent_path = "F:\\hyper-v\\master\\win2016.vhdx"
  vhd_type = "Differencing"
}

resource "hyperv_machine_instance" "server1" {
  name = "server1"
  generation = 2
  processor_count = 4
  static_memory = true
  memory_startup_bytes = 1024 * 1024 * 1024 * 4 # 4GB
  wait_for_state_timeout = 10
  wait_for_ips_timeout = 10

  vm_processor {
    expose_virtualization_extensions = true
    hw_thread_count_per_core = 1
  }

  network_adaptors {
      name = "internal"
      switch_name = data.hyperv_network_switch.internal.name
      wait_for_ips = false
  }

  hard_disk_drives {
    path = hyperv_vhd.server1.path
    controller_number = 0
    controller_location = 0
  }

  dvd_drives {
    controller_number = 0
    controller_location = 1
    #path = "ubuntu.iso"
  }
}
