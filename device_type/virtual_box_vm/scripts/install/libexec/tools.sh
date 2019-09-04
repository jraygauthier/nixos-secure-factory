#!/usr/bin/env bash
# device_type_install_libexec_dir="$(pkg-nixos-device-type-install-get-libexec-dir)"
device_common_install_libexec_dir="$(pkg-nixos-device-common-install-get-libexec-dir)"
. "$device_common_install_libexec_dir/tools.sh"

_SUPPORTED_DEVICES=$(cat <<EOF
virtual_box_vm
EOF
)

_SUPPORTED_DEVICES_SET_STR="$(echo "$_SUPPORTED_DEVICES" | paste -d',' -s)"


is_device_virtual_box_vm() {
  lspci | grep "InnoTek Systemberatung GmbH VirtualBox Guest Service" > /dev/null && \
  lspci | grep "InnoTek Systemberatung GmbH VirtualBox Graphics Adapter" > /dev/null
}


is_supported_device() {
  is_device_virtual_box_vm
}


ensure_supported_device_from_nixos_live_cd() {
  ensure_run_from_nixos_live_cd

  is_supported_device || \
    { 1>&2 echo "ERROR: This should be run only one of the \`{${_SUPPORTED_DEVICES_SET_STR}}\` devices."; exit 1; }
}


