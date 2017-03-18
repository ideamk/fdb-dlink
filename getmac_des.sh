#!/bin/bash

if [ -z "$1" ] 
then
>&2 echo "Missing argument: switch IP"
>&2 echo "Usage: "$0" ip_address_des-1100-xx [password]"
exit
fi
SwitchIP=$1

if [ -z "$2" ]
 then
 stty -echo
 read -p "Password for "$SwitchIP": " SwitchPass; >&2 echo
 stty echo
else
 SwitchPass=$2
fi

curl -j --silent -c $SwitchIP 'http://'$SwitchIP'/cgi/login.cgi?pass='$SwitchPass >/dev/null


>&2 echo $SwitchIP "wait response..."

TotalPages=$(curl --silent -b $SwitchIP 'http://'$SwitchIP'/DFD.js' -H 'Referer: http://'$SwitchIP'/H_46_DF_Table.htm' | grep -Po '(?<=TotalPage = ).*[^;]')
if [ -z "$TotalPages" ]
then
>&2 echo "Wrong password! Exit"
 exit
fi

CurPage=1

>&2 echo $TotalPages "total pages of fdb table"

while [ "$CurPage" -le "$TotalPages" ]
do
>&2 echo "Process" $CurPage "page"
curl --silent -b $SwitchIP 'http://'$SwitchIP'/cgi/changePage.cgi?pagenum='$CurPage -H 'Referer: http://'$SwitchIP'/H_46_DF_Table.htm' >/dev/null
curl --silent -b $SwitchIP 'http://'$SwitchIP'/DFD.js' -H 'Referer: http://'$SwitchIP'/H_46_DF_Table.htm' | pcregrep -M 'DynamicForwarding = .*(\n|.)*Total' |sed -e 's/DynamicForwarding = \[//g' -e '$d' -e 's/],//g' -e 's/\[//g' -e 's/\]];//g' -e "s/'//g" -e 's/,/;/g'
CurPage=$(( CurPage+1 ))

done
>&2 echo "Logout from "$SwitchIP
curl --silent -b $SwitchIP 'http://'$SwitchIP'/cgi/logout.cgi' >/dev/null
rm $SwitchIP >/dev/null
