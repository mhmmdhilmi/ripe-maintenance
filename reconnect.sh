#!/bin/bash -x

mmcli=`which mmcli`
nmcli=`which nmcli`
cat=`which cat`

disconnect_modem=`cat /tmp/modem_check/result_list.txt | grep unknown | wc -l`

echo "Reconnecting modem ..."

#restart modem
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


