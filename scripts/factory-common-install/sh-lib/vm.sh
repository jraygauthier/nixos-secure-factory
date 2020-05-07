#!/usr/bin/env bash
common_factory_install_sh_lib_dir="$(pkg-nixos-sf-factory-common-install-get-sh-lib-dir)"
. "$common_factory_install_sh_lib_dir/tools.sh"


_DEFAULT_VM_NAME="nixos_virtual_box_vm_default"


ensure_virtualbox_installed() {
  if ! command -v VBoxManage > /dev/null; then
    1>&2 echo "ERROR: Cannot find the required 'VBoxManage' application."
    return 1
  fi
}

trim_leading_ws() {
  sed -e 's/^[[:space:]]*//'
}

list_registered_hdds() {
  hdds="$(VBoxManage list hdds | grep -e '^Location:' | cut -d':' -f2 | trim_leading_ws)"
  echo "$hdds"
}

list_registered_dvds() {
  hdds="$(VBoxManage list dvds | grep -e '^Location:' | cut -d':' -f2 | trim_leading_ws)"
  echo "$hdds"
}

list_vbox_installed_extensions() {
  extensions="$(VBoxManage list extpacks | \
    grep -E -e '^Pack no. [0-9]+:' | \
    cut -d':' -f2 | \
    trim_leading_ws)" || return 1
  echo "$extensions"
}


ensure_virtualbox_installed_with_required_extensions() {
  ensure_virtualbox_installed
  if ! list_vbox_installed_extensions \
      | grep -q -e 'Oracle VM VirtualBox Extension Pack'; then
    1>&2 echo "ERROR: Cannot find required 'VirtualBox Exension Pack'."
    return 1
  fi
}


is_vbox_vm_already_created() {
  local vm_name="${1:-${_DEFAULT_VM_NAME}}"
  VBoxManage list vms | awk '{print $1}' | grep -e "^\"${vm_name}\"$" > /dev/null
}


ensure_vbox_vm_not_exists() {
  local vm_name="${1:-${_DEFAULT_VM_NAME}}"
  ensure_virtualbox_installed_with_required_extensions

  if is_vbox_vm_already_created "$vm_name"; then
    1>&2 echo "ERROR: VBox vm with name \`$vm_name\` already exists."
    return 1
  fi
}


ensure_vbox_vm_exists() {
  local vm_name="${1:-${_DEFAULT_VM_NAME}}"
  ensure_virtualbox_installed_with_required_extensions "$vm_name"

  if ! is_vbox_vm_already_created "$vm_name"; then
    1>&2 echo "ERROR: VBox vm with name \`$vm_name\` cannot be found."
    return 1
  fi
}


show_existing_vbox_vm_info() {
  local vm_name="${1:-${_DEFAULT_VM_NAME}}"
  ensure_vbox_vm_exists "$vm_name"
  VBoxManage showvminfo "$vm_name"
}


get_vbox_vm_main_hd_filename() {
  local vm_name="${1:-${_DEFAULT_VM_NAME}}"
  local vm_hd_file="$HOME/VirtualBox VMs/${vm_name}/${vm_name}.vdi"

  echo "$vm_hd_file"
}


list_vbox_vm_storage_controllers() {
  local vm_name="${1:-${_DEFAULT_VM_NAME}}"
  ensure_vbox_vm_exists "$vm_name"

  local controllers="$(show_existing_vbox_vm_info "$vm_name" | \
    grep -e '^Storage Controller Name' | \
    cut -d':' -f2 | \
    trim_leading_ws)"

  echo "$controllers"
}


list_vbox_vm_nic_x_rules() {
  local vm_name="${1:-${_DEFAULT_VM_NAME}}"
  local defaul_nic_id="1"
  local nic_id="${2:-"${defaul_nic_id}"}"
  local rules="$(show_existing_vbox_vm_info "$vm_name" | \
    grep -E -e "^NIC ${nic_id} Rule\([0-9]+\):" | \
    cut -d':' -f2 | cut -d',' -f1 | cut -d'=' -f2 | \
    trim_leading_ws)"
  echo "$rules"
}


list_vbox_vm_shared_folders() {
  local vm_name="${1:-${_DEFAULT_VM_NAME}}"
  folders="$(show_existing_vbox_vm_info "$vm_name" | \
    grep -e '^Name:' | grep -e "Host path:" | grep -e "machine mapping" | \
    cut -d':' -f2 | cut -d',' -f1 | \
    trim_leading_ws | xargs -r echo)"
  echo "$folders"
}

configure_vbox_vm_network_aspect_using_nat() {
  echo "configure_vbox_vm_network_aspect_using_nat"
  local vm_name="${1:-${_DEFAULT_VM_NAME}}"
  ensure_vbox_vm_exists "$vm_name"

  if list_vbox_vm_nic_x_rules "$vm_name" 1 | grep -q -e '^guestssh$'; then
    VBoxManage modifyvm "$vm_name" --natpf1 delete "guestssh"
  fi
  VBoxManage modifyvm "$vm_name" --nic1 nat
  VBoxManage modifyvm "$vm_name" --natpf1 "guestssh,tcp,,2222,,22"
}


unregister_vbox_vm_hd() {
  echo "unregister_vbox_vm_hd"
  local vm_name="${1:-${_DEFAULT_VM_NAME}}"

  local default_vm_hd_file="$(get_vbox_vm_main_hd_filename "$vm_name")"
  local vm_hd_file="${2:-"${default_vm_hd_file}"}"

  if list_registered_hdds |  grep -q "$vm_hd_file"; then
    VBoxManage closemedium disk "$vm_hd_file"
  fi
}


unregister_and_destroy_vbox_vm_hd() {
  local vm_name="${1:-${_DEFAULT_VM_NAME}}"

  local default_vm_hd_file="$(get_vbox_vm_main_hd_filename "$vm_name")"
  local vm_hd_file="${2:-"${default_vm_hd_file}"}"

  if list_registered_hdds |  grep -q "$vm_hd_file"; then
    VBoxManage closemedium disk "$vm_hd_file" --delete
    # Assert that was properly deleted by previous command.
    ! test -f "$vm_hd_file"
  else
    # When was not registered, make sure it is deleted.
    rm -f "$vm_hd_file"
  fi
}


remove_vbox_vm_storage_controller_sata() {
  echo "remove_vbox_vm_storage_controller_sata"
  local vm_name="${1:-${_DEFAULT_VM_NAME}}"
  ensure_vbox_vm_exists "$vm_name"

  default_storagectl_name="SATA Controller"
  storagectl_name="${2:-"${default_storagectl_name}"}"

  if list_vbox_vm_storage_controllers "$vm_name" | grep -e "^$storagectl_name\$" > /dev/null; then
    # Detach the hd from the controller.
    # VBoxManage storageattach "$vm_name" --storagectl "$storagectl_name" \
    #   --port 0 --device 0 --type hdd --medium none
    # Remove the storage controller.
    VBoxManage storagectl "$vm_name" --name "$storagectl_name" --remove
    unregister_vbox_vm_hd "$vm_name"
  fi
}


create_or_update_vbox_vm_hd() {
  local vm_name="${1:-${_DEFAULT_VM_NAME}}"

  local default_vm_hd_file="$(get_vbox_vm_main_hd_filename "$vm_name")"
  local vm_hd_file="${2:-"${default_vm_hd_file}"}"

  local default_vm_hd_size_mb="25600"
  local vm_hd_size_mb="${3:-"${default_vm_hd_size_mb}"}"

  if ! test -f "$vm_hd_file"; then
    VBoxManage createmedium disk --filename "$vm_hd_file" --size $vm_hd_size_mb --format VDI --variant Standard
  else
    VBoxManage modifymedium disk "$vm_hd_file" --resize $vm_hd_size_mb
  fi
}


configure_vbox_vm_main_storage_aspect() {
  echo "configure_vbox_vm_main_storage_aspect"
  local vm_name="${1:-${_DEFAULT_VM_NAME}}"
  ensure_vbox_vm_exists "$vm_name"

  storagectl_name="SATA Controller"

  remove_vbox_vm_storage_controller_sata "$vm_name" "$storagectl_name"

  local default_vm_hd_file="$(get_vbox_vm_main_hd_filename "$vm_name")"
  local vm_hd_file="${2:-"${default_vm_hd_file}"}"

  # Create or update the main hard drive.
  create_or_update_vbox_vm_hd "$vm_name" "$vm_hd_file"

  VBoxManage storagectl "$vm_name" --name "$storagectl_name" --add sata --bootable on
  VBoxManage storageattach "$vm_name" --storagectl "$storagectl_name" \
    --port 0 --device 0 --type hdd --medium "$vm_hd_file"
}


# remove_vbox_vm_shared_device_nixos_config() {
#   echo "remove_vbox_vm_shared_device_nixos_config"
#   local vm_name="${1:-${_DEFAULT_VM_NAME}}"
#   ensure_vbox_vm_exists "$vm_name"
#   local shared_dir="$(get_shared_dir_from_config_file)"
#   local share_name="device_nixos_config"
#   if list_vbox_vm_shared_folders "$vm_name" | grep -q "$share_name"; then
#     VBoxManage sharedfolder remove "$vm_name" --name "$share_name"
#   fi
# }


# configure_vbox_vm_shared_repo_device_nixos_config() {
#   echo "configure_vbox_vm_shared_repo_device_nixos_config"
#   local vm_name="${1:-${_DEFAULT_VM_NAME}}"
#   ensure_vbox_vm_exists "$vm_name"
#
#   local shared_dir="$(get_shared_dir_from_config_file)"
#   local share_name="device_nixos_config"
#   remove_vbox_vm_shared_device_nixos_config "$vm_name"
#   VBoxManage sharedfolder add "$vm_name" --name "$share_name" --hostpath "$shared_dir" --automount
#   # "--transient": Can be used to mount the shared while the device is running.
# }


_make_nixos_sf_download_dir_if_required() {
  local home_cache_dir="$HOME/.cache"
  [[ -d "$home_cache_dir" ]] || mkdir -m 755 "$home_cache_dir"

  local nsf_cache_dir="$home_cache_dir/nixos-secure-factory"
  [[ -d "$nsf_cache_dir" ]] || mkdir -m 700 "$nsf_cache_dir"

  local nsf_cache_download_dir="$nsf_cache_dir/download"
  [[ -d "$nsf_cache_download_dir" ]] || mkdir -m 700 "$nsf_cache_download_dir"
}


_get_nixos_sf_download_dir() {
  _make_nixos_sf_download_dir_if_required
  echo "$HOME/.cache/nixos-secure-factory/download"
}


read_livecd_iso_filename_from_default_url() {
  local out_varname="$1"
  local DEFAULT_LIVECD_ISO_URL="https://releases.nixos.org/nixos/19.09/nixos-19.09.1936.e6391b4389e/nixos-minimal-19.09.1936.e6391b4389e-x86_64-linux.iso"
  local DEFAULT_LIVECD_ISO_URL_HASH="0byihd7l0fdqxhfxs0rsfa1k91lvvg6fdbv6cry39gl96izixbnl"
  echo "read_livecd_iso_filename_from_default_url: <${DEFAULT_LIVECD_ISO_URL}>"

  local nsf_download_dir
  nsf_download_dir="$(_get_nixos_sf_download_dir)"

  if ! TMPDIR="$nsf_download_dir" \
      nix-prefetch-url "$DEFAULT_LIVECD_ISO_URL" "$DEFAULT_LIVECD_ISO_URL_HASH"; then
    1>&2 echo "ERROR: Was unable to complete download of \`<${DEFAULT_LIVECD_ISO_URL}>\` nixos livcd iso."
    return 1
  fi

  local filename
  filename="$(TMPDIR="$nsf_download_dir" \
    nix-prefetch-url --print-path "$DEFAULT_LIVECD_ISO_URL" "$DEFAULT_LIVECD_ISO_URL_HASH" | tail -n 1)"
  # TODO: Consider pinning the store path by creating a symlink at the root of this repo (
  #       registered as a root of the Nix garbage collector same as "result" when building).
  #       We might event want to put all this stuff to a ".nix" file and built it
  #       with --out-link "nixos-minimal-my-version-my-platform-linux.iso". This would allow us to instead
  #       build it to a dir which would allow us to see a shorter name in vbox ui.
  #       Alternativement, to might even be directly retrieved as a dependancy of this project
  #       and our scritps wrapped with it ("wrapProgram"). Note that this last solution
  #       is much less lazy but much more robust and we can add mirrors.
  eval "${out_varname}=${filename}"
}


ensure_by_reading_livecd_iso_filename() {
  local out_varname="$1"
  custom_file_name="${2:-}"
  if test "" == "${custom_file_name}"; then
    read_livecd_iso_filename_from_default_url "$out_varname"
  else
    eval "${out_varname}=${custom_file_name}"
  fi
}


unregister_vbox_dvd_medias() {
  media_list="${1:-}"
  for m in $media_list; do
    VBoxManage closemedium dvd "$m"
  done
}


list_vbox_vm_storage_controller_ide_attached_media_by_uuid() {
  local vm_name="${1:-${_DEFAULT_VM_NAME}}"
  out="$(show_existing_vbox_vm_info "$vm_name" | \
    grep '^IDE Controller' | grep -v '^IDE Controller[^:]\+\:[ \t]\+Empty' | \
    sed -E -e 's/^.*UUID:[ \t]*([0-9a-zA-Z_-]+).*$/\1/')"

  if test "" == "$out"; then
    return 1
  fi

  if ! echo "$out" | grep -q -E '^[0-9a-zA-Z_-]+$'; then
    1>&2 echo "ERROR: list_vbox_vm_storage_controller_ide_attached_media: Unexpected \`out=\` value: ${out}"
    return 1
  fi
  echo "$out"
}


remove_vbox_vm_media_from_dvd_drive() {
  echo "remove_vbox_vm_media_from_dvd_drive"
  local vm_name="${1:-${_DEFAULT_VM_NAME}}"
  ensure_vbox_vm_exists "$vm_name"

  local storagectl_name="IDE Controller"

  if attached_medias="$(list_vbox_vm_storage_controller_ide_attached_media_by_uuid "$vm_name")"; then
    VBoxManage storageattach "$vm_name" --storagectl "$storagectl_name" \
      --port 0 --device 0 --type dvddrive --medium none
    # VBoxManage storageattach "$vm_name" --storagectl "$storagectl_name" \
    #   --port 0 --device 0 --type dvddrive --medium emptydrive
  fi

  if list_vbox_vm_storage_controllers "$vm_name" | grep -q -e "^$storagectl_name\$"; then
    VBoxManage storagectl "$vm_name" --name "$storagectl_name" --remove
  fi

  unregister_vbox_dvd_medias "$attached_medias"

  VBoxManage storagectl "$vm_name" --name "$storagectl_name" --add ide
  VBoxManage storageattach "$vm_name" --storagectl "$storagectl_name" \
    --port 0 --device 0 --type dvddrive --medium emptydrive
}


configure_vbox_vm_storage_controller_ide_with_empty_drive() {
  echo "configure_vbox_vm_storage_controller_ide_with_empty_drive"
  local vm_name="${1:-${_DEFAULT_VM_NAME}}"
  remove_vbox_vm_media_from_dvd_drive "$vm_name"
}


is_vbox_vm_dvd_drive_empty() {
  local vm_name="${1:-${_DEFAULT_VM_NAME}}"

  show_existing_vbox_vm_info "$vm_name" | \
    grep '^IDE Controller' | \
    awk -F':' '{ printf $2}' | \
    grep -q 'Empty'
}


insert_vbox_vm_livecd_iso_into_empty_dvd_drive() {
  echo "insert_vbox_vm_livecd_iso_into_empty_dvd_drive"
  local vm_name="${1:-${_DEFAULT_VM_NAME}}"
  ensure_vbox_vm_exists "$vm_name"

  if ! is_vbox_vm_dvd_drive_empty "$vm_name"; then
    remove_vbox_vm_media_from_dvd_drive "$vm_name"
  fi

  ensure_by_reading_livecd_iso_filename "livecd_iso_file" "${2:-}"

  local storagectl_name="IDE Controller"

  if ! list_vbox_vm_storage_controllers "$vm_name" | grep -q -e "^$storagectl_name\$"; then
    VBoxManage storagectl "$vm_name" --name "$storagectl_name" --add ide
  fi

  # "--tempeject on" corresponds to the GUI's "Live CD/DVD" checkbox.
  VBoxManage storageattach "$vm_name" --storagectl "$storagectl_name" \
    --port 0 --device 0 --type dvddrive --medium "$livecd_iso_file" \
    --tempeject on
}


configure_vbox_vm_uart1_disconnected() {
  local vm_name="${1:-${_DEFAULT_VM_NAME}}"
  ensure_vbox_vm_exists "$vm_name"
  VBoxManage modifyvm "$vm_name" --uart1 0x3F8 4 --uartmode1 disconnected
}


configure_vbox_vm_uart1_as_client_to_unix_socket() {
  local vm_name="${1:-${_DEFAULT_VM_NAME}}"
  ensure_vbox_vm_exists "$vm_name"

  local default_unix_socket_path="${vm_name}-uart1-socket"
  local unix_socket_path="${2:-"${default_unix_socket_path}"}"
  VBoxManage modifyvm "$vm_name" --uart1 0x3F8 4 --uartmode1 client "$unix_socket_path"
}


configure_vbox_vm() {
  local vm_name="${1:-${_DEFAULT_VM_NAME}}"
  ensure_vbox_vm_exists "$vm_name"

  VBoxManage modifyvm "$vm_name" --cpus 1 --memory 4096 --vram 16

  # VBoxManage modifyvm "$vm_name" --firmware bios
  VBoxManage modifyvm "$vm_name" --firmware efi

  VBoxManage modifyvm "$vm_name" --usbxhci on

  # Requiring guest additions.
  VBoxManage modifyvm "$vm_name" --clipboard bidirectional
  VBoxManage modifyvm "$vm_name" --draganddrop bidirectional

  configure_vbox_vm_network_aspect_using_nat "$vm_name"
  configure_vbox_vm_main_storage_aspect "$vm_name"
  # configure_vbox_vm_shared_repo_device_nixos_config "$vm_name"
  configure_vbox_vm_storage_controller_ide_with_empty_drive "$vm_name"
  configure_vbox_vm_uart1_disconnected "$vm_name"
}


create_new_vbox_vm_unconfigured() {
  local vm_name="${1:-${_DEFAULT_VM_NAME}}"
  ensure_vbox_vm_not_exists "$vm_name"
  VBoxManage createvm --name "${vm_name}" --ostype Linux_64 --register
}


create_new_vbox_vm() {
  local vm_name="${1:-${_DEFAULT_VM_NAME}}"
  create_new_vbox_vm_unconfigured "$vm_name"
  configure_vbox_vm "$vm_name"
}


create_new_vbox_vm_w_livecd_attached() {
  local vm_name="${1:-${_DEFAULT_VM_NAME}}"
  create_new_vbox_vm "$vm_name"
  insert_vbox_vm_livecd_iso_into_empty_dvd_drive "$vm_name"
}


destroy_vbox_vm_keeping_main_hd() {
  local vm_name="${1:-${_DEFAULT_VM_NAME}}"
  ensure_vbox_vm_exists "$vm_name"

  remove_vbox_vm_storage_controller_sata "$vm_name"
  # remove_vbox_vm_shared_device_nixos_config "$vm_name"
  remove_vbox_vm_media_from_dvd_drive "$vm_name"
  unregister_vbox_vm_hd "$vm_name"

  VBoxManage unregistervm "$vm_name" --delete
}


destroy_vbox_vm_and_main_hd() {
  local vm_name="${1:-${_DEFAULT_VM_NAME}}"
  ensure_vbox_vm_exists "$vm_name"

  destroy_vbox_vm_keeping_main_hd "$vm_name"
  unregister_and_destroy_vbox_vm_hd "$vm_name"
}


is_vbox_vm_running() {
  local vm_name="${1:-${_DEFAULT_VM_NAME}}"
  ensure_vbox_vm_exists "$vm_name"
  VBoxManage list runningvms | grep -q "$vm_name"
}


ensure_vbox_vm_running() {
  local vm_name="${1:-${_DEFAULT_VM_NAME}}"
  if ! is_vbox_vm_running "$vm_name"; then
    1>&2 echo "ERROR: Vbox vm \`$vm_name\` should be running but is stopped."
  fi
}


ensure_vbox_vm_stopped() {
  local vm_name="${1:-${_DEFAULT_VM_NAME}}"
  if is_vbox_vm_running "$vm_name"; then
    1>&2 echo "ERROR: Vbox vm \`$vm_name\` should be stopped but is running."
  fi
}


start_vbox_vm() {
  local vm_name="${1:-${_DEFAULT_VM_NAME}}"
  ensure_vbox_vm_stopped "$vm_name"

  remove_vbox_vm_media_from_dvd_drive "$vm_name"
  configure_vbox_vm_uart1_disconnected "$vm_name"
  VBoxManage startvm "$vm_name"
}


start_vbox_vm_headless() {
  local vm_name="${1:-${_DEFAULT_VM_NAME}}"
  ensure_vbox_vm_stopped "$vm_name"

  # VBoxManage modifyvm OracleLinux6Test --vrde on
  remove_vbox_vm_media_from_dvd_drive "$vm_name"
  configure_vbox_vm_uart1_disconnected "$vm_name"
  VBoxManage startvm "$vm_name" --type headless
}


start_vbox_vm_headless_entering_screen_on_virtual_serial_console() {
  local vm_name="${1:-${_DEFAULT_VM_NAME}}"
  ensure_vbox_vm_stopped "$vm_name"

  local baudrate="115200"

  local tmp_dir
  tmp_dir="$(mktemp -d)"

  local socket_path="$tmp_dir/${vm_name}-ttyS0-socket"
  local pty_path="$tmp_dir/${vm_name}-ttyS0-pty"
  rm -f "$socket_path" "$pty_path"

  insert_vbox_vm_livecd_iso_into_empty_dvd_drive "$vm_name"
  configure_vbox_vm_uart1_as_client_to_unix_socket "$vm_name" "$socket_path"

  # touch "$socket_path"
  socat "PTY,link=${pty_path},raw,echo=0,wait-slave" "UNIX-LISTEN:${socket_path}" &
  local socat_pid="$!"

  (sleep 3.5; VBoxManage startvm "$vm_name" --type headless) &

  screen "$pty_path" "$baudrate"

  kill -s "SIGINT" "$socat_pid"
}


stop_vbox_vm() {
  local vm_name="${1:-${_DEFAULT_VM_NAME}}"
  ensure_vbox_vm_running "$vm_name"

  VBoxManage controlvm "$vm_name" acpipowerbutton
}

stop_vbox_vm_forced() {
  local vm_name="${1:-${_DEFAULT_VM_NAME}}"
  ensure_vbox_vm_running "$vm_name"

  VBoxManage controlvm "$vm_name" poweroff
}
