#!/bin/bash 

mmcli=`which mmcli`
nmcli=`which nmcli`
cat=`which cat`

connected_modem=`$nmcli c s -a | grep gsm | wc -l`
detected_modem=`mmcli -L | grep Modem | wc -l`

enable(){
	provider=$1
	provider_apn=$2
	modem_id=$3
	state=$4

	echo "Enable ${provider,,} interface"
	if [ "$state" == "${provider,,}" ]; then
		echo "[!] Interface ${provider,,} is exist, I do nothing :-)"
	else
		echo "Interface ${provider,,} successfully created and enabled"
		$nmcli c add type gsm ifname $ifname con-name ${provider,,} apn $provider_apn > /dev/null 2>&1
		sleep 5
	fi
}

#remove temporary file
rm -f /tmp/list.txt

#check from detected modem
for _id in `$mmcli -L | awk '{print $1}' | sed 1,2d`; do
	modem_id=`basename "$_id"`
	provider=`$mmcli -m $modem_id | grep "operator name" | awk '{print $4$5}' | cut -d "'" -f2`
	echo ${provider,,} >> /tmp/list.txt
done

#detected vs connected
if [ "$connected_modem" == "$detected_modem" ]; then
	echo "all of $connected_modem modem(s) connected"
	exit
else
	echo "$connected_modem of $detected_modem modem(s) disconnected"
	for i in `seq 1 $detected_modem`; do
		check=`$nmcli c s | grep gsm | awk {'print $1'} | sed -n "$i"p`
		if [[ -z `$cat /tmp/list.txt | grep "$check"` ]]; then
			echo "$check disconnected"
		fi
	done

	echo "Reconnecting modem ..."

	# Enabling modem
	for _id in `$mmcli -L | awk '{print $1}' | sed 1,2d`; do

		modem_id=`basename "$_id"`
		provider=`$mmcli -m $modem_id | grep "operator name" | awk '{print $4$5}' | cut -d "'" -f2`
		ifname=`$mmcli -m $modem_id | grep primary | awk '{print $4}' | cut -d "'" -f2`
		manufacture=`$mmcli -m $modem_id | grep manufacture | awk '{print $4}' | cut -d "'" -f2`
		model=`$mmcli -m $modem_id | grep model | awk '{print $3}' | cut -d "'" -f2`
		state=`$nmcli c s ${provider,,} | grep connection.id | awk '{print $2}'`

		#Disable/Enable modem before dialing
		echo "=============================================="
		echo "Modem $manufacture $model succesfully enabled!" 
		$mmcli -m $modem_id -e > /dev/null 2>&1


		case "$provider" in
			"INDOSATOOREDOO" ) enable "$provider" "indosatgprs" "$modem_id" "$state"
				;;
			"ISAT" ) enable "$provider" "indosatgprs" "$modem_id" "$state"
				;;
			"XL" ) enable "$provider" "internet" "$modem_id" "$state"
				;;
			"3" ) enable "$provider" "3gprs" "$modem_id" "$state"
				;;
			"smartfren" ) enable "$provider" "smartfren4G" "$modem_id" "$state"
				;;
			"TSEL" ) enable "$provider" "telkomsel" "$modem_id" "$state"
				;;
		esac
	done
fi


