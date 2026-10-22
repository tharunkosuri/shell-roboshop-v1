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

cp rabbitmq.repo /etc/yum.repos.d/rabbitmq.repo
validate $? "Adding rabbitmq.repo"

dnf install erlang rabbitmq-server -y &>> $logs_file
validate $? "Installing rabbitmq server"

systemctl enable rabbitmq-server &>> $logs_file
systemctl start rabbitmq-server &>> $logs_file
validate $? "Enable and Starting RabbitMQ server"

sudo rabbitmqctl list_users | grep -qw "roboshop"
if [ $? -ne 0 ]; then
    rabbitmqctl add_user roboshop roboshop123 &>> $logs_file
    validate $? "Creating RabbitMQ user for Roboshop"
else
    echo "${timestamp} [INFO] RabbitMQ user already exists...${Y}SKIPING${N}"
fi

rabbitmqctl set_permissions -p / roboshop ".*" ".*" ".*" &>> $logs_file
validate $? "Setting permissions for RabbitMQ user for Roboshop"

echo "${timestamp} [INFO] Script Completed in $SECONDS seconds" | tee -a $logs_file
echo "${timestamp} [INFO] ====== Script Completed execution ======" | tee -a $logs_file
