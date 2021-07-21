#!/bin/bash
#charset=UTF-8
#Description: 检查服务器硬件信息;
#检查字符集
#localectl status|printf "字符集:$(grep "System Locale:"|awk '{print $3}') \n"
source /etc/init.d/functions

CPU_Check(){
  printf "#########查看CPU信息#########\n"
  printf "\n"
  #(1)处理器个数检查
  printf "检查处理器个数\n"
  CPU=/proc/cpuinfo
  CPU_Num=$(grep "physical id" ${CPU}|sort|uniq|wc -l)
  printf "处理器共${CPU_Num}颗\n"
  sleep 1

  #(2)处理器型号检查
  printf "检查处理器型号\n"
  CPU_Name=$(lscpu|egrep "Architecture\:|Model name:"|sed -e 's#Architecture#处理器架构#g' -e 's#Model name# 处理器型号#g')
  printf "${CPU_Name}\n"
  sleep 1

  #(3)处理器物理核数
  printf "检查处理器物理核数\n"
  printf "处理器核数$(grep "cpu cores" ${CPU}|uniq|sed 's#cpu cores##g')\n"
  sleep 1

  #(4)处理器逻辑核数
  printf "检查处理器逻辑核数\n"
  CPU_Logical=$(grep "siblings" ${CPU}|uniq|sed 's#siblings##g')
  printf "处理器逻辑个数${CPU_Logical}\n"
  sleep 1
  printf "\n"
}

Mem_Check(){
  printf "#########查看内存信息#########\n"
  printf "\n"
  #(1)查看服务器内存总大小
  Mem=$(grep MemTotal /proc/meminfo |awk '{print $2}')
  Mem_Total=$(echo "${Mem} / 1024 / 1024"|bc)
  printf "显示系统内存为${Mem_Total}GB，#此为当前系统可用，请手动转换! \n"
  sleep 1
  #服务器内存最大扩展容量
  Mem_Max_capacity=$(dmidecode -t memory|grep 'Maximum Capacity'|sed -ne 's#Maximum Capacity#最大内存扩展容量#gp')
  printf "${Mem_Max_capacity}\n"
  sleep 1

  #(2.0)查看服务器安装了内存数量以及详细信息
  Mem_Num=$(dmidecode -t memory|grep -i size|awk -F ":" '$NF !~ "No Module Installed"'|wc -l)
  printf "当前服务器安装了${Mem_Num}根内存\n"
  sleep 1

  #(2.1)单根内存大小、型号、频率
  Single_Mem_Total=$(echo "$(dmidecode -t memory|grep -i size |grep -v No|awk '{print $2}'|uniq)" / 1024 |bc)
  Single_Mem_Speed=$(dmidecode -t memory|grep Speed|grep -v Unknown|sort|uniq|sed -e 's#Speed#内存频率#g' -e 's#Configured Clock#主板锁频#g')
  Single_Mem_Sheet=$(dmidecode -t memory|grep "Part Number"|grep -v "Not Specified"|uniq|sed -n 's#Part Number#内存颗粒型号#gp')
  printf "单根内存大小为${Single_Mem_Total}G\n"
  printf "${Single_Mem_Speed}\n"
  printf "${Single_Mem_Sheet}\n"
  sleep 1

  #(3)查看服务器内存插槽数量
  Mem_Socket_Total=$(dmidecode -t memory|grep -i size|wc -l)
  printf "服务器的内存总插槽数为${Mem_Socket_Total}个\n"
  sleep 1
  printf "\n"
}

Disk_Check(){
  printf "#########查看硬盘信息#########\n"
  printf "\n"
  printf "查看服务器硬盘信息:\n"
  lsscsi -s|awk 'BEGIN {print "磁盘厂商"," ","磁盘型号","磁盘容量"}{print $3," ",$4," ",$NF}'
  printf "\n"
  sleep 1
  printf "\n"
}

Raid_Check(){
  printf "#########查看Raid卡信息#########\n"
  printf "\n"
  MCLI=/opt/MegaRAID/MegaCli/MegaCli64
  printf "查看服务器Raid卡信息:\n"
  sleep 1

  Raid_Name=$(lspci |grep -i lsi|awk -F ":" '{print $3}')
  printf "RAID卡型号:$Raid_Name\n"
  sleep 1

  #检查MegaCli64是否安装
  printf "检查MegaCli64是否安装\n"
  if [ ! -f $MCLI ]
  then
      action "MegaCli64 没有安装!" /bin/false
      printf "\n"
      printf "确保MegaCli64部署路径为:/opt/MegaRAID/MegaClix下，并赋予可执行权限\n"
      exit 1
  elif [ -x $MCLI ]
  then
      chmod u+x $MCLI
  fi
  sleep 1

  #检查MegaCli64是否
    Raid_soft=$(/opt/MegaRAID/MegaCli/MegaCli64  -AdpAllInfo -aALL|grep "^FW"|sed -ne 's#FW Package Build#驱动版本#gp' -e 's#FW Version#固件版本#gp')
    printf "${Raid_soft}\n"
    sleep 1
    printf "\n"
}

NIC_Check(){
  printf "#########查看网卡信息#########\n"
  printf "\n"
  #网卡信息
  printf "查看网卡型号\n"
  NIC_Info=$(lspci |grep Ethernet)
  printf "$NIC_Info\n"
  sleep 1

  #网口数量
  NIC_Count=$(lspci |grep Ethernet|wc -l)
  printf "网口数量为:$NIC_Count\n"
  sleep 1

  #网口信息
  Nic_Interface=$(ip link show|awk -F " " '{print $2}'|grep "^e"|awk -F ":" '{print $1}')
  for NIC in ${Nic_Interface}
  do
      Nic_soft=$(ethtool -i ${NIC}|egrep "^version|firmware-version")
      printf "${NIC}的驱动和固件的版本分别是\n${Nic_soft}\n"
      printf "\n"
  done
  sleep 1
  printf "\n"
}

menu(){
printf "请输入你要查看的硬件信息：\n"
cat << EOF
(1) 查看CPU信息

(2) 查看内存信息

(3) 查看磁盘信息

(4) 查看Raid卡信息

(5) 查看网卡信息

(6) 查看1-6所有硬件信息

(7) 退出
EOF
printf "\n"
read -p "(输入1-7): " num
printf "\n"

case $num in
  1) CPU_Check
     menu ;;
  2) Mem_Check
     menu;;
  3) Disk_Check
     menu;;
  4) Raid_Check
     menu;;
  5) NIC_Check
     menu;;
  6) CPU_Check
     Mem_Check
     Disk_Check
     Raid_Check
     NIC_Check
     menu;;
  7) exit 0 ;;
  *) clear;
     menu
esac
printf "\n"
}
menu



