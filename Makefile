SHELL := bash
.ONESHELL:
.SHELLFLAGS := -eu -o pipefail -c
.DELETE_ON_ERROR:
MAKEFLAGS += --warn-undefined-variables
MAKEFLAGS += --no-builtin-rules
MAKEFLAGS += -j$(shell grep -c 'processor' /proc/cpuinfo)
HEADLESS ?= true
QEMU_CMD = qemu-system-x86_64 -accel kvm -smp 4 -m 4096 -hda
define launch_qemu
		# We want two variables
		# Image path (i.e. what are we running)
		# socket path (i.e. how do we communicate with the QEMU agent)
    $(eval $@_image_path = $(1))
    $(eval $@_socket_path = $(2))
		qemu-system-x86_64 -accel kvm -smp 4 -m 4096 -hda ${$@_image_path} \
		-chardev socket,path=${$@_socket_path}.sock,server=on,wait=off,id=qga0 \
		-device virtio-serial \
		-device virtserialport,chardev=qga0,name=org.qemu.guest_agent.0
endef
define test_ga
		# Tests if the guest agent is running and responsive
		# Takes a path to a given socket
		# and an expected os version for comparison
    $(eval $@_socket_path = $(1))
    $(eval $@_expected_os = $(2))
		N=$$RANDOM
		echo "Check if host is alive / guest agent is listening"
		echo '{"execute":"guest-ping"}' | nc -U ${$@_socket_path} -W 1 >/dev/null
		echo "Get OS info"
		echo '{"execute":"guest-get-osinfo"}' | nc -U ${$@_socket_path} -W 1 | jq -r ".return"
		echo "Checking if expected os - Should be ${$@_expected_os}"
		echo '{"execute":"guest-get-osinfo"}' | nc -U ${$@_socket_path} -W 1 | jq .return.version | grep -i ${$@_expected_os}
		echo "Checking if guest returns nonce correctly"
		echo "{'execute':'guest-sync', 'arguments':{'id':$$N}}" | nc -U ${$@_socket_path}  -W 1 | grep $$N | jq ".return"
		#
		# Figure out if windeploy.exe is running, fail if it is
		echo "Check if windeploy.exe is running (This is an indication sysprep has not finished)"
		pid=$$(echo '{"execute":"guest-exec", "arguments": {"path": "tasklist.exe", "capture-output":true, "arg": []}}' | nc -U ${$@_socket_path} -W 1 | jq .return.pid)
		# We need to sleep to ensure it finishes running
		sleep 2
		# Note this only grabs stdout!
		res=$$(echo "{'execute': 'guest-exec-status', 'arguments': { 'pid': $$pid }}" |  nc -U ${$@_socket_path} -W 1 | jq -r '.return."out-data"'  | base64 -d | grep -ci windeploy.exe || true)
		if [ $$res -ge 1 ]; then
			echo "Sysprep / windeploy.exe still running?"
			exit 1
		fi
		echo "LGTM!"
endef

ifeq ($(origin .RECIPEPREFIX), undefined)
  $(error This Make does not support .RECIPEPREFIX. Please use GNU Make 4.0 or later)
endif
.RECIPEPREFIX = >

all: win10 win11 win2019 win2022 win2019_core win2022_core
.PHONY: all

clean:
>rm -rf output-*
.PHONY: clean

win10: output-windows_10/packer-win10_22h2
.PHONY: win10
win11: output-windows_11/packer-win11_23h2
.PHONY: win11
win2019: output-windows_2019/packer-win2019
.PHONY: win2019
win2022: output-windows_2022/packer-win2022
.PHONY: win2022
win2019_core: output-windows_2019_core/packer-win2019
.PHONY: win2019_core
win2022_core: output-windows_2022_core/packer-win2022
.PHONY: win2022_core

output-windows_10/packer-win10_22h2:
>packer build -var=headless=$(HEADLESS) win10_22h2.pkr.hcl
output-windows_11/packer-win11_23h2:
>packer build -var=headless=$(HEADLESS) win11_23h2.pkr.hcl
output-windows_2019/packer-win201:
>packer build -var=headless=$(HEADLESS) win2019.pkr.hcl
output-windows_2022/packer-win2022:
>packer build -var=headless=$(HEADLESS) win2022.pkr.hcl
output-windows_2019_core/packer-win2019:
>packer build -var=headless=$(HEADLESS) -var=vm_name=windows_2019_core -var=autounattend=answer_files/2019-core/Autounattend.xml win2019.pkr.hcl
output-windows_2022_core/packer-win2022:
>packer build -var=headless=$(HEADLESS) -var=vm_name=windows_2022_core -var=autounattend=answer_files/2022-core/Autounattend.xml win2022.pkr.hcl

# Handlers for launching images
# Used to figure out if images are bootable or not
# Be careful here - as everything is sysprep'd on first boot
# you just used that boot, so the image is no longer going
# to sysprep when you try to use it.
# Keep this in mind!
launch_win10: win10
>@$(call launch_qemu,"output-windows_10/packer-win10_22h2","/tmp/win10")
.PHONY: launch_win10
launch_win11: win11
>@$(call launch_qemu,"output-windows_11/packer-win11_23h2","/tmp/win11")
.PHONY: launch_win11
launch_win2019: win2019
>@$(call launch_qemu,"output-windows_2019/packer-win2019","/tmp/win2019")
.PHONY: launch_win2019
launch_win2022: win2022
>@$(call launch_qemu,"output-windows_2022/packer-win2022","/tmp/win2022")
.PHONY: launch_win2022
launch_win2019_core: win2019_core
>@$(call launch_qemu,"output-windows_2019_core/packer-win2019","/tmp/win2019_core")
.PHONY: launch_win2019_core
launch_win2022_core: win2022_core
>@$(call launch_qemu,"output-windows_2022_core/packer-win2022","/tmp/win2022_core")
.PHONY: launch_win2022_core

# Ensure the guest agent responds
# This is usually a sign the system has come up happily
# Fairly useful to figure out if end-to-end works locally
# However this can't check if  the machine sysprepped properly
# So make sure to eyeball it too
test_win10:
>@$(call test_ga,"/tmp/win10.sock", "Microsoft Windows 10)
test_win11:
>@$(call test_ga,"/tmp/win11.sock", "Microsoft Windows 11")
test_win2019:
>@$(call test_ga,"/tmp/win2019.sock","Microsoft Windows Server 2019")
test_win2022:
>@$(call test_ga,"/tmp/win2022.sock", "Microsoft Windows Server 2022")
test_win2019_core:
>@$(call test_ga,"/tmp/win2019_core.sock", "Microsoft Windows Server 2019")
test_win2022_core:
>@$(call test_ga,"/tmp/win2022_core.sock", "Microsoft Windows Server 2022")
