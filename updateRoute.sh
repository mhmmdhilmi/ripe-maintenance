#!/bin/bash 

mmcli=`which mmcli`
nmcli=`which nmcli`
cat=`which cat`
ip=`which ip`

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

