#!/bin/bash

if [ -z "$1" ] 
then
>&2 echo "Missing argument: switch IP"
>&2 echo "Usage: "$0" ip_address_dgs-1100-16 [password]"
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

getcookie() {

CurrentAuth=$(curl --silent 'http://'$SwitchIP'/cgi/login.cgi' -H 'Referer: http://'$SwitchIP'/DGS-1100-16_1.10.016/login2.htm' --data 'pass='$SwitchPass |grep -Po '(?<=document.cookie=).*' | sed -e 's/^"//' -e 's/"$//')

if [ -z "$CurrentAuth" ]
then
>&2 echo "Wrong password! Exit"
 exit
fi


if [ -n "$CurrentAuth" ]
 then
  return 2
 else
  return 1
 fi

} # end fuction getcookie()

n=1

while [ $n -le 1 ] 
do
 getcookie
 if [ $? -eq 2 ]
 then
 n=2
 fi
done
>&2 echo $SwitchIP "wait response..."

TotalPages=$(curl --silent 'http://'$SwitchIP'/DGS-1100-16_1.10.016/DS/LAChannelSetting.js+DynamicForwarding.js' -H 'Referer: http://'$SwitchIP'/DGS-1100-16_1.10.016/iss/H_46_DF_Table.htm' -H 'Cookie: '$CurrentAuth | grep -Po '(?<=TotalPage = ).*[^;]')

CurPage=1

>&2 echo $TotalPages "total pages of fdb table"

while [ "$CurPage" -le "$TotalPages" ]
do
>&2 echo "Process" $CurPage "page"
curl --silent 'http://'$SwitchIP'/cgi/changePage.cgi'-H 'Referer: http://'$SwitchIP'/DGS-1100-16_1.10.016/iss/H_46_DF_Table.htm' -H 'Cookie: '$CurrentAuth --data 'pagenum='$CurPage >/dev/null

curl --silent 'http://'$SwitchIP'/DGS-1100-16_1.10.016/DS/LAChannelSetting.js+DynamicForwarding.js' -H 'Referer: http://'$SwitchIP'/DGS-1100-16_1.10.016/iss/H_46_DF_Table.htm' -H 'Cookie: '$CurrentAuth | pcregrep -M 'DynamicForwarding = .*(\n|.)*Total' |sed -e 's/DynamicForwarding = \[//g' -e '$d' -e 's/],//g' -e 's/\[//g' -e 's/\]];//g' -e "s/'//g" -e 's/,/;/g'

CurPage=$(( CurPage+1 ))

done
>&2 echo "Logout from "$SwitchIP
curl --silent -H 'Cookie: '$CurrentAuth 'http://'$SwitchIP'/cgi/logout.cgi' >/dev/null
