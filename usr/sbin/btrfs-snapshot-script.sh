#! /usr/bin/bash

declare -r snapshot_dir="/var/.snapshots/"
declare -r tmp_dir="/tmp/snapshots/"
declare -r backup_dir="/media/backup/"

get_snapshot_dates() {
    local snapshot_identifier=$1
    local type=$2
    local snapshots=$(ls "${snapshot_dir}${snapshot_identifier}" -1q | sort)
    local selected_snapshot

    if [[ $type = "latest" ]]; then
        selected_snapshot=$(echo "$snapshots" | tail -n1)
        echo "Latest snapshot: ${selected_snapshot}" | systemd-cat --identifier=btrfs-snapshot-script.sh
    elif [[ $type = "oldest" ]]; then
        selected_snapshot=$(echo "$snapshots" | head -n1)
        echo "Oldest snapshot: ${selected_snapshot}" | systemd-cat --identifier=btrfs-snapshot-script.sh
    fi
    echo $selected_snapshot
}

send_snapshot() {
    local snapshot_filename=$1
    local snapshot_number=$2
    local snapshot_latest=$3
    local stderr
    local exit_status

    if [[ $snapshot_number -eq 0 ]]; then
        echo "Sending snapshot ${snapshot_dir}${snapshot_filename} to ${tmp_dir}${snapshot_filename}" | systemd-cat --identifier=btrfs-snapshot-script.sh
        stderr=$(btrfs send -f "${tmp_dir}${snapshot_filename}" "${snapshot_dir}${snapshot_filename}" 2>&1 1>/dev/null)
        exit_status=$?
    else
        echo "Sending snapshot ${snapshot_dir}${snapshot_filename} to ${tmp_dir}${snapshot_filename} with delta ${snapshot_dir}${snapshot_latest}" | systemd-cat --identifier=btrfs-snapshot-script.sh
        stderr=$(btrfs send -p "${snapshot_dir}${snapshot_latest}" -f "${tmp_dir}${snapshot_filename}" "${snapshot_dir}${snapshot_filename}" 2>&1 1>/dev/null)
        exit_status=$?
    fi

    if [[ $exit_status -ne 0 ]]; then
        echo -e "btrfs send failed with exit status: $exit_status.\nPrinting stderr:\n$stderr" | systemd-cat --identifier=btrfs-snapshot-script.sh
    fi

    return $exit_status
}

receive_snapshot() {
    local snapshot_identifier=$1
    local snapshot_filename=$2
    local exit_status


    echo "Remounting ${backup_dir}${snapshot_identifier} as rw" | systemd-cat --identifier=btrfs-snapshot-script.sh
    mount -o remount,rw "${backup_dir}${snapshot_identifier}"

    echo "Receiving snapshot at ${backup_dir}${snapshot_identifier}/${snapshot_filename} from ${tmp_dir}${snapshot_filename}" | systemd-cat --identifier=btrfs-snapshot-script.sh
    stderr=$(btrfs receive -f "${tmp_dir}${snapshot_filename}" "${backup_dir}${snapshot_identifier}/${snapshot_filename}" 2>&1 1>/dev/null)
    exit_status=$?

    echo "Remounting ${backup_dir}${snapshot_identifier} as ro" | systemd-cat --identifier=btrfs-snapshot-script.sh
    mount -o remount,ro "${backup_dir}${snapshot_identifier}"

    if [[ $exit_status -ne 0 ]]; then
        echo -e "btrfs receive failed with exit status: $exit_status.\nPrinting stderr:\n$stderr" | systemd-cat --identifier=btrfs-snapshot-script.sh
    fi

    return $exit_status
}

process_snapshot() {
    local subvol=$1
    local snapshot_identifier=$2
    local snapshot_filename=$3
    local snapshot_number=$4

    local snapshot_latest
    local snapshot_oldest
    
    local exit_status
    local stderr

    echo "Starting on $snapshot_identifier - subvol $subvol " | systemd-cat --identifier=btrfs-snapshot-script.sh

    if [[ $snapshot_number -gt 0 ]]; then
        snapshot_latest=$(get_snapshot_dates "${snapshot_identifier}" "latest" )
    fi

    echo "Creating snapshot: ${snapshot_dir}${snapshot_filename}" | systemd-cat --identifier=btrfs-snapshot-script.sh
    stderr=$(btrfs subvolume snapshot -r "${subvol}" "${snapshot_dir}${snapshot_filename}" 2>&1 1>/dev/null)

    if [[ $? -ne 0 ]]; then
        echo -e "btrfs subvolume snapshot failed with exit status: $exit_status.\nPrinting stderr:\n$stderr" | systemd-cat --identifier=btrfs-snapshot-script.sh
        return 1
    fi

    if ! send_snapshot "${snapshot_filename}" "${snapshot_number}" "${snapshot_latest}"; then
        return 1
    fi


    if ! receive_snapshot ${snapshot_identifier} ${snapshot_filename} ]]; then
        return 1
    fi


    if [[ $snapshot_number -gt 2 ]]; then
        echo "Snapshot quota reached - rotating" | systemd-cat --identifier=btrfs-snapshot-script.sh
        snapshot_oldest=$(get_snapshot_dates ${snapshot_identifier} "oldest")
        btrfs subvolume delete "${snapshot_dir}${snapshot_oldest}"
    fi

    echo "Deleting ${tmp_dir}${snapshot_filename}" | systemd-cat --identifier=btrfs-snapshot-script.sh
    rm -f "${tmp_dir}${snapshot_filename}"

    echo "Snapshot of $snapshot_identifier finished successfully" | systemd-cat --identifier=btrfs-snapshot-script.sh
    return 0
}

main() {

    declare -r date=$(date +'%Y-%m-%d-%H%M')
    declare -r root_subvol="@"
    declare -r home_subvol="@home"
    declare -r root_snapshot_identifier="root"
    declare -r home_snapshot_identifier="home"
    declare -r root_snapshot_filename="$root_snapshot_identifier-$date"
    declare -r home_snapshot_filename="$home_snapshot_identifier-$date"
    declare -ri nr_root_snapshots=$(ls "${snapshot_dir}${root_snapshot_identifier}" -1q | wc -l)
    declare -ri nr_home_snapshots=$(ls "${snapshot_dir}${home_snapshot_identifier}" -1q | wc -l)

    mkdir "$tmp_dir"

    echo "Starting btrfs-snapshot-script.sh" | systemd-cat --identifier=btrfs-snapshot-script.sh

    if ! process_snapshot "${root_subvol}" "${root_snapshot_identifier}" "${root_snapshot_filename}" "${nr_root_snapshots}"; then
        echo "Failed to create snapshot of root - subvol '@'." | systemd-cat --identifier=btrfs-snapshot-script.sh
    fi

    if ! process_snapshot "${home_subvol}" "${home_snapshot_identifier}" "${home_snapshot_filename}" "${nr_home_snapshots}"; then
        echo "Failed to create snapshot of home - subvol '@home'." | systemd-cat --identifier=btrfs-snapshot-script.sh
    fi
}

main "$@"
