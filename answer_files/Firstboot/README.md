# Firstboot

This is used to sysprep the host on first boot after packaging.
See ../../README for more info

Ultimately, we need three things:

* don't prompt to create a new user (we have vagrant)
* Re-license the machine (for 90 days)
* Re-enable winrm
