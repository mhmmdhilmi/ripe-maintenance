
#!/bin/bash 

mmcli=`which mmcli`
nmcli=`which nmcli`
cat=`which cat`
tail=`which tail`
ip=`which ip`

connected_modem=`$nmcli c s -a | grep gsm | wc -l`
detected_modem=`mmcli -L | grep Modem | wc -l`

redial(){
	disconnect_modem=`cat /tmp/modem_check/check_list.txt | wc -l`
	echo "Reconnecting modem ..."

	#redial modem
	for i in `seq 1 $disconnect_modem`; do
		provider=`cat /tmp/modem_check/check_list.txt | sed -n "$i"p`
		$nmcli c u $provider
	done
}

send_message(){
	#Send message to telegram API (change your chatid and token)
	msg=`$cat /tmp/modem_check/message.txt`
	token="697263182:AAEljlmqD5wGKO1q6eSb6_Sn710gIOWey0s"
	chatid="393577627"
	curl -s -F chat_id="$chatid" -F text="$msg" https://api.telegram.org/bot$token/sendMessage > /dev/null
}


#remove temporary file
mkdir -p /tmp/modem_check 
rm -f /tmp/modem_check/{provider_list,gateway_list,check_list,result_list,message}.txt

#check from detected modem
for _id in `$mmcli -L | awk '{print $1}' | sed 1,2d`; do
	modem_id=`basename "$_id"`
	provider=`$mmcli -m $modem_id | grep "operator name" | awk '{print $4$5}' | cut -d "'" -f2`
	gateway_ip=`$nmcli c s ${provider,,} | grep IP4.GATEWAY | awk '{print $2}'`
	
	echo ${provider,,} >> /tmp/modem_check/provider_list.txt
	echo $gateway_ip >> /tmp/modem_check/gateway_list.txt
done

paste -d' ' /tmp/modem_check/provider_list.txt /tmp/modem_check/gateway_list.txt >> /tmp/modem_check/result_list.txt

#detected vs connected
if [ "$connected_modem" == "$detected_modem" ]; then
	echo "all of $connected_modem modem(s) connected" >> /tmp/modem_check/message.txt 
else
	echo "$(($detected_modem - $connected_modem)) of $detected_modem modem(s) disconnected" >> /tmp/modem_check/message.txt 
	for i in `seq 1 $detected_modem`; do
		if [[ -z `$cat /tmp/modem_check/result_list.txt | sed -n "$i"p | awk {'print $2'}` ]]; then
			check=`$cat /tmp/modem_check/result_list.txt | sed -n "$i"p | awk {'print $1'}`
			echo "$check disconnected" >> /tmp/modem_check/message.txt 
			echo "$check" >> /tmp/modem_check/check_list.txt		
		fi
	done
	send_message
	redial
	sleep 30
	rm -f /tmp/modem_check/message.txt
	while IFS= read line
	do
	  if $nmcli c | grep $line | grep -q 'gsm'; then
	    echo "$line reconnected" >> /tmp/modem_check/message.txt
	  else
	    echo "$line cannot reconnect" >> /tmp/modem_check/message.txt
	  fi
	done < /tmp/modem_check/check_list.txt
	send_message
fi

#Update Route
for _id in `$mmcli -L | awk '{print $1}' | sed 1,2d`; do
        modem_id=`basename "$_id"`
        provider=`$mmcli -m $modem_id | grep "operator name" | awk '{print $4$5}' | cut -d "'" -f2`
        active_route=`$nmcli c s ${provider,,} | grep IP4.GATE |  awk '{ print $2 }'`

        if [ "$nmcli c s ${provider,,} | grep STATE | awk '{ print $2 }'" != "activated" ]; then

                check_route=`$ip route list table $provider | awk '{ print $3 }'`

                echo "Existing route: $active_route"
                echo "Last route: $check_route"

                if [ "$check_route" == " " ]; then
                        echo "Route is changed, updating..."
                        $ip route add default via $active_route table $provider
                elif [ "$check_route" != "$active_route" ]; then
                        echo "Route found, checksum failed, updating..."
                        $ip route add default via $active_route table $provider
                else
                        echo "Route found, checksum OK."
                fi
        fi
done
