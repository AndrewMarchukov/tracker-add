#!/bin/sh
# Get transmission credentials and ip or dns address
auth=user:password
host=localhost

trans="$(which transmission-remote) $host --auth=$auth"
while true ; do
    sleep 25

    add_trackers () {
        torrent_hash=$1
        id=$2
        trackerslist=/tmp/trackers.txt
        for base_url in https://raw.githubusercontent.com/ngosang/trackerslist/master/trackers_all.txt ; do
            if [ ! -f $trackerslist ]; then
                curl -o "$trackerslist" "${base_url}"
            fi
            Local=$(wc -c < $trackerslist)
            Remote=$(curl -sI "${base_url}" | awk '/Content-Length/ {sub("\r",""); print $2}')
            if [ "$Local" != "$Remote" ]; then
                curl -o "$trackerslist" "${base_url}"
            fi
            echo "URL for ${base_url}"
            echo "Adding trackers for $torrent_name..."
            for tracker in $(cat $trackerslist) ; do
                    echo -n "${tracker}..."
                if ${trans} --torrent "${torrent_hash}" -td "${tracker}" | grep -q 'success'; then
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
    ids="$(${trans} --list | grep -vE 'Seeding|Stopped|Finished|[[:space:]]100%[[:space:]]' | grep '^ ' | awk '{ print $1 }' | grep -vE 'ID')"
    for id in $ids ; do
        add_date="$(${trans} --torrent "$id" --info| grep '^  Date added: ' |cut -c 21-)"
        if [ $(uname) = "FreeBSD" ]; then
            add_date_t="$(date -jf "%+" "$add_date" "+%Y-%m-%d %H:%M")"
            dateo="$(date -jv-1M "+%Y-%m-%d %H:%M")"
        else
            add_date_t="$(date -d "$add_date" "+%Y-%m-%d %H:%M")"
            dateo="$(date -d "1 minutes ago" "+%Y-%m-%d %H:%M")"
        fi
        dater="$(date "+%Y-%m-%d %H:%M")"

        if [ ! -f "/tmp/TTAA.$id.lock" ]; then
            if [ "$add_date_t" = "$dater" -o "$add_date_t" = "$dateo" ]; then
                hash="$(${trans} --torrent "$id" --info | grep '^  Hash: ' | awk '{ print $2 }')"
                torrent_name="$(${trans} --torrent "$id" --info | grep '^  Name: ' |cut -c 9-)"
                add_trackers "$hash" "$id" &
                touch "/tmp/TTAA.$id.lock"
            fi
        fi
    done
done
