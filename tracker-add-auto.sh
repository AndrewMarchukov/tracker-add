#!/bin/bash
# Get transmission credentials and ip or dns address
auth=user:password
host=localhost
# set trackers list space separated
trackers=https://raw.githubusercontent.com/ngosang/trackerslist/master/trackers_all.txt
pt_trackers=()

while true; do
    sleep 25
    add_trackers() {
        torrent_hash=$1
        id=$2
        for base_url in $trackers; do
            trackerslist=/tmp/trackers.$(echo "$base_url" | cksum | cut -d' ' -f1).txt
            curl -fsS -o "$trackerslist" -z "$trackerslist" "${base_url}"
            echo "URL for ${base_url}"
            echo "Adding trackers for $torrent_name..."
            for tracker in $(cat $trackerslist); do
                echo -n "${tracker}..."
                if transmission-remote "$host" --auth="$auth" --torrent "${torrent_hash}" -td "${tracker}" | grep -q 'success'; then
                    echo ' done.'
                else
                    echo ' already added.'
                fi
            done
        done
        sleep 3m
        rm -f "/tmp/TTAA.$id.lock"
    }
    # Get list of active torrents
    ids="$(transmission-remote "$host" --auth="$auth" --list | grep -vE '^[[:space:]]+ID[[:space:]]|Seeding|Stopped|Finished|[[:space:]]100%[[:space:]]' | grep '^ ' | awk '{ gsub(/[^0-9]/,"",$1); print $1 }')"
    for id in $ids; do
        info="$(transmission-remote "$host" --auth="$auth" --torrent "$id" --info)"
        case "$info" in *"Public torrent: No"*) continue;; esac
        hash="$(echo "$info" | grep '^  Hash: ' | awk '{ print $2 }')"
        add_date="$(echo "$info" | grep '^  Date added: ' | cut -c 21-)"
        add_date_t="$(date -d "$add_date" "+%Y-%m-%d %H:%M")"
        dater="$(date "+%Y-%m-%d %H:%M")"
        dateo="$(date -d "1 minutes ago" "+%Y-%m-%d %H:%M")"
        tracker0="$(transmission-remote "$host" --auth="$auth" -t "$id" -it | sed -n '2,2p' | awk '{print $3}' | sed -e 's|.*://||' -e 's|[:/].*||')"
        if [ ${#pt_trackers[@]} -gt 0 ] && [ -n "$tracker0" ] && [[ " ${pt_trackers[*]} " == *" $tracker0 "* ]]; then
            echo "skip id=" "$id" "$tracker0"
            continue
        fi

        if [ ! -f "/tmp/TTAA.$hash.lock" ]; then
            if [[ "$add_date_t" == "$dater" || "$add_date_t" == "$dateo" ]]; then
                torrent_name="$(echo "$info" | grep '^  Name: ' | cut -c 9-)"
                add_trackers "$hash" "$hash" &
                touch "/tmp/TTAA.$hash.lock"
            fi
        fi
    done
done
