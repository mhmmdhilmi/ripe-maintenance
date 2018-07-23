#!/bin/bash 

mmcli=`which mmcli`
nmcli=`which nmcli`
cat=`which cat`

rm -f /tmp/list.txt

connected_modem=`$nmcli c s -a | grep gsm | wc -l`
detected_modem=`mmcli -L | grep Modem | wc -l`


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
	echo "$detected_modem of $connected_modem disconnected"
	echo "============================================" 
	for i in `seq 1 $connected_modem`; do
		check=`$nmcli c s -a | grep gsm | awk {'print $1'} | sed -n $ip`
		if [ ! $check == `$cat /tmp/list.txt | grep $check` ]; then
			echo "$check disconnected"
		fi
	done
fi

