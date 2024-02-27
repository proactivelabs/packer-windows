SHELL := bash
.ONESHELL:
.SHELLFLAGS := -eu -o pipefail -c
.DELETE_ON_ERROR:
MAKEFLAGS += --warn-undefined-variables
MAKEFLAGS += --no-builtin-rules
MAKEFLAGS += -j$(shell grep -c 'processor' /proc/cpuinfo)
HEADLESS ?= true
QEMU_CMD = qemu-system-x86_64 -accel kvm -smp 4 -m 4096 -hda 

ifeq ($(origin .RECIPEPREFIX), undefined)
  $(error This Make does not support .RECIPEPREFIX. Please use GNU Make 4.0 or later)
endif
.RECIPEPREFIX = >

all: win10 win11 win2019 win2022 win2019_core win2022_core
.PHONY: all

clean:
>rm -rf output-*
.PHONY: clean

win10: output-win10_22h2/packer-win10_22h2
.PHONY: win10
win11: output-win11_23h2/packer-win11_23h2
.PHONY: win11
win2019: output-win2019/packer-win2019
.PHONY: win2019
win2022: output-win2022/packer-win2022
.PHONY: win2022
win2019_core: output-win2019_core/packer-win2019
.PHONY: win2019_core
win2022_core: output-win2022_core/packer-win2022
.PHONY: win2022_core

output-win10_22h2/packer-win10_22h2:
>packer build -var=headless=$(HEADLESS) win10_22h2.pkr.hcl
output-win11_23h2/packer-win11_23h2:
>packer build -var=headless=$(HEADLESS) win11_23h2.pkr.hcl
output-win2019/packer-win2019:
>packer build -var=headless=$(HEADLESS) win2019.pkr.hcl
output-win2022/packer-win2022:
>packer build -var=headless=$(HEADLESS) win2022.pkr.hcl
output-win2019_core/packer-win2019:
>packer build -var=headless=$(HEADLESS) -var=vm_name=win2019_core -var=autounattend=answer_files/2019-core/Autounattend.xml win2019.pkr.hcl
output-win2022_core/packer-win2022:
>packer build -var=headless=$(HEADLESS) -var=vm_name=win2022_core -var=autounattend=answer_files/2022-core/Autounattend.xml win2022.pkr.hcl

# Handlers for launching images
# Used to figure out if images are bootable or not
# Be careful here - as everything is sysprep'd on first boot
# you just used that boot, so the image is no longer going
# to sysprep when you try to use it.
# Keep this in mind!
launch_win10: win10
>$(QEMU_CMD) output-win10_22h2/packer-win10_22h2
.PHONY: launch_win10
launch_win11: win11
>$(QEMU_CMD) output-win11_23h2/packer-win11_23h2
.PHONY: launch_win11
launch_win2019: win2019
>$(QEMU_CMD) output-win2019/packer-win2019
.PHONY: launch_win2019
launch_win2022: win2022
>$(QEMU_CMD) output-win2022/packer-win2022
.PHONY: launch_win2022
launch_win2019_core: win2019_core
>$(QEMU_CMD) output-win2019_core/packer-win2019
.PHONY: launch_win2019_core
launch_win2022_core: win2022_core
>$(QEMU_CMD) output-win2022_core/packer-win2022
.PHONY: launch_win2022_core
