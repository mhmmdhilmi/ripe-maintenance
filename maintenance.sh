#!/bin/bash 

mmcli=`which mmcli`
nmcli=`which nmcli`
cat=`which cat`

connected_modem=`$nmcli c s -a | grep gsm | wc -l`
detected_modem=`mmcli -L | grep Modem | wc -l`

redial(){
	disconnect_modem=`cat /tmp/modem_check/result_list.txt | grep unknown | wc -l`
	echo "Reconnecting modem ..."

	restart modem
	for i in `seq 1 $disconnect_modem`; do
		modem_id=`cat /tmp/modem_check/result_list.txt | grep "unknown" | awk {'print $1'} | sed -n "$i"p`
		$mmcli -r -m $modem_id
	done

	sleep 60

	#redial modem
	for i in `seq 1 $disconnect_modem`; do
		provider=`cat /tmp/modem_check/check_list.txt | sed -n "$i"p`
		$nmcli c u $provider
	done
}

if mmcli -L | grep 'No modems were found' > /dev/null 2>&1; then
        echo "Modems not found"
        exit
fi

#remove temporary file
mkdir -p /tmp/modem_check 
rm -f /tmp/modem_check/{id_list,provider_list,ifname_list,check_list,result_list,tmp_list,result_list,message}.txt

#check from detected modem
for _id in `$mmcli -L | awk '{print $1}' | sed 1,2d`; do
	modem_id=`basename "$_id"`
	provider=`$mmcli -m $modem_id | grep "operator name" | awk '{print $4$5}' | cut -d "'" -f2`
	ifname=`$mmcli -m $modem_id | grep primary | awk '{print $4}' | cut -d "'" -f2`
	
	echo $modem_id >> /tmp/modem_check/id_list.txt
	echo ${provider,,} >> /tmp/modem_check/provider_list.txt
	echo $ifname >> /tmp/modem_check/ifname_list.txt
done

paste -d' ' /tmp/modem_check/id_list.txt /tmp/modem_check/provider_list.txt >> /tmp/modem_check/tmp_list.txt
paste -d' ' /tmp/modem_check/tmp_list.txt /tmp/modem_check/ifname_list.txt >> /tmp/modem_check/result_list.txt

#detected vs connected
if [ "$connected_modem" == "$detected_modem" ]; then
	echo "all of $connected_modem modem(s) connected" >> /tmp/modem_check/message.txt 
	exit
else 
	echo "$(($detected_modem - $connected_modem)) of $detected_modem modem(s) disconnected" >> /tmp/modem_check/message.txt 
	for i in `seq 1 $detected_modem`; do
		check=`$nmcli c s | grep gsm | awk {'print $1'} | sed -n "$i"p`
		if [[ -z `$cat /tmp/modem_check/result_list.txt | awk {'print $2'} | grep "$check"` ]]; then
			echo "$check disconnected" >> /tmp/modem_check/message.txt 
			echo "$check" >> /tmp/modem_check/check_list.txt
		fi
	done
	redial
fi

token="697263182:AAEljlmqD5wGKO1q6eSb6_Sn710gIOWey0s"
msg=cat /tmp/modem_check/message.txt
chatid="-272438846"
curl -s -F chat_id=$chatid -F text="$msg" https://api.telegram.org/bot$token/sendMessage > /dev/null

