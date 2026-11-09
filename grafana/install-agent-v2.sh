#!/usr/bin/env bash
# Monitoring Agent Installer for Ubuntu 24.04
# Supports schema v1 (explicit config) and v2 (auto-discovery)

set -Eeuo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="${SCRIPT_DIR}/device.yaml"
MODE="install"
RENDER_OUTPUT=""

usage() {
  cat <<'EOF'
Usage (schema v1 - hardcoded token):
  sudo ./install-agent-v2.sh [--config PATH]
  
Usage (schema v2 - environment token):
  export INFLUX_TOKEN="your_token_here"
  sudo -E ./install-agent-v2.sh [--config PATH]

Modes:
  default          Install/configure Telegraf and start the service.
  --validate-only  Validate device.yaml only; does not install anything.
  --render-only    Generate a Telegraf TOML file locally; does not install anything.

Options:
  --config PATH    Use alternative device.yaml (default: ./device.yaml)
  -h, --help       Show this help message
EOF
}

while (($#)); do
  case "$1" in
    --config)
      [[ $# -ge 2 ]] || { usage; exit 2; }
      CONFIG_FILE="$2"
      shift 2
      ;;
    --validate-only)
      MODE="validate"
      shift
      ;;
    --render-only)
      [[ $# -ge 2 ]] || { usage; exit 2; }
      MODE="render"
      RENDER_OUTPUT="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "ERROR: Unknown argument: $1" >&2
      usage
      exit 2
      ;;
  esac
done

fail() { echo "ERROR: $*" >&2; exit 1; }
info() { printf '\n[INFO] %s\n' "$*"; }
warn() { printf '\n[WARN] %s\n' "$*" >&2; }

[[ -f "$CONFIG_FILE" ]] || fail "Cannot find configuration file: $CONFIG_FILE"
command -v python3 >/dev/null 2>&1 || fail "python3 is required."

if ! python3 -c 'import yaml' >/dev/null 2>&1; then
  if [[ "$MODE" == "install" ]]; then
    [[ $EUID -eq 0 ]] || fail "Run with sudo so python3-yaml can be installed."
    export DEBIAN_FRONTEND=noninteractive
    apt-get update
    apt-get install -y python3-yaml
  else
    fail "PyYAML is missing. Install it with: sudo apt-get install python3-yaml"
  fi
fi

TMP_DIR="$(mktemp -d -t telegraf-agent.XXXXXX)"
cleanup() { rm -rf "$TMP_DIR"; }
trap cleanup EXIT
GENERATED_CONFIG="${TMP_DIR}/90-device-agent.conf"

# YAML validation and TOML generation
python3 - "$CONFIG_FILE" "$GENERATED_CONFIG" <<'PY'
import json
import os
import re
import subprocess
import sys
from pathlib import Path

import yaml

source = Path(sys.argv[1])
target = Path(sys.argv[2])


def die(message):
    print(f"ERROR: {message}", file=sys.stderr)
    raise SystemExit(1)


def as_mapping(value, label):
    if value is None:
        return {}
    if not isinstance(value, dict):
        die(f"'{label}' must be a YAML mapping/object")
    return value


def as_bool(value, label, default=False):
    if value is None:
        return default
    if isinstance(value, bool):
        return value
    if isinstance(value, str):
        if value.lower() == "auto":
            return "auto"
        if value.lower() in ("true", "yes"):
            return True
        if value.lower() in ("false", "no"):
            return False
    die(f"'{label}' must be true, false, or auto")


def as_string(value, label, required=False, default=""):
    if value is None:
        value = default
    if not isinstance(value, str):
        die(f"'{label}' must be a string")
    value = value.strip()
    if required and not value:
        die(f"'{label}' is required")
    if "\x00" in value or "\n" in value or "\r" in value:
        die(f"'{label}' contains an invalid control character")
    return value


def as_list(value, label, default=None):
    if value is None:
        value = [] if default is None else default
    if not isinstance(value, list):
        die(f"'{label}' must be a YAML list")
    return value


def duration(value, label, default):
    value = as_string(value, label, default=default)
    if not re.fullmatch(r"[0-9]+(?:ms|s|m|h)", value):
        die(f"'{label}' must be a duration such as 10s, 30s or 1m")
    return value


def toml_string(value):
    return json.dumps(str(value), ensure_ascii=False)


def toml_value(value):
    if isinstance(value, bool):
        return "true" if value else "false"
    if isinstance(value, (int, float)):
        return str(value)
    if isinstance(value, list):
        return "[" + ", ".join(toml_value(x) for x in value) + "]"
    if isinstance(value, dict):
        return "{ " + ", ".join(toml_string(k) + " = " + toml_value(v) for k, v in value.items()) + " }"
    return toml_string(value)


def add_block(lines, table, values):
    lines.append(f"[[{table}]]")
    for key, value in values.items():
        if value is not None:
            lines.append(f"{key} = {toml_value(value)}")
    lines.append("")


def pg_conninfo_value(value):
    text = str(value).replace("\\", "\\\\").replace("'", "\\'")
    return "'" + text + "'"


def check_command_exists(cmd):
    """Check if a command exists on the system."""
    return subprocess.run(["which", cmd], capture_output=True).returncode == 0


def find_csv_files(paths):
    """Find CSV files matching glob patterns."""
    import glob
    found = []
    for pattern in paths:
        matches = glob.glob(pattern)
        found.extend(matches)
    return list(set(found))


def detect_csv_config(file_path):
    """Auto-detect CSV configuration: header, delimiter, column types."""
    config = {"header": True, "delimiter": ",", "column_types": [], "tag_columns": []}
    
    try:
        with open(file_path, 'r', encoding='utf-8', errors='replace') as f:
            first_line = f.readline()
            second_line = f.readline()
            
        if not first_line:
            return config
        
        # Detect delimiter
        for delim in [',', ';', '\t', '|']:
            count = first_line.count(delim)
            if count > 0:
                config["delimiter"] = delim
                break
        
        # Detect if header exists (heuristic: check if first line looks like field names)
        parts = first_line.rstrip().split(config["delimiter"])
        if second_line:
            second_parts = second_line.rstrip().split(config["delimiter"])
            # If first line has non-numeric values and second has numeric, likely header
            if parts and second_parts and len(parts) == len(second_parts):
                first_all_numeric = all(p.replace('.', '').replace('-', '').isdigit() for p in parts if p)
                second_has_numeric = any(p.replace('.', '').replace('-', '').isdigit() for p in second_parts if p)
                config["header"] = not first_all_numeric or second_has_numeric
        
        # Detect column types
        if config["header"] and second_line:
            data_parts = second_line.rstrip().split(config["delimiter"])
            for val in data_parts:
                if not val:
                    config["column_types"].append("string")
                elif re.match(r'^-?\d+$', val):
                    config["column_types"].append("int")
                elif re.match(r'^-?\d+\.?\d*$', val):
                    config["column_types"].append("float")
                elif val.lower() in ("true", "false"):
                    config["column_types"].append("bool")
                else:
                    config["column_types"].append("string")
    except Exception:
        pass
    
    return config


def discover_postgresql_instances():
    """Auto-discover PostgreSQL instances running locally."""
    instances = []
    
    # Check if PostgreSQL is installed
    if not check_command_exists("psql"):
        return instances
    
    # Try to connect via Unix socket (local)
    try:
        result = subprocess.run(
            ["sudo", "-u", "postgres", "psql", "-l", "-t", "-c", "SELECT datname FROM pg_database WHERE datistemplate = false;"],
            capture_output=True,
            text=True,
            timeout=5
        )
        if result.returncode == 0:
            databases = [db.strip() for db in result.stdout.split('\n') if db.strip()]
            instances.append({
                "name": "local",
                "host": "localhost",
                "port": 5432,
                "username": "postgres",
                "databases": databases[:1] if databases else ["postgres"],  # At least one DB
                "sslmode": "disable"
            })
    except Exception:
        pass
    
    return instances


def discover_docker():
    """Check if Docker is available."""
    return check_command_exists("docker")


def discover_systemd_services():
    """Auto-discover running systemd services."""
    services = []
    
    try:
        result = subprocess.run(
            ["systemctl", "list-units", "--type=service", "--state=running", "--no-pager", "-q"],
            capture_output=True,
            text=True,
            timeout=5
        )
        if result.returncode == 0:
            lines = result.stdout.strip().split('\n')
            for line in lines:
                parts = line.split()
                if parts:
                    service = parts[0]
                    if not service.startswith("system"):
                        services.append(service)
    except Exception:
        pass
    
    return services[:10] if services else ["ssh.service", "docker.service"]  # Default services


try:
    raw = yaml.safe_load(source.read_text(encoding="utf-8"))
except yaml.YAMLError as exc:
    die(f"Invalid YAML in {source}: {exc}")
except OSError as exc:
    die(f"Cannot read {source}: {exc}")

cfg = as_mapping(raw, "root")
device = as_mapping(cfg.get("device"), "device")
influx = as_mapping(cfg.get("influxdb"), "influxdb")
agent = as_mapping(cfg.get("agent"), "agent")
monitoring = as_mapping(cfg.get("monitoring"), "monitoring")
system = as_mapping(monitoring.get("system"), "monitoring.system")
heartbeat = as_mapping(monitoring.get("heartbeat"), "monitoring.heartbeat")
postgres = as_mapping(cfg.get("postgresql"), "postgresql")
postgres_discovery = as_mapping(postgres.get("discovery"), "postgresql.discovery")
csv_cfg = as_mapping(cfg.get("csv"), "csv")
csv_discovery = as_mapping(csv_cfg.get("discovery"), "csv.discovery")
docker = as_mapping(cfg.get("docker"), "docker")
docker_discovery = as_mapping(docker.get("discovery"), "docker.discovery")
applications = as_mapping(cfg.get("applications"), "applications")
apps_discovery = as_mapping(applications.get("discovery"), "applications.discovery")

schema = cfg.get("schema_version", 1)
if schema not in (1, 2):
    die(f"Unsupported schema_version: {schema}. Supported: 1, 2")

device_id = as_string(device.get("id"), "device.id", required=True)
if not re.fullmatch(r"[A-Za-z0-9][A-Za-z0-9_.-]{0,63}", device_id):
    die("device.id must be 1-64 characters: letters, digits, dot, underscore or hyphen")

# Auto-detect hostname for schema v2
device_name = device.get("name")
if device_name == "auto" or not device_name:
    device_name = subprocess.run(["hostname", "-s"], capture_output=True, text=True).stdout.strip() or device_id
else:
    device_name = as_string(device_name, "device.name", default=device_id)

device_description = as_string(device.get("description"), "device.description", default="")
location = as_string(device.get("location"), "device.location", default="")

if not as_bool(influx.get("enabled"), "influxdb.enabled", True):
    die("influxdb.enabled must be true because InfluxDB is the only output")

influx_url = as_string(influx.get("url"), "influxdb.url", required=True).rstrip("/")
if not re.match(r"^https?://", influx_url):
    die("influxdb.url must begin with http:// or https://")

# Token handling: schema v1 (hardcoded) vs v2 (environment variable)
token = None
if schema == 1:
    organization = as_string(influx.get("organization"), "influxdb.organization", required=True)
    token = as_string(influx.get("token"), "influxdb.token", required=True)
    if any(marker in token.upper() for marker in ("REPLACE", "YOUR_", "CHANGE_ME")):
        die("Replace the placeholder in influxdb.token with a write token before installing")
elif schema == 2:
    organization = as_string(influx.get("organization"), "influxdb.organization", default="monitoring")
    token_env = as_string(influx.get("token_env"), "influxdb.token_env", default="INFLUX_TOKEN")
    token = os.environ.get(token_env, "")
    if not token:
        die(f"Schema v2 requires token from environment variable: export {token_env}=... && sudo -E ./install-agent-v2.sh")
    if any(marker in token.upper() for marker in ("REPLACE", "YOUR_", "CHANGE_ME")):
        die(f"Environment variable {token_env} contains a placeholder; replace with a valid write token")

buckets = as_mapping(influx.get("buckets"), "influxdb.buckets")
system_bucket = as_string(buckets.get("system"), "influxdb.buckets.system",
                          required=(schema==1), default="system_metrics" if schema==2 else "")
csv_bucket = as_string(buckets.get("csv"), "influxdb.buckets.csv",
                       required=(schema==1), default="device_csv" if schema==2 else "")
database_bucket = as_string(buckets.get("database"), "influxdb.buckets.database",
                            required=False, default="device_database" if schema==2 else "")

interval = duration(agent.get("interval"), "agent.interval", "10s")
flush_interval = duration(agent.get("flush_interval"), "agent.flush_interval", "10s")

system_enabled = as_bool(system.get("enabled"), "monitoring.system.enabled", True)
if system_enabled == "auto":
    system_enabled = True
system_switches = {
    "cpu": as_bool(system.get("cpu"), "monitoring.system.cpu", True),
    "memory": as_bool(system.get("memory"), "monitoring.system.memory", True),
    "disk": as_bool(system.get("disk"), "monitoring.system.disk", True),
    "diskio": as_bool(system.get("diskio"), "monitoring.system.diskio", True),
    "network": as_bool(system.get("network"), "monitoring.system.network", True),
    "uptime": as_bool(system.get("uptime"), "monitoring.system.uptime", True),
    "processes": as_bool(system.get("processes"), "monitoring.system.processes", True),
}
for key in system_switches:
    if system_switches[key] == "auto":
        system_switches[key] = True

heartbeat_enabled = as_bool(heartbeat.get("enabled"), "monitoring.heartbeat.enabled", True)
if heartbeat_enabled == "auto":
    heartbeat_enabled = True
heartbeat_interval = duration(heartbeat.get("interval"), "monitoring.heartbeat.interval", interval)

# Schema v1: explicit PostgreSQL instances; Schema v2: auto-discovery
postgres_enabled = as_bool(postgres.get("enabled"), "postgresql.enabled", False)
if postgres_enabled == "auto":
    postgres_enabled = discover_postgresql_instances() if schema == 2 else False
pg_instances = []
if postgres_enabled:
    if schema == 1:
        pg_instances = as_list(postgres.get("instances"), "postgresql.instances")
        if not pg_instances:
            die("postgresql.enabled is true but postgresql.instances is empty")
    elif schema == 2:
        # Auto-discovered instances
        if isinstance(postgres_enabled, list):
            pg_instances = postgres_enabled
        else:
            pg_instances = discover_postgresql_instances()
        postgres_enabled = bool(pg_instances)

discovery_instances = []
for index, instance in enumerate(pg_instances):
    if not isinstance(instance, dict):
        die(f"postgresql.instances[{index}] must be an object")
    for field in ("name", "host", "username"):
        as_string(instance.get(field), f"postgresql.instances[{index}].{field}", required=True)
    port = instance.get("port", 5432)
    if not isinstance(port, int) or not (1 <= port <= 65535):
        die(f"postgresql.instances[{index}].port must be between 1 and 65535")
    password = instance.get("password", "")
    if not isinstance(password, str) or "\x00" in password or "\n" in password or "\r" in password:
        die(f"postgresql.instances[{index}].password must be a single-line string")
    if postgres_enabled and any(marker in password.upper() for marker in ("CHANGE_ME", "REPLACE", "YOUR_")):
        die(f"Replace the placeholder PostgreSQL password in postgresql.instances[{index}] or remove the password key when using passwordless authentication")
    dbs = as_list(instance.get("databases"), f"postgresql.instances[{index}].databases")
    if not dbs:
        die(f"postgresql.instances[{index}].databases must list at least one database; this prevents accidentally collecting all databases")
    for db in dbs:
        if not isinstance(db, str) or not db.strip():
            die(f"postgresql.instances[{index}].databases contains an empty/non-string value")
    sslmode = as_string(instance.get("sslmode"), f"postgresql.instances[{index}].sslmode", default="disable")
    if sslmode not in {"disable", "allow", "prefer", "require", "verify-ca", "verify-full"}:
        die(f"Unsupported sslmode '{sslmode}' in PostgreSQL instance {index}")

# Schema v1: explicit CSV files; Schema v2: auto-discovery
csv_enabled = as_bool(csv_cfg.get("enabled"), "csv.enabled", False)
if csv_enabled == "auto":
    csv_enabled = False

csv_interval = duration(csv_cfg.get("interval"), "csv.interval", "30s")
csv_files = []
if csv_enabled:
    if schema == 1:
        csv_files = as_list(csv_cfg.get("files"), "csv.files")
        if not csv_files:
            die("csv.enabled is true but csv.files is empty")
    elif schema == 2:
        # Auto-discovery: scan paths for CSV files
        paths = as_list(csv_cfg.get("paths"), "csv.paths", default=[])
        if paths:
            found_files = find_csv_files(paths)
            for file_path in found_files:
                csv_config = detect_csv_config(file_path)
                csv_files.append({
                    "name": Path(file_path).stem,
                    "path": file_path,
                    **csv_config
                })

for index, item in enumerate(csv_files):
    if not isinstance(item, dict):
        die(f"csv.files[{index}] must be an object")
    as_string(item.get("name"), f"csv.files[{index}].name", required=True)
    as_string(item.get("path"), f"csv.files[{index}].path", required=True)
    header = as_bool(item.get("header"), f"csv.files[{index}].header", True)
    if header == "auto":
        header = True
    col_names = as_list(item.get("column_names"), f"csv.files[{index}].column_names")
    if not header and not col_names:
        die(f"csv.files[{index}] has header: false; column_names is required")

# Schema v1: explicit Docker; Schema v2: auto-discovery
docker_enabled = as_bool(docker.get("enabled"), "docker.enabled", False)
if docker_enabled == "auto":
    docker_enabled = discover_docker() if schema == 2 else False

docker_endpoint = as_string(docker.get("endpoint"), "docker.endpoint", default="unix:///var/run/docker.sock")
grant_docker = as_bool(docker.get("grant_socket_access"), "docker.grant_socket_access", False)
if grant_docker == "auto":
    grant_docker = False
container_include = as_list(docker.get("container_name_include"), "docker.container_name_include")

# Schema v1: explicit services; Schema v2: auto-discovery
apps_enabled = as_bool(applications.get("enabled"), "applications.enabled", False)
if apps_enabled == "auto":
    services = discover_systemd_services() if schema == 2 else []
    apps_enabled = bool(services)
else:
    services = as_list(applications.get("systemd_services"), "applications.systemd_services")
    if apps_enabled and not services:
        die("applications.enabled is true but applications.systemd_services is empty")

if any(not isinstance(v, str) or not v.strip() for v in services):
    die("applications.systemd_services must contain non-empty strings")

if not (any(system_switches.values()) and system_enabled) and not (heartbeat_enabled or postgres_enabled or csv_enabled or docker_enabled or apps_enabled):
    die("No input plugins are enabled. Enable at least one monitoring feature.")

lines = [
    "# Managed by install-agent-v2.sh. Edit device.yaml, then rerun the installer.",
    f"# Device ID: {device_id}",
    "",
]

# Apply device identifier to all metrics
lines.extend([
    "[[processors.override]]",
    "  [processors.override.tags]",
    f"    device = {toml_string(device_id)}",
    f"    device_name = {toml_string(device_name)}",
])
if device_description:
    lines.append(f"    device_description = {toml_string(device_description)}")
if location:
    lines.append(f"    location = {toml_string(location)}")
lines.append("")

# System monitoring
if system_enabled:
    if system_switches["cpu"]:
        add_block(lines, "inputs.cpu", {"percpu": False, "totalcpu": True, "report_active": True, "interval": interval})
    if system_switches["memory"]:
        add_block(lines, "inputs.mem", {"interval": interval})
    if system_switches["disk"]:
        add_block(lines, "inputs.disk", {"ignore_fs": ["tmpfs", "devtmpfs", "devfs", "overlay", "squashfs"], "interval": interval})
    if system_switches["diskio"]:
        add_block(lines, "inputs.diskio", {"interval": interval})
    if system_switches["network"]:
        add_block(lines, "inputs.net", {"interval": interval})
    if system_switches["uptime"]:
        add_block(lines, "inputs.system", {"interval": interval})
    if system_switches["processes"]:
        add_block(lines, "inputs.processes", {"interval": interval})

# Heartbeat
if heartbeat_enabled:
    add_block(lines, "inputs.file", {
        "files": ["/var/lib/telegraf-monitoring/heartbeat.lp"],
        "data_format": "influx",
        "interval": heartbeat_interval,
    })

# PostgreSQL
if postgres_enabled:
    for index, instance in enumerate(pg_instances):
        name = as_string(instance.get("name"), f"postgresql.instances[{index}].name", required=True)
        host = as_string(instance.get("host"), f"postgresql.instances[{index}].host", required=True)
        username = as_string(instance.get("username"), f"postgresql.instances[{index}].username", required=True)
        port = instance.get("port", 5432)
        password = instance.get("password", "")
        sslmode = as_string(instance.get("sslmode"), f"postgresql.instances[{index}].sslmode", default="disable")
        maintenance_db = as_string(instance.get("maintenance_db"), f"postgresql.instances[{index}].maintenance_db", default="postgres")
        fields = [
            f"host={pg_conninfo_value(host)}",
            f"port={pg_conninfo_value(port)}",
            f"user={pg_conninfo_value(username)}",
            f"dbname={pg_conninfo_value(maintenance_db)}",
            f"sslmode={pg_conninfo_value(sslmode)}",
        ]
        if password:
            fields.append(f"password={pg_conninfo_value(password)}")
        add_block(lines, "inputs.postgresql", {
            "address": " ".join(fields),
            "outputaddress": name,
            "databases": [str(x) for x in instance["databases"]],
            "prepared_statements": as_bool(instance.get("prepared_statements"), f"postgresql.instances[{index}].prepared_statements", True),
            "interval": interval,
        })

# CSV
if csv_enabled:
    for index, item in enumerate(csv_files):
        name = as_string(item.get("name"), f"csv.files[{index}].name", required=True)
        path = as_string(item.get("path"), f"csv.files[{index}].path", required=True)
        header = as_bool(item.get("header"), f"csv.files[{index}].header", True)
        if header == "auto":
            header = True
        values = {
            "files": [path],
            "data_format": "csv",
            "csv_header_row_count": 1 if header else 0,
            "file_tag": "source_file",
            "name_override": "file",
            "tags": {"csv_name": name},
            "interval": csv_interval,
        }
        if item.get("tag_columns"):
            values["csv_tag_columns"] = item["tag_columns"]
        if not header:
            values["csv_column_names"] = item.get("column_names", [])
        if item.get("column_types"):
            values["csv_column_types"] = item["column_types"]
        if item.get("timestamp_column"):
            values["csv_timestamp_column"] = as_string(item.get("timestamp_column"), f"csv.files[{index}].timestamp_column", required=True)
            values["csv_timestamp_format"] = as_string(item.get("timestamp_format"), f"csv.files[{index}].timestamp_format", required=True)
        if item.get("skip_rows") is not None:
            if not isinstance(item["skip_rows"], int) or item["skip_rows"] < 0:
                die(f"csv.files[{index}].skip_rows must be a non-negative integer")
            values["csv_skip_rows"] = item["skip_rows"]
        add_block(lines, "inputs.file", values)

# Docker
if docker_enabled:
    values = {
        "endpoint": docker_endpoint,
        "timeout": "5s",
        "interval": interval,
    }
    if container_include:
        values["container_name_include"] = container_include
    add_block(lines, "inputs.docker", values)

# Systemd services
if apps_enabled:
    normalized = [s if "." in s else s + ".service" for s in services]
    add_block(lines, "inputs.systemd_units", {
        "pattern": " ".join(normalized),
        "unittype": "service",
        "details": True,
        "timeout": "5s",
        "interval": interval,
    })

# Output: system metrics
add_block(lines, "outputs.influxdb_v2", {
    "urls": [influx_url],
    "token": token,
    "organization": organization,
    "bucket": system_bucket,
    "namedrop": ["file"],
    "timeout": "5s",
    "flush_interval": flush_interval,
})

# Output: CSV metrics
add_block(lines, "outputs.influxdb_v2", {
    "urls": [influx_url],
    "token": token,
    "organization": organization,
    "bucket": csv_bucket,
    "namepass": ["file"],
    "timeout": "5s",
    "flush_interval": flush_interval,
})

target.write_text("\n".join(lines), encoding="utf-8")
print(f"✓ Schema v{schema} configuration valid")
print(f"  Device: {device_id} ({device_name})")
print(f"  System: {any(system_switches.values())}, Heartbeat: {heartbeat_enabled}")
print(f"  PostgreSQL: {postgres_enabled} ({len(pg_instances)} instances), CSV: {csv_enabled} ({len(csv_files)} files)")
print(f"  Docker: {docker_enabled}, Services: {apps_enabled} ({len(services)} services)")
print(f"  Generated: {target}")
PY

if [[ "$MODE" == "validate" ]]; then
  info "YAML validation completed. No packages or services were changed."
  exit 0
fi

if [[ "$MODE" == "render" ]]; then
  mkdir -p "$(dirname -- "$RENDER_OUTPUT")"
  install -m 0600 "$GENERATED_CONFIG" "$RENDER_OUTPUT"
  info "Rendered Telegraf configuration to: $RENDER_OUTPUT"
  echo "Review this file before installing it on a device. For schema v2, the token comes from environment variable; for schema v1, it's in the TOML."
  exit 0
fi

[[ $EUID -eq 0 ]] || fail "Run installation with sudo: sudo bash $0"
chmod 0600 "$CONFIG_FILE"

if [[ -r /etc/os-release ]]; then
  . /etc/os-release
else
  fail "Cannot identify operating system (/etc/os-release missing)"
fi
[[ "${ID:-}" == "ubuntu" && "${VERSION_ID:-}" == "24.04" ]] || fail "This version targets Ubuntu 24.04 only (detected: ${PRETTY_NAME:-unknown})"

export DEBIAN_FRONTEND=noninteractive
info "Installing prerequisites"
apt-get update
apt-get install -y ca-certificates curl gnupg python3-yaml openssh-client

if ! command -v telegraf >/dev/null 2>&1; then
  info "Adding InfluxData APT repository"
  install -d -m 0755 /etc/apt/keyrings
  curl --fail --silent --show-error --location \
    https://repos.influxdata.com/influxdata-archive.key \
    -o "${TMP_DIR}/influxdata-archive.key"
  FINGERPRINT="$(gpg --show-keys --with-fingerprint --with-colons "${TMP_DIR}/influxdata-archive.key" 2>/dev/null | awk -F: '$1 == "fpr" {print $10; exit}')"
  [[ "$FINGERPRINT" == "24C975CBA61A024EE1B631787C3D57159FC2F927" ]] || fail "InfluxData GPG fingerprint mismatch: ${FINGERPRINT:-not found}"
  gpg --dearmor --yes --output /etc/apt/keyrings/influxdata-archive.gpg "${TMP_DIR}/influxdata-archive.key"
  chmod 0644 /etc/apt/keyrings/influxdata-archive.gpg
  echo 'deb [signed-by=/etc/apt/keyrings/influxdata-archive.gpg] https://repos.influxdata.com/debian stable main' \
    > /etc/apt/sources.list.d/influxdata.list
  apt-get update
  apt-get install -y telegraf
else
  info "Telegraf is already installed: $(telegraf --version 2>&1 | head -n 1)"
fi

id telegraf >/dev/null 2>&1 || fail "The telegraf service account was not created by the package"

DOCKER_ENABLED="$(python3 - "$CONFIG_FILE" <<'PY'
import sys, yaml
c = yaml.safe_load(open(sys.argv[1], encoding='utf-8')) or {}
d = c.get('docker') or {}
print('true' if d.get('enabled', False) else 'false')
PY
)"
DOCKER_GRANT="$(python3 - "$CONFIG_FILE" <<'PY'
import sys, yaml
c = yaml.safe_load(open(sys.argv[1], encoding='utf-8')) or {}
d = c.get('docker') or {}
print('true' if d.get('grant_socket_access', False) else 'false')
PY
)"
if [[ "$DOCKER_ENABLED" == "true" ]]; then
  if [[ "$DOCKER_GRANT" == "true" ]]; then
    getent group docker >/dev/null 2>&1 || fail "docker.enabled is true and grant_socket_access is true, but the docker group does not exist"
    usermod -aG docker telegraf
    warn "The telegraf user was added to the docker group. Docker group membership grants root-equivalent control over this machine."
  elif getent group docker | grep -qE ":([^:]*,)?telegraf(,|$)"; then
    :
  else
    warn "Docker monitoring is enabled, but telegraf lacks Docker socket access. Set docker.grant_socket_access: true only if you accept the root-equivalent Docker permission."
  fi
fi

install -d -o root -g telegraf -m 0750 /var/lib/telegraf-monitoring
printf 'device_heartbeat online=1i\n' > "${TMP_DIR}/heartbeat.lp"
install -o root -g telegraf -m 0640 "${TMP_DIR}/heartbeat.lp" /var/lib/telegraf-monitoring/heartbeat.lp

TELEGRAF_DIR="/etc/telegraf/telegraf.d"
TARGET_CONFIG="${TELEGRAF_DIR}/90-device-agent.conf"
BACKUP_DIR="/var/backups/telegraf-agent"
install -d -o root -g telegraf -m 0750 "$TELEGRAF_DIR"
install -d -o root -g root -m 0700 "$BACKUP_DIR"

if [[ -f /etc/telegraf/telegraf.conf ]] && grep -Eq "^[[:space:]]*\[\[(inputs|outputs)\." /etc/telegraf/telegraf.conf; then
  warn "The main /etc/telegraf/telegraf.conf has active input/output blocks. Review to avoid duplicate collection."
fi

shopt -s nullglob
OTHER_CONFIGS=("${TELEGRAF_DIR}"/*.conf)
shopt -u nullglob
if ((${#OTHER_CONFIGS[@]} > 1)) || { ((${#OTHER_CONFIGS[@]} == 1)) && [[ "${OTHER_CONFIGS[0]}" != "$TARGET_CONFIG" ]]; }; then
  warn "Other Telegraf *.conf files exist in ${TELEGRAF_DIR}:"
  for f in "${OTHER_CONFIGS[@]}"; do
    [[ "$f" == "$TARGET_CONFIG" ]] || printf '  - %s\n' "$f" >&2
  done
fi

info "Validating Telegraf configuration"
if ! telegraf --config "$GENERATED_CONFIG" --input-filter cpu --test \
    >"${TMP_DIR}/telegraf-test.log" 2>&1; then
  install -o root -g root -m 0600 "${TMP_DIR}/telegraf-test.log" /var/log/telegraf-agent-config-test.log
  fail "Telegraf validation failed. Log: /var/log/telegraf-agent-config-test.log"
fi

STAMP="$(date +%Y%m%d-%H%M%S)"
HAD_OLD_CONFIG="false"
if [[ -f "$TARGET_CONFIG" ]]; then
  cp -a "$TARGET_CONFIG" "${BACKUP_DIR}/90-device-agent.conf.${STAMP}"
  HAD_OLD_CONFIG="true"
fi

install -o root -g telegraf -m 0640 "$GENERATED_CONFIG" "${TARGET_CONFIG}.new"
mv -f "${TARGET_CONFIG}.new" "$TARGET_CONFIG"

info "Enabling and restarting Telegraf"
systemctl enable telegraf
if systemctl restart telegraf && systemctl is-active --quiet telegraf; then
  info "✓ Telegraf is active and running"
else
  warn "Telegraf failed; restoring previous configuration"
  if [[ "$HAD_OLD_CONFIG" == "true" ]]; then
    cp -a "${BACKUP_DIR}/90-device-agent.conf.${STAMP}" "$TARGET_CONFIG"
  else
    rm -f "$TARGET_CONFIG"
  fi
  systemctl restart telegraf || true
  fail "Telegraf did not start. Check: journalctl -u telegraf -n 100"
fi

info "Installation complete!"

DEVICE_ID="$(python3 -c '
import yaml, sys
cfg = yaml.safe_load(open(sys.argv[1]))
print(cfg["device"]["id"])
' "$CONFIG_FILE")"

info "Device ID: $DEVICE_ID"
info "Config: $TARGET_CONFIG"
info "Logs: journalctl -u telegraf -f"
