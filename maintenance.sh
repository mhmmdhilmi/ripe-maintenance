#!/bin/bash

state=`which ls`
mmcli=`which mmcli`
nmcli=`which nmcli`
cat=`which cat`

if mmcli -L | grep 'No modems were found' > /dev/null 2>&1; then
        echo "Modems not found"
        exit
fi

getParam(){
	for _id in `$mmcli -L | awk '{print $1}' | sed 1,2d`; do
		modem_id=`basename "$_id"`
		provider=`$mmcli -m $modem_id | grep "operator name" | awk '{print $4$5}' | cut -d "'" -f2`
		gateway_ip=`$nmcli c s ${provider,,} | grep IP4.GATEWAY | awk '{print $2}'`
	
		echo ${provider,,} >> /tmp/provider_list.txt
		echo $gateway_ip >> /tmp/gateway_list.txt
		paste -d' ' /tmp/provider_list.txt /tmp/gateway_list.txt >> /tmp/state.txt
	done
}

last_state(){
	num=`cat /tmp/state.txt | wc -l`
	for i in `seq 1 $num`; do
		last_provider=`$cat /tmp/state.txt | sed -n "$i"p | awk {'print $1'}`
	 	last_gateway=`$cat /tmp/state.txt | sed -n "$i"p | awk {'print $2'}`
	 	current_provider=`$nmcli c s -a | grep "$last_provider" | awk {'print $1'}`
	 	current_gateway=`$nmcli c s $last_provider | grep IP4.GATEWAY | awk '{print $2}'`

	 	if [[ "$last_provider" == "$current_provider" && "$last_gateway" == "$current_gateway" ]]; then
	 		echo "no update"
	 	else
	 		echo "updatting system"
	 		source "recovery.sh"
	 	fi
	done
}

if [ ! -z `$state /tmp | grep state` ]; then
	last_state
	rm -f /tmp/{state,provider_list,gateway_list}.txt
	getParam
else 
	getParam	
fi
