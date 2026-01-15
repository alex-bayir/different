#!/bin/bash
help='report.sh -p <proxy address:port> --chat <telegram chat id> --thread <telegram mesage thread id> --tg <telegram bot token> --kuma <kuma token> --st $(date -d "-1 days" +"%FT08:00:00Z") --et $(date +"%FT08:00:00Z")'
#> crontab -l
# 0 8 * * * /opt/kaspersky/kuma/core/scripts/telegram-report.sh -p 'proxy.example.com:8888' --chat '<telegram chat id>' --thread '<telegram mesage thread id>' --tg '<telegram bot token>' --kuma '<kuma token>' --st $(date -u -d '-1 days' +'\%FT\%H:00:00Z') --et $(date -u +'\%FT\%H:00:00Z')
# 0 8 * * 1 /opt/kaspersky/kuma/core/scripts/telegram-report.sh -p 'proxy.example.com:8888' --chat '<telegram chat id>' --thread '<telegram mesage thread id>' --tg '<telegram bot token>' --kuma '<kuma token>' --st $(date -u -d '-2 days' +'\%FT\%H:00:00Z') --et $(date -u +'\%FT\%H:00:00Z')
#> /opt/kaspersky/kuma/core/scripts/telegram-report.sh -p 'proxy.example.com:8888' --chat '<telegram chat id>' --thread '<telegram mesage thread id>' --tg '<telegram bot token>' --kuma '<kuma token>' --st $(date -u -d '-1 days' +'%FT%H:00:00Z') --et $(date -u +'%FT%H:00:00Z')
while [ "$#" -gt 0 ]; do
    case $1 in
        -c|--chat) CHAT=$2; shift;;
        -t|--thread) THREAD=$2; shift;;
        --tg) TG=$2; shift;;
        --kuma) KUMA=$2; shift;;
        -p|--proxy) PROXY=$2; shift;;
        --st) st=$2; shift;;
        --et) et=$2; shift;;
        --help) echo -e "$help"; exit 0;;
        *) echo "Unknown parameter passed: $1"; echo -e "$help"; exit 1 ;;
    esac
    shift
done

dir=/opt/kaspersky/kuma/core/scripts

#st=$(date +"%FT%H:%M:%SZ" -d yesterday)
#et=$(date +"%FT%H:%M:%SZ")
stf=$(date +"%F %H:%M" -d $st) # +UTC TimeZone and format
etf=$(date +"%F %H:%M" -d $et) # +UTC TimeZone and format
events=$(curl -s -X POST "https://kuma.example.com:7223/api/v3/events/" -H "Authorization: Bearer $KUMA" -d '{
    "sql": "SELECT if(Type=3,extract(replaceRegexpOne(BaseEvents,'\'',\"ServiceName\":\"[^\"]+Correlator\"'\'','\'''\''),'\''\"ServiceName\":\"([^\"]+)\"'\''),ServiceName) as service, countIf(Type=1) as base, countIf(Type=3 AND NOT service ilike '\''%correlator%'\'') as correlated FROM `events` WHERE NOT match(CorrelationRuleName, '\''R\\d\\d\\d_\\d\\d_'\'') GROUP BY service ORDER BY service ASC LIMIT 20",
    "emptyFields": true,
    "rawTimestamps": false,
    "period": {
        "from": "'$st'",
        "to": "'$et'"
    }
}')

alerts=$(curl -s -X POST "https://kuma.example.com:7223/api/v3/events/" -H "Authorization: Bearer $KUMA" -d '{
    "sql": "SELECT count(ID) AS count,replace(replace(replace(replace(toString(any(Priority)),'\''1'\'','\''🟢'\''),'\''2'\'','\''🟡'\''),'\''3'\'','\''🔴'\''),'\''4'\'','\''☢️'\'') as priority, if(match(CorrelationRuleName,'\''NAD (alerts|detections).*'\''),concat('\''NAD. '\'',Name),if(CorrelationRuleName like '\''WAF alerts%'\'',concat('\''WAF. '\'',DeviceEventCategory),CorrelationRuleName)) as rule FROM `events` WHERE Type = 3 AND NOT match(rule, '\''R\\d\\d\\d_\\d\\d_'\'') GROUP BY rule ORDER BY count DESC LIMIT 50",
    "emptyFields": true,
    "rawTimestamps": false,
    "period": {
        "from": "'$st'",
        "to": "'$et'"
    }
}')

eventstable=$(echo $events | jq -r '"|       service       |    base    | correlated |\n|---------------------|------------|------------|\n" + (map("|\(.service[0:21] | . + (" " * (21 - length)))|\(.base | tostring | (" " * (12 - length)) + .)|\(.correlated | tostring | (" " * (12 - length)) + .)|") | join("\n")) + "\n|Итого                |" + ([.[].base] | add | tostring | (" " * (12 - length) + .)) + "|" + ([.[].correlated] | add | tostring | (" " * (12 - length) + .)) +"|"')
eventscsv=$(echo $events | jq -r '.[] | [.service,.base,.correlated] | @csv' | sed -ze 's/[\\\/]/\\\\\\&/g' -e 's/\n/\\n/g')
alertstable=$(echo $alerts | jq -r '"|pr|                                  rule                                  | count |\n|--|------------------------------------------------------------------------|-------|\n" + (.[:30] | map("|\(.priority)|\(.rule[0:72] | (. + " " * (72 - length)))|\(.count | tostring | (" " * (7 - length) + .))|") | join("\n")) +"\n" + (if length > 30 then "|⚪|Остальное                                                               |"+(.[30:] | map(.count) | add | tostring | (" " * (7 - length) + .))+"|\n" else "" end) + (("|Итого: ☢️x" + (map(select(.priority == "☢️").count) | add | tostring | sub("null";"0")) + " 🔴x" + (map(select(.priority == "🔴").count) | add | tostring | sub("null";"0")) + " 🟡x" + (map(select(.priority == "🟡").count) | add | tostring | sub("null";"0")) + " 🟢x" + (map(select(.priority == "🟢").count) | add | tostring | sub("null";"0"))) | (. + " " * (71 - length))) + "|" + ([.[].count] | add | tostring | (" " * (7 - length) + .)) + "|"')
alertscsv=$(echo $alerts | jq -r '.[] | [.priority,.rule,.count] | @csv' | sed -ze 's/[\\\/]/\\\\\\&/g' -e 's/\n/\\n/g')
alertsurl="https://kuma.example.com:7220/threat-hunting#/threat-hunting?search=%257B%2522sql%2522%253A%2522SELECT%2520count%28ID%29%2520AS%2520count%252Cany%28Priority%29%2520as%2520Priority%252C%2520if%28CorrelationRuleName%2520like%2520%27NAD%2520detections%2525%27%252Cconcat%28%27NAD.%2520%27%252CName%29%252Cif%28CorrelationRuleName%2520like%2520%27WAF%2520alerts%2525%27%252Cconcat%28%27WAF.%2520%27%252CDeviceEventCategory%29%252CCorrelationRuleName%29%29%2520as%2520rule%252C%2520any%28extract%28replaceRegexpOne%28BaseEvents%252C%27%252C%255C%255C%255C%2522ServiceName%255C%255C%255C%2522%253A%255C%255C%255C%2522%255B%255E%255C%255C%255C%2522%255D%252BCorrelator%255C%255C%255C%2522%27%252C%27%27%29%252C%27%255C%255C%255C%2522ServiceName%255C%255C%255C%2522%253A%255C%255C%255C%2522%28%255B%255E%255C%255C%255C%2522%255D%252B%29%255C%255C%255C%2522%27%29%29%2520as%2520service%2520FROM%2520%2560events%2560%2520WHERE%2520Type%2520%253D%25203%2520AND%2520NOT%2520match%28rule%252C%2520%27R%255C%255C%255C%255Cd%255C%255C%255C%255Cd%255C%255C%255C%255Cd_%255C%255C%255C%255Cd%255C%255C%255C%255Cd_%27%29%2520GROUP%2520BY%2520rule%2520ORDER%2520BY%2520count%2520DESC%2520LIMIT%2520250%2522%252C%2522period%2522%253A%257B%2522from%2522%253A$(date +"%s" -d "$st")000%252C%2522to%2522%253A$(date +"%s" -d "$et")000%257D%257D"
curl $([ $PROXY ] && echo "--proxy $PROXY") -X POST "https://api.telegram.org/bot$TG/sendMessage?chat_id=$CHAT&message_thread_id=$THREAD&parse_mode=html" --data-urlencode "text=$(echo -e "$stf - $etf\nEvents:\n<pre>$eventstable</pre>\n<a href=\"$alertsurl\">Alerts:</a>\n<pre>$alertstable</pre>")"

file="$(date +"%Y-%m-%d" -d $et).html"
cat "$dir/report-template.html" | sed -e "s/{{events-date-export}}/$(echo $stf - $etf)/g" | sed -e "s/{{events-data-export}}/$eventscsv/g" -e "s/{{alerts-data-export}}/$alertscsv/g" > "$dir/$file"
curl $([ $PROXY ] && echo "--proxy $PROXY") -X POST "https://api.telegram.org/bot$TG/sendDocument?chat_id=$CHAT&message_thread_id=$THREAD" -F document=@$dir/$file
rm $dir/$file
