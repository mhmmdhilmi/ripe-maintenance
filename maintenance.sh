#!/bin/bash 

mmcli=`which mmcli`
nmcli=`which nmcli`
cat=`which cat`

connected_modem=`$nmcli c s -a | grep gsm | wc -l`
detected_modem=`mmcli -L | grep Modem | wc -l`

if mmcli -L | grep 'No modems were found' > /dev/null 2>&1; then
        echo "Modems not found"
        exit
fi

#remove temporary file
mkdir -p /tmp/modem_check 
rm -f /tmp/modem_check/{id_list,provider_list,ifname_list,result_list,tmp_list,result_list}.txt

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
	echo "all of $connected_modem modem(s) connected"
	exit
else
	echo "$connected_modem of $detected_modem modem(s) disconnected"
	for i in `seq 1 $detected_modem`; do
		check=`$nmcli c s | grep gsm | awk {'print $1'} | sed -n "$i"p`
		if [[ -z `$cat /tmp/modem_check/result_list.txt | awk {'print $2'} | grep "$check"` ]]; then
			echo "$check disconnected" 
		fi
	done
fi
