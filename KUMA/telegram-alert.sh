#!/bin/bash
help='notify.sh -p <proxy address:port> --chat <telegram chat id> --thread <telegram mesage thread id> --tg <telegram bot token> -m <message>'
while [ "$#" -gt 0 ]; do
    case $1 in
        -c|--chat) CHAT=$2; shift;;
        -t|--thread) THREAD=$2; shift;;
        --tg) TOKEN=$2; shift;;
        -m|--message) TEXT=$2; shift;;
        -p|--proxy) PROXY=$2; shift;;
        --help) echo -e "$help"; exit 0;;
        *) echo "Unknown parameter passed: $1"; echo -e "$help"; exit 1 ;;
    esac
    shift
done

TEXT=$(echo $TEXT | sed 's/[\][^n]/\\&/g')
while read ts; do TEXT=$(echo $TEXT | sed "s/$ts/$(date "+%Y-%m-%d %H:%M:%S" -d $(echo $ts | sed 's/\(@[0-9]\{10\}\)[0-9]\{3\}/\1/g'))/g"); done < <(echo $TEXT | grep -o '@[0-9]\{10\}[0-9]\{3\}')

curl $([ $PROXY ] && echo "--proxy $PROXY") -X POST "https://api.telegram.org/bot$TOKEN/sendMessage?chat_id=$CHAT&message_thread_id=$THREAD&parse_mode=html" --data-urlencode "text=$(echo -e $TEXT)"

<<kuma-response-rule
./telegram-alert.sh --proxy <proxy address:port> --chat <telegram chat id> --thread <telegram mesage thread id> --tg <telegram bot token> --message "{{if eq .Priority 1}}🟢{{end}}{{if eq .Priority 2}}🟡{{end}}{{if eq .Priority 3}}🔴{{end}}{{if eq .Priority 4}}☢️{{end}} <a href=\"https://kuma.example.com:7220/alerts/correlated-events/{{.ID}}?timestamp={{.Timestamp}}&cluster=1460dc0c-2218-46fd-bcde-36ae327c766a\">{{.CorrelationRuleName}}</a>\\n
time: @{{.Timestamp}}\\n{{if and (ne .DeviceProduct \"\") (ne .DeviceProduct \"KUMA\") (ne .S.url \"\")}}\\n
product: <a href=\"{{.S.url}}\">{{.DeviceProduct}}</a>{{end}}{{if ne .DeviceAction \"\"}}\\n
action: {{.DeviceAction}}{{end}}{{if ne .Severity \"\"}}\\n
severity: {{.Severity}}{{end}}{{if ne .DeviceEventCategory \"\"}}\\n
category: {{.DeviceEventCategory}}{{end}}{{if ne .Technique \"\"}}\\n
technique: {{.Technique}}{{end}}{{if ne .SourceAddress \"\"}}\\n
src.address: {{.SourceAddress}}:{{.SourcePort}} {{.SourceHostName}}{{end}}{{if ne .DestinationAddress \"\"}}\\n
dst.address: {{.DestinationAddress}}:{{.DestinationPort}} {{.DestinationHostName }}{{end}}{{if and (ne .SourceUserName \"\") (ne .SourceUserName \"-\")}}\\n
src.user: {{.SourceUserID}} {{.SourceUserName}}{{end}}{{if and (ne .DestinationUserName \"\") (ne .DestinationUserName \"-\")}}\\n
dst.user: {{.DestinationUserID}} {{.DestinationUserName}}{{end}}{{if and (ne .SourceProcessName \"\") (ne .SourceProcessName \"-\")}}\\n
src.process: {{.SourceProcessName}}{{end}}{{if and (ne .DestinationProcessName \"\") (ne .DestinationProcessName \"-\")}}\\n
dst.process: {{.DestinationProcessName}}{{end}}{{if or (ne .ApplicationProtocol \"\") (ne .TransportProtocol \"\")}}\\n
protocols: {{.ApplicationProtocol}} {{.TransportProtocol}}{{end}}{{if ne .RequestUrl \"\"}}\\n
url: {{.RequestUrl}}{{end}}{{if ne .Message \"\"}}\\n
message: {{.Message}}{{end}}"
kuma-response-rule
