#!/usr/bin/env bash
set -e

DATA_DIR="/etc/mock-hostnamectl"
DATA_FILE="$DATA_DIR/hostinfo.json"

mkdir -p "$DATA_DIR"

# -------------------------
# 1) If no hostinfo.json, auto-generate from real system data
# -------------------------
if [ ! -f "$DATA_FILE" ]; then
  echo "[mock-hostnamectl] Initializing $DATA_FILE with system info..."

  # Grab real hostname from `hostname` (if available)
  REAL_HOSTNAME="$(hostname 2>/dev/null || echo "myHost")"

  # Try to parse /etc/os-release for OS info
  OS_NAME="Unknown Linux"
  OS_HOME_URL="https://www.example.com/"
  if [ -f /etc/os-release ]; then
    # shellcheck source=/dev/null
    . /etc/os-release
    # $PRETTY_NAME, $HOME_URL are often set here
    OS_NAME="${PRETTY_NAME:-$OS_NAME}"
    OS_HOME_URL="${HOME_URL:-$OS_HOME_URL}"
  fi

  # Grab kernel data from uname
  KERNEL_NAME="$(uname -s 2>/dev/null || echo "Linux")"
  KERNEL_RELEASE="$(uname -r 2>/dev/null || echo "0.0.0")"
  KERNEL_VERSION="$(uname -v 2>/dev/null || echo "#1 SMP MOCK")"

  # Detect architecture from uname -m
  ARCH="$(uname -m 2>/dev/null || echo "x86_64")"

  # Build a default JSON
  cat <<EOF > "$DATA_FILE"
{
  "Hostname": "$REAL_HOSTNAME",
  "StaticHostname": "$REAL_HOSTNAME",
  "PrettyHostname": null,
  "DefaultHostname": "localhost",
  "HostnameSource": "static",
  "IconName": "computer",
  "Chassis": null,
  "Deployment": null,
  "Location": null,
  "KernelName": "$KERNEL_NAME",
  "KernelRelease": "$KERNEL_RELEASE",
  "KernelVersion": "$KERNEL_VERSION",
  "OperatingSystemPrettyName": "$OS_NAME",
  "OperatingSystemCPEName": null,
  "OperatingSystemHomeURL": "$OS_HOME_URL",
  "HardwareVendor": null,
  "HardwareModel": null,
  "HardwareSerial": null,
  "FirmwareVersion": null,
  "ProductUUID": null,
  "Architecture": "$ARCH"
}
EOF
fi

# Helper function: Print usage
print_help() {
  cat <<EOF
hostnamectl [OPTIONS...] COMMAND ...

Query or change system hostname.

Commands:
  status                 Show current hostname settings
  hostname [NAME]        Get/set system hostname
  icon-name [NAME]       Get/set icon name for host
  chassis [NAME]         Get/set chassis type for host
  deployment [NAME]      Get/set deployment environment for host
  location [NAME]        Get/set location for host

Options:
  -h --help              Show this help
     --version           Show package version
     --no-ask-password   Do not prompt for password
  -H --host=[USER@]HOST  Operate on remote host
  -M --machine=CONTAINER Operate on local container
     --transient         Only set transient hostname
     --static            Only set static hostname
     --pretty            Only set pretty hostname
     --json=pretty|short|off
       or
     --json pretty|short|off
                         Generate JSON output

EOF
}

print_version() {
  echo "mock-hostnamectl 1.0 (Docker)"
}

# Read a field from JSON
read_value() {
  local field="$1"
  jq -r ".${field}" "$DATA_FILE"
}

# Write a string value to JSON field
write_value() {
  local field="$1"
  local val="$2"
  if [ "$val" = "null" ]; then
    jq ".${field} = null" "$DATA_FILE" > "${DATA_FILE}.tmp"
  else
    # we treat all updates as string if not null
    jq ".${field} = \"$val\"" "$DATA_FILE" > "${DATA_FILE}.tmp"
  fi
  mv "${DATA_FILE}.tmp" "$DATA_FILE"
}

# Print text-based status if --json=off or no JSON
print_status() {
  local hname="$(read_value "Hostname")"
  local icon="$(read_value "IconName")"
  local chas="$(read_value "Chassis")"
  local deploy="$(read_value "Deployment")"
  local loc="$(read_value "Location")"
  local os="$(read_value "OperatingSystemPrettyName")"
  local kname="$(read_value "KernelName")"
  local krelease="$(read_value "KernelRelease")"
  local kversion="$(read_value "KernelVersion")"
  local arch="$(read_value "Architecture")"

  cat <<EOF
 Static hostname: $hname
       Icon name: ${icon:-computer}
         Chassis: ${chas:-n/a}
      Deployment: ${deploy:-n/a}
       Location:  ${loc:-n/a}
 Operating System: $os
           Kernel: $kname $krelease ($kversion)
    Architecture:  ${arch:-n/a}
EOF
}

# Print JSON
print_json() {
  local mode="$1"
  # If user wants text or no JSON
  if [ "$mode" = "off" ]; then
    print_status
    return
  fi

  if [ "$mode" = "pretty" ]; then
    jq '.' "$DATA_FILE"
  else
    # short => one-line JSON
    jq -c '.' "$DATA_FILE"
  fi
}

# Default command is 'status' if no command given
COMMAND="status"
JSON_MODE="off"
ARGS=()

while [ $# -gt 0 ]; do
  case "$1" in
    # Commands
    status|hostname|icon-name|chassis|deployment|location)
      COMMAND="$1"
      shift
      [ $# -gt 0 ] && ARGS+=("$1") && shift
      ;;
    # Options
    --json=*)
      # e.g. --json=pretty
      JSON_MODE="${1#*=}"  # pretty|short|off
      shift
      ;;
    --json)
      # e.g. user wrote: hostnamectl --json short
      shift
      if [ $# -gt 0 ]; then
        JSON_MODE="$1"    # store next token as the mode
        shift
      fi
      ;;
    -h|--help)
      print_help
      exit 0
      ;;
    --version)
      print_version
      exit 0
      ;;
    --no-ask-password|--transient|--static|--pretty)
      # We'll ignore these flags but accept them
      shift
      ;;
    -H|--host=*)
      # ignoring remote host
      shift
      ;;
    -M|--machine=*)
      # ignoring machine param
      shift
      ;;
    *)
      # leftover or unknown
      shift
      ;;
  esac
done

# Exec the command
case "$COMMAND" in
  status)
    print_json "$JSON_MODE"
    ;;
  hostname)
    if [ -n "${ARGS[0]:-}" ]; then
      # set new hostname => also set StaticHostname
      write_value "Hostname" "${ARGS[0]}"
      write_value "StaticHostname" "${ARGS[0]}"
    else
      read_value "Hostname"
    fi
    ;;
  icon-name)
    if [ -n "${ARGS[0]:-}" ]; then
      write_value "IconName" "${ARGS[0]}"
    else
      read_value "IconName"
    fi
    ;;
  chassis)
    if [ -n "${ARGS[0]:-}" ]; then
      write_value "Chassis" "${ARGS[0]}"
    else
      read_value "Chassis"
    fi
    ;;
  deployment)
    if [ -n "${ARGS[0]:-}" ]; then
      write_value "Deployment" "${ARGS[0]}"
    else
      read_value "Deployment"
    fi
    ;;
  location)
    if [ -n "${ARGS[0]:-}" ]; then
      write_value "Location" "${ARGS[0]}"
    else
      read_value "Location"
    fi
    ;;
  *)
    # fallback => status
    print_json "$JSON_MODE"
    ;;
esac
