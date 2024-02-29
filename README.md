# Windows / Qemu(KVM/Libvirt) Packer Templates

Builds Windows 10 (22h2), Windows 11 (22h2) Server 2022 and Server 2019 windows images.
These are suitable for consumption for QEMU and libvirt.

## Intent

Images have the following:

* Fully up to date (see `windows-update` provisioner)
* Access mechanisms:
  * winrm, rdp, and ssh enabled by default
  * username / password is "vagrant/vagrant"
* Installed packages
  * Chocolatey
  * QEMU guest additions
  * VirtIO drivers

## Prerequisites

* QEMU 8.1.5 or above
* Packer 1.9.4 or above

## Building

```bash
# We need to initialise plugins first
# any file will do, as they all have the same plugin
packer init win10_22h2.pkr.hcl 
# make everything (server builds are core)
make all
# Build with UI support, useful for debugging
packer build -var=headless=false win10_22h2.pkr.hcl
# Build with a different image
# Ensure to specify a new checksum!
packer build -var=iso_checksum=sha256:xxx -var=iso_url=http://foo.com win10_22h2.pkr.hcl
# Use a different autounattend file
packer build autounattend=./Autounattend.xml win10_22h2.pkr.hcl
```

### Windows 10

`packer build win10_22h2.pkr.hcl`

### Windows 11

`packer build win11_22h2.pkr.hcl`

### Windows Server 2019

```bash
packer build win2019.pkr.hcl
# Build core edition instead
packer build -var=autounattend=answer_files/2019-core/Autounattend.xml win2019.pkr.hcl
```

### Windows Server 2022

```bash
packer build win2022.pkr.hcl
# Build core edition instead
packer build -var=autounattend=answer_files/2022-core/Autounattend.xml win2022.pkr.hcl
```

## Building faster

* Remove the `windows-update` provisioner
  * This takes almost as long as the initial installation
* Comment out the `sdelete` command in `scripts/90-compact.bat`
  * This will save about 10 minutes on build time

## Customisations

### General customisations

Most of the time, you want to edit `scripts/70-install-misc.bat`

### Toggling sysprep

These images will sysprep on first boot, this can be disabled by specifying the following:

```bash
packer build -var=shutdown_command="shutdown /s /t 10 /f /d p:4:1 /c \"Packer Shutdown\""
```

### Checking host prepared-ness

A file based lock is implemented, which creates the text
file `C:/not-yet-finished` in `70-install-misc.bat`, and is
deleted once the `Firstboot-Autounattend.xml` has finished
running (i.e. post sysprep). A simple check has been implemented
in the `Makefile` to check for this condition.

It is recommended to check for `C:/not-yet-finished` file,
if it is not present, the host has finished sysprepping
and is ready to be used (although depending on time, you *could*
hit a situation where sysprep has run the specialise phase,
but has not yet done one final reboot. ymmv)
