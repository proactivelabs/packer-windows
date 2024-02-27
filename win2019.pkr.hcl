packer {
  required_plugins {
    qemu = {
      source  = "github.com/hashicorp/qemu"
      version = "~> 1"
    }

    windows-update = {
      version = "0.15.0"
      source  = "github.com/rgl/windows-update"
    }
  }
}

variable "accelerator" {
  type    = string
  default = "kvm"
}

variable "autounattend" {
  type    = string
  default = "./answer_files/2019-standard/Autounattend.xml"
}

variable "cpus" {
  type    = string
  default = "4"
}

variable "disk_size" {
  type    = string
  default = "61440"
}

variable "headless" {
  type    = string
  default = "true"
}

variable "iso_checksum" {
  type    = string
  default = "sha256:549bca46c055157291be6c22a3aaaed8330e78ef4382c99ee82c896426a1cee1"
}

variable "iso_url" {
  type    = string
  default = "https://software-download.microsoft.com/download/pr/17763.737.190906-2324.rs5_release_svc_refresh_SERVER_EVAL_x64FRE_en-us_1.iso"
}

variable "memory_size" {
  type    = string
  default = "4096"
}

variable "shutdown_command" {
  type    = string
  default = "%WINDIR%/system32/sysprep/sysprep.exe /generalize /oobe /shutdown /unattend:C:/Windows/Temp/Autounattend.xml"
}

variable "vm_name" {
  type    = string
  default = "windows_2019"
}

source "qemu" "win2019" {
  accelerator      = "${var.accelerator}"
  boot_wait        = "20s"
  communicator     = "winrm"
  cpus             = "${var.cpus}"
  disk_compression = "true"
  disk_interface   = "virtio"
  disk_size        = "${var.disk_size}"
  floppy_files     = ["${var.autounattend}", "./scripts/0-firstlogin.bat", "./scripts/1-fixnetwork.ps1", "./scripts/70-install-misc.bat", "./scripts/50-enable-winrm.ps1", "./answer_files/Firstboot/Firstboot-Autounattend.xml", "./drivers/"]
  format           = "qcow2"
  headless         = "${var.headless}"
  iso_checksum     = "${var.iso_checksum}"
  iso_url          = "${var.iso_url}"
  memory           = "${var.memory_size}"
  net_device       = "virtio-net"
  qemuargs         = [["-vga", "qxl"]]
  shutdown_command = "${var.shutdown_command}"
  winrm_insecure   = "true"
  winrm_password   = "vagrant"
  winrm_timeout    = "30m"
  winrm_use_ssl    = "true"
  winrm_username   = "vagrant"
  output_directory = "output-${var.vm_name}"
}

build {
  sources = ["source.qemu.win2019"]
  # We do this a bit backwards - because 2019 will install dotnet 4.8 as part of choco
  # But will need a reboot - so the first thing we do is reboot it when we can connect
  provisioner "windows-restart" {
    restart_check_command = "powershell -command \"& {Write-Output 'restarted.'}\""
  }
  # We also need to install chocolatey now
  provisioner "windows-shell" {
    inline = ["powershell -NoProfile -InputFormat None -ExecutionPolicy Bypass -Command \"Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))\""]
  }

  # Now we proceed as planned!
  provisioner "windows-shell" {
    execute_command = "{{ .Vars }} cmd /c C:/Windows/Temp/script.bat"
    remote_path     = "c:/Windows/Temp/script.bat"
    scripts         = ["./scripts/70-install-misc.bat", "./scripts/80-compile-dotnet-assemblies.bat"]
  }

  # Reboot after doing our first stages
  # This is to give the windows-update provisioner a chance
  # As it will seemingly hang on TiWorker.exe siting around idling
  # (This is due to registry changes in the first stage seemignly not having
  # efect until a reboot has happened)
  provisioner "windows-restart" {
    restart_check_command = "powershell -command \"& {Write-Output 'restarted.'}\""
  }

  provisioner "windows-update" {
  }

  # Without this step, your images will be ~12-15GB
  # With this step, roughly ~8-9GB
  provisioner "windows-shell" {
    execute_command = "{{ .Vars }} cmd /c C:/Windows/Temp/script.bat"
    remote_path     = "c:/Windows/Temp/script.bat"
    scripts         = ["./scripts/90-compact.bat"]
  }
}
