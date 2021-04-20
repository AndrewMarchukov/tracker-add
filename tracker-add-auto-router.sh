#!/bin/sh
# Get transmission credentials and ip or dns address
auth=
host=localhost

record_file="/tmp/tracker_add.rec"
temp_file="/tmp/tracker_add_id.info"
[[ -f $record_file ]] || touch $record_file
add_trackers () {
	torrent_hash=$1
	id=$2
	trackerslist=/tmp/trackers.txt
    for base_url in https://raw.githubusercontent.com/ngosang/trackerslist/master/trackers_all.txt ; do
        curl -o "$trackerslist" "${base_url}"
        echo "URL for ${base_url}"
        echo "Adding trackers for $torrent_name..."
        for tracker in $(cat $trackerslist) ; do
            echo "${tracker}..."
        if [ $(transmission-remote "$host"  --auth="$auth" --torrent "${torrent_hash}" -td "${tracker}" | grep -c 'success') -eq 0 ]; then
            echo ' already added.'
        else
            echo ' done.'
        fi
        done
    done
}
while true ; do
    sleep 25
    # Get list of active torrents
    ids="$(transmission-remote "$host" --auth="$auth" --list | grep -vE 'Seeding|Stopped|Finished|[[:space:]]100%[[:space:]]' | grep '^ ' | awk 'BEGIN{IGNORECASE=1} $1 !~ /^id$/ { print $1 }')"
    for id in $ids ; do
        transmission-remote "$host" --auth="$auth" --torrent "$id" --info > $temp_file
        add_date="$(grep '^  Date added: ' $temp_file |cut -c 21-)"
        hash="$(grep '^  Hash: ' $temp_file | awk '{ print $2 }')"
        torrent_name="$( grep '^  Name: ' $temp_file |cut -c 9-)"
    
    if [ "$(grep -c "$hash $add_date" $record_file)" -eq "0" ]; then
        add_trackers "$hash" "$id"
        echo "$hash $add_date" >> $record_file
    fi
    done
	# delete removed torrents record from record file
    for hash in $(awk '{print $1}' $record_file); do
        [[ $(transmission-remote "$host"  --auth="$auth" --torrent "${torrent_hash}" --info | wc -l) -eq 0 ]] && sed -in $(grep -n $hash $record_file | awk -F ':' '{print $1}')'d' $record_file
    done
done
