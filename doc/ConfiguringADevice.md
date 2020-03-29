# Configuring a device

Make sure that the device's live env grant your ssh id access as root.
This is what will allow the automated tools to perform the installation
without asking you for your password multiple times.

```bash
$ device-liveenv-grant-factory-ssh-access
# ..
```

Which can be tested using:

```bash
$ device-ssh-enter-as-root
# ..
```

Install the factory install tools specific to your device type:

```bash
$ device-liveenv-install-factory-tools
# ..
```


Partition and format the device hard drive:

```bash
$ device-hw-config-partition-and-format
```


Generate and deploy new secrets to the devices.

```bash
$ device-os-secrets-create-and-deploy
# ..
```

In case secrets already exist, you can instead do:

```bash
$ device-os-secrets-deploy
# ..
```

Deploy the system configuration:

```bash
$ device-os-config-build-and-deploy
# ..
```

Power of the device and remove the live usb stick:

```bash
$ device-hw-poweroff
# ..
```


## In case of a problem

It is possible to avoid having to format again and re-install everything in case
something was wrong after reboot.


```bash
$ device-liveenv-grant-factory-ssh-access
$ device-liveenv-install-factory-tools

$ device-liveenv-mount-nixos-partition
$ device-os-config-build-and-deploy

$ device-hw-poweroff
# ..
```
