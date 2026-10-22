#!/bin/bash

user_id=$(id -u)
logs_folder="/var/log/roboshop"
logs_file="${logs_folder}/${0}.log"  # scriptname saved as logfile name
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

if [ $user_id -ne 0 ]; then
    echo "Please run the script with sudo access"
    exit 1
fi

mkdir -p $logs_folder  # If folder present then it will not create the folder.So we didnt get error

timestamp(){
    date +"%F %T"
}

validate(){
    if [ $1 -ne 0 ]; then
        echo -e "${timestamp} [ERROR] ${2}... is ${R}failed${N}" | tee -a $logs_file  # It will show in screen as well as in logs file
        exit 1
    else
         echo -e "${timestamp} [INFO] ${2}... is ${G}success${N}" | tee -a $logs_file # It will show in screen as well as in logs file
    fi

}

echo "${timestamp} [INFO] ====== Script started execution ======" | tee -a $logs_file

dnf module disable redis -y &>> $logs_file
dnf module enable redis:7 -y &>> $logs_file
dnf install redis -y &>> $logs_file
validate $? "Installing Redis" 

sed -i -e 's/127.0.0.1/0.0.0.0/g' -e 's/^protected-mode yes/protected-mode no/' /etc/redis/redis.conf
validate $? "Allowing remote connections from Redis" 

systemctl enable redis &>> $logs_file
systemctl start redis &>> $logs_file
validate $? "Enable and Starting Redis" 

echo "${timestamp} [INFO] Script Completed in $SECONDS seconds" | tee -a $logs_file
echo "${timestamp} [INFO] ====== Script Completed execution ======" | tee -a $logs_file