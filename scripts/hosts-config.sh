#!/bin/bash
set -eux
set -o pipefail

write_entries() {
    local file="$1"
    local entries="$2"

    # Don't do anything if the file isn't there
    if [ ! -f "$file" ]; then
        return
    fi

    if grep -q "^# HEAT_HOSTS_START" "$file"; then
        temp=$(mktemp)
        awk -v v="$entries" '/^# HEAT_HOSTS_START/ {
            print $0
            print v
            f=1
            }f &&!/^# HEAT_HOSTS_END$/{next}/^# HEAT_HOSTS_END$/{f=0}!f' "$file" > "$temp"
            echo "INFO: Updating hosts file $file, check below for changes"
            diff "$file" "$temp" || true
            cat "$temp" > "$file"
    else
        echo -ne "\n# HEAT_HOSTS_START - Do not edit manually within this section!\n" >> "$file"
        echo "$entries" >> "$file"
        echo -ne "# HEAT_HOSTS_END\n\n" >> "$file"
    fi

}

if [ ! -z "$hosts" ]; then
    for tmpl in /etc/cloud/templates/hosts.*.tmpl ; do
        write_entries "$tmpl" "$hosts"
    done
    write_entries "/etc/hosts" "$hosts"
else
    echo "No hosts in Heat, nothing written."
fi
