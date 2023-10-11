#!/bin/bash
# shell server status
# 一款纯 shell 实现简易的 linux 设备状态监测

#设置监测的网口名称(可通过ifconfig查看,默认 eth0)
Interface=eth0

#设置刷新的时间间隔(单位秒,默认1秒刷新一次)
interval=1

#设置上传json的服务器名称(默认名称 status)
server_name=status

if [ ! -f "/sys/class/thermal/thermal_zone0/temp" ]
then
	echo 不支持CPU温度获取
	cpu_temp=null
	cpu_temp_support=error
	sleep 1
fi
date -u -d"+8 hour" +'%Y-%m-%d %H:%M:%S' &> /dev/null
if [ ! $? == 0 ]
then
	echo 不支持UTC时间偏差
	lastest_time_support=error
	sleep 1
fi
if [ $(cat /proc/net/dev | sed '1,2d' | grep -v "lo" | awk -F: '{print $1}' | sed -e 's/ //g' | wc -l) == 1 ]
then
	if [ "$(cat /proc/net/dev | sed '1,2d' | grep -v "lo" | awk -F: '{print $1}' | sed -e 's/ //g')" != "$Interface" ]
	then
		echo 找不到网口 $Interface
		Interface=$(cat /proc/net/dev | sed '1,2d' | grep -v "lo" | awk -F: '{print $1}' | sed -e 's/ //g')
		echo 网口已经自动设置为 $Interface
		sleep 1
	fi
elif [ $(cat /proc/net/dev | sed '1,2d' | grep -v "lo" | awk -F: '{print $1}' | sed -e 's/ //g' | grep -w "$Interface" | wc -l) == 0 ]
then
	echo 找不到网口 $Interface
	echo 当前可用网口如下
	cat /proc/net/dev | sed '1,2d' | grep -v "lo" | awk -F: '{print $1}' | sed -e 's/ //g'
	echo 请修改正确的网口
	exit
fi

while true
do
old=`cat /proc/net/dev | grep $Interface`
cpu_old=`cat /proc/stat | awk 'NR==1{print}'`
sleep $interval's'
new=`cat /proc/net/dev | grep $Interface`
cpu_new=`cat /proc/stat | awk 'NR==1{print}'`
receive_old=`echo $old | awk '{print $2}'`
transmit_old=`echo $old | awk '{print $10}'`
receive_new=`echo $new | awk '{print $2}'`
transmit_new=`echo $new | awk '{print $10}'`
loadavg=`uptime`
last1=`echo $loadavg | awk -F"average:" '{print $2}' | awk -F"," '{print $1}' | awk '{print $1}'`
last5=`echo $loadavg | awk -F"average:" '{print $2}' | awk -F"," '{print $2}' | awk '{print $1}'`
last15=`echo $loadavg | awk -F"average:" '{print $2}' | awk -F"," '{print $3}' | awk '{print $1}'`
runtime=`cat /proc/uptime | awk '{print $1}'`
days=`awk 'BEGIN{printf("%d",'$runtime' / 3600 / 24)}'`
hours=`awk 'BEGIN{printf("%d",('$runtime' - '$days' * 3600 * 24) / 3600)}'`
mins=`awk 'BEGIN{printf("%d",('$runtime' - '$days' * 3600 * 24 - '$hours' * 3600) / 60)}'`
seconds=`awk 'BEGIN{printf("%d",'$runtime' - '$days' * 3600 * 24 - '$hours' * 3600 - '$mins' * 60)}'`
receive=$[$receive_new-$receive_old]
transmit=$[$transmit_new-$transmit_old]
receive_speed=`awk 'BEGIN{printf("%.2f",('$receive_new' - '$receive_old') / 1024 / '$interval')}'`
transmit_speed=`awk 'BEGIN{printf("%.2f",('$transmit_new' - '$transmit_old') / 1024 / '$interval')}'`
receive_total=`awk 'BEGIN{printf("%.2f",'$receive_new' / 1024 / 1024 / 1024)}'`
transmit_total=`awk 'BEGIN{printf("%.2f",'$transmit_new' / 1024 / 1024 / 1024)}'`
cpu_old_total=`echo $cpu_old | awk '{printf "%.0f", $2+$3+$4+$5+$6+$7+$8+$9+$10+$11}'`
cpu_new_total=`echo $cpu_new | awk '{printf "%.0f", $2+$3+$4+$5+$6+$7+$8+$9+$10+$11}'`
cpu_usage=`awk 'BEGIN{printf("%.2f",('$(echo $cpu_new | awk '{printf "%.0f", $2+$3+$4}')' - '$(echo $cpu_old | awk '{printf "%.0f", $2+$3+$4}')') * 100 / ('$cpu_new_total' - '$cpu_old_total') / '$interval')}'`
if [ "$cpu_temp_support" != "error" ]
then
	cpu_temp=`awk 'BEGIN{printf("%.2f",'$(cat /sys/class/thermal/thermal_zone0/temp)' / 1000)}'`
fi
mem=`free | awk 'NR==2{print}'`
swap=`free | awk 'NR==3{print}'`
mem_total=`echo $mem | awk '{print $2}'`
mem_used=`echo $mem | awk '{print $3}'`
mem_free=`echo $mem | awk '{print $4}'`
mem_available=`echo $mem | awk '{print $7}'`
mem_usage=`awk 'BEGIN{printf("%.2f",'$mem_used' * 100 / '$mem_total')}'`
mem_total_space=`awk 'BEGIN{printf("%.2f",'$mem_total' / 1024)}'`
mem_used_space=`awk 'BEGIN{printf("%.2f",'$mem_used' / 1024)}'`
mem_free_space=`awk 'BEGIN{printf("%.2f",'$mem_free' / 1024)}'`
mem_available_space=`awk 'BEGIN{printf("%.2f",'$mem_available' / 1024)}'`
swap_total=`echo $swap | awk '{print $2}'`
swap_used=`echo $swap | awk '{print $3}'`
swap_free=`echo $swap | awk '{print $4}'`
swap_total_space=`awk 'BEGIN{printf("%.2f",'$swap_total' / 1024)}'`
swap_used_space=`awk 'BEGIN{printf("%.2f",'$swap_used' / 1024)}'`
swap_free_space=`awk 'BEGIN{printf("%.2f",'$swap_free' / 1024)}'`
disk_available=0
for i in `df | grep -wvE '\-|none|tmpfs|devtmpfs|by-uuid|chroot|udev|docker|storage' | awk '{print $4}' | awk 'NR!=1{print}'`
do
	disk_available=$[$disk_available+$i]
done
disk_used=0
for i in `df | grep -wvE '\-|none|tmpfs|devtmpfs|by-uuid|chroot|udev|docker|storage' | awk '{print $3}' | awk 'NR!=1{print}'`
do
	disk_used=$[$disk_used+$i]
done
disk_total=0
for i in `df | grep -wvE '\-|none|tmpfs|devtmpfs|by-uuid|chroot|udev|docker|storage' | awk '{print $2}' | awk 'NR!=1{print}'`
do
        disk_total=$[$disk_total+$i]
done
disk_usage=`awk 'BEGIN{printf("%.2f",'$disk_used' * 100 / '$disk_total')}'`
disk_available_space=`awk 'BEGIN{printf("%.2f",'$disk_available' / 1024 / 1024)}'`
disk_used_space=`awk 'BEGIN{printf("%.2f",'$disk_used' / 1024 / 1024)}'`
disk_total_space=`awk 'BEGIN{printf("%.2f",'$disk_total' / 1024 / 1024)}'`
if [ "$lastest_time_support" != "error" ]
then
	lastest_time=`date -u -d"+8 hour" +'%Y-%m-%d %H:%M:%S'`
else
	lastest_time=`date +'%Y-%m-%d %H:%M:%S'`
fi

clear
echo 运行时间: $days 天 $hours 时 $mins 分 $seconds 秒
echo 平均负载: $last1 $last5 $last15
echo CPU使用率: $cpu_usage %
echo CPU温度: $cpu_temp ºC
echo RAM总容量: $mem_total_space MB
echo RAM已用: $mem_used_space MB
echo RAM空闲: $mem_free_space MB
echo RAM可用: $mem_available_space MB
echo RAM使用率: $mem_usage %
echo SWAP总容量: $swap_total_space MB
echo SWAP已用: $swap_used_space MB
echo SWAP空闲: $swap_free_space MB
echo 磁盘总容量: $disk_total_space GB
echo 磁盘已用: $disk_used_space GB
echo 磁盘可用: $disk_available_space GB
echo 磁盘使用率: $disk_usage %
echo 接收速率: $receive_speed kB/s 发送速率: $transmit_speed kB/s
echo 累计接收: $receive_total GB 累计发送: $transmit_total GB
echo 更新时间: $lastest_time
cat>$server_name.json<<EOF
{
	"run_time":"$days 天 $hours 时 $mins 分 $seconds 秒",
	"last1":"$last1",
	"last5":"$last5",
	"last15":"$last15",
	"cpu_usage":"$cpu_usage",
	"cpu_temp":"$cpu_temp",
	"mem_total_space":"$mem_total_space",
	"mem_used_space":"$mem_used_space",
	"mem_free_space":"$mem_free_space",
	"mem_available_space":"$mem_available_space",
	"mem_usage":"$mem_usage",
	"swap_total_space":"$swap_total_space",
	"swap_used_space":"$swap_used_space",
	"swap_free_space":"$swap_free_space",
	"disk_total_space":"$disk_total_space",
	"disk_used_space":"$disk_used_space",
	"disk_available_space":"$disk_available_space",
	"disk_usage":"$disk_usage",
	"receive_speed":"$receive_speed",
	"transmit_speed":"$transmit_speed",
	"receive_total":"$receive_total",
	"transmit_total":"$transmit_total",
	"lastest_time":"$lastest_time"
}
EOF
#可以上传json到服务器做统一管理,示例 https://dash.baipiao.eu.org/
#curl https://example.com -F file=@$server_name.json
done
