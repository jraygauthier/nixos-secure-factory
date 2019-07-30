#!/usr/bin/env bash
common_factory_install_libexec_dir="$(pkg_nixos_factory_common_install_get_libexec_dir)"
# Source both dependencies.
. "$common_factory_install_libexec_dir/tools.sh"
. "$common_factory_install_libexec_dir/vm.sh"
. "$common_factory_install_libexec_dir/app_current_device_store.sh"




start_vm_device() {
  vm_name="$(get_required_current_device_id)"
  if ! is_vbox_vm_running "$vm_name"; then
    start_vbox_vm "$vm_name"
  else
    1>&2 echo "WARNING: VM \`$vm_name\` was already started. Some changes might not be taken into account."
  fi
}


start_vm_device_headless() {
  vm_name="$(get_required_current_device_id)"
  if ! is_vbox_vm_running "$vm_name"; then
    start_vbox_vm_headless "$vm_name"
  else
    1>&2 echo "WARNING: VM \`$vm_name\` was already started. Some changes might not be taken into account."
  fi
}


start_vm_device_headless_w_serial_console() {
  vm_name="$(get_required_current_device_id)"

  if is_vbox_vm_running "$vm_name"; then
    1>&2 echo "ERROR: VM \`$vm_name\` was already started."
    exit 1
  fi

  start_vbox_vm_headless_entering_screen_on_virtual_serial_console "$vm_name"
}


stop_vm_device() {
  vm_name="$(get_required_current_device_id)"
  if is_vbox_vm_running "$vm_name"; then
    stop_vbox_vm "$vm_name"
    sleep 1.0
    if is_vbox_vm_running "$vm_name"; then
      stop_vbox_vm_forced "$vm_name"
    fi
  else
    echo "VM \`$vm_name\` was already stopped."
  fi
}


deploy_vm_device() {
  vm_name="$(get_required_current_device_id)"
  if ! is_vbox_vm_already_created "$vm_name"; then
    create_new_vbox_vm "$vm_name"
  else
    # TODO: Would it be possible to ensure removal of livedvd?
    echo "VM \`$vm_name\` was already created."
  fi

  start_vm_device "$vm_name"
}

destroy_vm_device() {
  vm_name="$(get_required_current_device_id)"
  stop_vm_device "$vm_name"

  if is_vbox_vm_already_created "$vm_name"; then
    destroy_vbox_vm_and_main_hd "$vm_name"
  fi
}

destroy_all_vm_devices() {
  false # TODO: Implement
}


deploy_vm_device_headless() {
  vm_name="$(get_required_current_device_id)"
  if ! is_vbox_vm_already_created "$vm_name"; then
    create_new_vbox_vm "$vm_name"
  else
    # TODO: Would it be possible to ensure removal of livedvd?
    echo "VM \`$vm_name\` was already created."
  fi

  start_vm_device_headless "$vm_name"
}


deploy_vm_device_headless_factory_reset() {
  vm_name="$(get_required_current_device_id)"
  if ! is_vbox_vm_already_created "$vm_name"; then
    create_new_vbox_vm_w_livecd_attached "$vm_name"
  else
    # TODO: Would it be possible to ensure removal of livedvd?
    echo "VM \`$vm_name\` was already created."
  fi

  if is_vbox_vm_running "$vm_name"; then
    1>&2 echo "ERROR: VM \`$vm_name\` was already started."
    exit 1
  fi

  start_vbox_vm_headless_entering_screen_on_virtual_serial_console "$vm_name"
}
