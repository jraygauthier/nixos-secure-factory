#!/usr/bin/env bash
common_factory_install_sh_lib_dir="$(pkg-nixos-sf-factory-common-install-get-sh-lib-dir)"
# Source all dependencies:
. "$common_factory_install_sh_lib_dir/app_current_device_ssh.sh"
. "$common_factory_install_sh_lib_dir/app_current_device_store.sh"


is_x11vnc_pid_stopped() {
  local vnc_user="${1?}"
  local vnc_hostname="${2?}"
  local device_ssh_port="${3?}"
  local vnc_port="${4?}"
  shift 4

  if ! ssh "${vnc_user}@${vnc_hostname}" -p "${device_ssh_port}" "lsof -i :'${vnc_port}'"  >/dev/null; then
    echo "Status: is_x11vnc_pid_stopped"
    return 0
  fi

  echo "Status: X11vnc pid already exist."
  return 1
}

exit_x11vnc() {
  local vnc_user="${1?}"
  local vnc_hostname="${2?}"
  local device_ssh_port="${3?}"
  shift 3

  echo "Closing X11VNC"
  if ! ssh "${vnc_user}@${vnc_hostname}" -p "${device_ssh_port}" 'x11vnc -remote stop -display :0' >/dev/null; then
    local err="$?"
    1>&2 echo "Error: $FUNCNAME: $err"
    return "$err"
  fi
}

is_x11vnc_systemd_process_stopped() {
  local vnc_user="${1?}"
  local vnc_hostname="${2?}"
  local device_ssh_port="${3?}"
  local systemd_service_name="${4?}"
  shift 4

  if ! ssh "${vnc_user}@${vnc_hostname}" -p "${device_ssh_port}" "systemctl -q --no-pager --user status '${systemd_service_name}'"  >/dev/null; then
    echo "Status: is_x11vnc_service_stopped: $?"
    return 0
  fi

  echo "Status: X11vnc systemd is already started. $?"
  return 1
}

close_x11vnc_systemd_process() {
  local vnc_user="${1?}"
  local vnc_hostname="${2?}"
  local device_ssh_port="${3?}"
  local systemd_service_name="${4?}"
  shift 4

  echo "Closing systemd process"
  if ! ssh "${vnc_user}@${vnc_hostname}" -p "${device_ssh_port}" "systemctl -q --no-pager --user stop '${systemd_service_name}'" >/dev/null; then
    local err="$?"
    1>&2 echo "Error: $FUNCNAME: $err"
    return "$err"
  fi
}

enter_vnc_as_user() {
  local vnc_user="${1?}"
  shift 1

  local systemd_service_name="nixos-secure-factory-x11"
  local vnc_local_port="5900"
  local vnc_remote_port="5900"
  read_or_prompt_for_current_device__hostname "vnc_hostname"
  read_or_prompt_for_current_device__ssh_port "device_ssh_port"

  cleanup() {
    local vnc_user="${1?}"
    local vnc_hostname="${2?}"
    local device_ssh_port="${3?}"
    local vnc_remote_port="${4?}"
    local systemd_service_name="${5?}"
    shift 5

    echo "Cleanup required"
    if is_x11vnc_systemd_process_stopped "${vnc_user}" "${vnc_hostname}" "${device_ssh_port}" "${systemd_service_name}"; then
        echo "x11vnc systemd process is already closed"
    else
        echo "Closing x11vnc systemd process"
        close_x11vnc_systemd_process "${vnc_user}" "${vnc_hostname}" "${device_ssh_port}" "${systemd_service_name}"
    fi

    if is_x11vnc_pid_stopped "${vnc_user}" "${vnc_hostname}" "${device_ssh_port}" "${vnc_remote_port}"; then
        echo "x11vnc pid is already stopped"
    else
        echo "Closing x11vnc pid"
        exit_x11vnc "${vnc_user}" "${vnc_hostname}" "${device_ssh_port}"
    fi

    return 0
  }
  trap "cleanup '${vnc_user}' '${vnc_hostname}' '${device_ssh_port}' '${vnc_remote_port}' '${systemd_service_name}'" EXIT SIGINT SIGQUIT

  # Validation that the service that we are about to launch does not exist yet.
  # if the service is alive we ask the user if it wants to kill the existing session.
  echo " -> Making sure x11vnc is not aready started"
  if ! is_x11vnc_systemd_process_stopped "${vnc_user}" "${vnc_hostname}" "${device_ssh_port}" "${systemd_service_name}"; then
    local active_session_info
    active_session_info=$(ssh "${vnc_user}@${vnc_hostname}" -p "${device_ssh_port}" "systemctl -q --no-pager --user status '${systemd_service_name}'") && true
    echo "An active x11vnc session has been detected"
    echo "Here is some information about the active session"
    echo "${active_session_info}"
    echo ""
    local user_input
    read -n 1 -p 'Do you want to close the session? (Y)es or (N)o' user_input
    echo ""
    case $user_input in
      [yY] )
        echo "Okay, we will kill the existing session"
        cleanup "${vnc_user}" "${vnc_hostname}" "${device_ssh_port}" "${vnc_remote_port}" "${systemd_service_name}"
        # Sleep 5 seconds to avoid getting kicked out by the other script cleanup.
        # Todo: Find a proper way to fix the race condition.
        #       - Perhaps we could stop x11vnc from the new session and wait for the old session to stop the systemd service.
        sleep 5
        ;;
      [nN] )
        echo "Okay, leaving the existing session as is."
        trap - EXIT SIGINT SIGQUIT
        return 0
        ;;
      * )
        echo "Erroneous answer. Doing nothing."
        trap - EXIT SIGINT SIGQUIT
        return 0
        ;;
    esac
  fi

  # x11vnc is launched as a connect once server, as soon as vncviewer closes x11vnc also closes.
  echo " -> Starting x11vnc"
  local user_info
  user_info="$(get_factory_info__user_full_name)<$(get_factory_info__user_email)>"
  local vnc_passwd
  vnc_passwd="$(pwgen -cn 32 | head -n1)"
  local cmd="$(cat <<EOF
systemd-run \
--remain-after-exit \
--property=Type=forking \
--unit "${systemd_service_name}" \
--user bash\
 -c 'echo "${user_info}"'; x11vnc -bg -once -localhost -passwd "${vnc_passwd}" -display :0
EOF
)"
  if ! ssh "${vnc_user}@${vnc_hostname}" -p "${device_ssh_port}" "${cmd}"; then
    local err="$?"
    1>&2 echo "Error: $FUNCNAME: $err"
    return "$err"
  fi

  # The tunnel auto-closes as soon as vncviewer is closed.
  # The sleep 10 is executed on the remote machine and allows the tunnel to remain open
  # while we are launching the vncviewer.
  echo " -> Creating an SSH tunnel"
  if ! ssh -f -T -L "${vnc_local_port}:localhost:${vnc_remote_port}" "${vnc_user}@${vnc_hostname}" -p "${device_ssh_port}" "sleep 10"; echo "${vnc_passwd}" | vncviewer -autopass localhost:"${vnc_local_port}"; then
    local err="$?"
    1>&2 echo "Error: $FUNCNAME: $err"
    return "$err"
  fi
}
