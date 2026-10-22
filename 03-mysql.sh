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

dnf module enable mysql:8.4 -y &>> $logs_file
dnf install mysql-server -y &>> $logs_file
validate $? "Installing mysql server"

systemctl enable mysqld &>> $logs_file
systemctl start mysqld &>> $logs_file
validate $? "Enabling and Starting mysql server"

mysql_secure_installation --set-root-pass RoboShop@1 &>> $logs_file
validate $? "Setup mysql root password"

echo "${timestamp} [INFO] Script Completed in $SECONDS seconds" | tee -a $logs_file
echo "${timestamp} [INFO] ====== Script Completed execution ======" | tee -a $logs_file

