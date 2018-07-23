#!/bin/bash

mmcli=`which mmcli`
nmcli=`which nmcli`
cat=`which cat`

connected_modem=`$nmcli c s -a | grep gsm | wc -l`
detected_modem=`mmcli -L | grep gsm | wc -l`


#check from detected modem
for _id in `$mmcli -L | awk '{print $1}' | sed 1,2d`; do
	provider=`$mmcli -m $modem_id | grep "operator name" | awk '{print $4$5}' | cut -d "'" -f2`
	echo $provider >> ~/script/kim.text
done

#detected vs connected
if [ "$connect_modem" == "$detected_modem" ]; then
	echo "all of $connected_modem modem(s) connected"
else
	echo "$detected_modem of $connected_modem disconnected"
	echo "============================================" 
	for i in `seq 1 $connected_modem`; do
		check=`$nmcli c s -a | grep gsm | awk {'print &1'} | sed -n $ip`
		if [ ! $check == `$cat ~/script/kim.text | grep $check` ]; then
			echo "$check disconnected"
		fi
	done
fi

