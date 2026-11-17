#!/usr/bin/env bash
# Converts a sonar-project.properties file into SonarScanner for .NET begin arguments, printed one per line.
# SonarScanner for .NET doesn't read sonar-project.properties, so its settings have to be passed on the command line.
#   sonar.projectKey, sonar.organization, sonar.projectName and sonar.projectVersion become /k:, /o:, /n: and /v:
#   sonar.sources and sonar.tests are skipped, as the scanner derives them from the projects
#   sonar.token and sonar.login are skipped, as credentials must not be kept in the file
#   Any other property becomes /d:<key>=<value>
# Only single-line key=value properties are supported; comments (# or !) and blank lines are ignored.
# Exits 0 on success, 1 if the file is missing or has no sonar.projectKey, and 2 on invalid usage.
#
# Usage: parse-sonar-properties.sh [options] [properties-file]
#
# Options:
#   --default-host-url <url>   host URL used when the file doesn't set sonar.host.url (default https://sonarcloud.io)
#
# Arguments:
#   properties-file            path to the properties file (default sonar-project.properties)

set -euo pipefail

usage() {
  sed -n 's/^# \{0,1\}//; 11,17p' "$0" >&2
  exit 2
}

default_host_url=https://sonarcloud.io
properties_file=""

while [[ "$#" -gt 0 ]]; do
  case "$1" in
    --default-host-url) default_host_url="${2:?--default-host-url needs a value}"; shift 2 ;;
    -h | --help) usage ;;
    -*) echo "Unknown option: $1" >&2; usage ;;
    *)
      if [[ -n "$properties_file" ]]; then
        echo "Only one properties file can be given" >&2
        usage
      fi
      properties_file="$1"
      shift
      ;;
  esac
done

properties_file="${properties_file:-sonar-project.properties}"

if [[ ! -f "$properties_file" ]]; then
  echo "::error::Properties file $properties_file not found" >&2
  exit 1
fi

trim() {
  local input="$1"
  printf '%s' "$input" | tr -d '\r' | sed 's/^[[:space:]]*//; s/[[:space:]]*$//'
}

project_key_set=false
host_url_set=false

# The || handles a last line without a trailing newline
while IFS='=' read -r key value || [[ -n "$key" ]]; do
  key=$(trim "$key")
  value=$(trim "${value:-}")
  case "$key" in
    '' | '#'* | '!'*) ;;
    sonar.projectKey) project_key_set=true; printf '/k:%s\n' "$value" ;;
    sonar.organization) printf '/o:%s\n' "$value" ;;
    sonar.projectName) printf '/n:%s\n' "$value" ;;
    sonar.projectVersion) printf '/v:%s\n' "$value" ;;
    sonar.sources | sonar.tests | sonar.token | sonar.login) ;;
    sonar.host.url) host_url_set=true; printf '/d:%s=%s\n' "$key" "$value" ;;
    *) printf '/d:%s=%s\n' "$key" "$value" ;;
  esac
done < "$properties_file"

if [[ "$project_key_set" = false ]]; then
  echo "::error::$properties_file doesn't set sonar.projectKey" >&2
  exit 1
fi

if [[ "$host_url_set" = false ]]; then
  printf '/d:sonar.host.url=%s\n' "$default_host_url"
fi
