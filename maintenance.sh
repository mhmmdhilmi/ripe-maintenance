#!/bin/bash 

mmcli=`which mmcli`
nmcli=`which nmcli`
cat=`which cat`
tail=`which tail`

connected_modem=`$nmcli c s -a | grep gsm | wc -l`
detected_modem=`mmcli -L | grep Modem | wc -l`

redial(){
	disconnect_modem=`cat /tmp/modem_check/check_list.txt | wc -l`
	echo "Reconnecting modem ..."

	#sleep 30

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
	chatid="-272438846"
	curl -s -F chat_id="$chatid" -F text="$msg" https://api.telegram.org/bot$token/sendMessage > /dev/null
}

if mmcli -L | grep 'No modems were found' > /dev/null 2>&1; then
        echo "Modems not found"
        exit
fi

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
	send_message
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
	sleep 60
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
