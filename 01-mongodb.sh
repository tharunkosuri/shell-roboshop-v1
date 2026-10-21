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

echo "Script started execution at $(date +"%F %T")" &>> $logs_file

validate(){
    if [ $1 -ne 0 ]; then
        echo -e "${2}... is ${R}failed${N}" | tee -a $logs_file  # It will show in screen as well as in logs file
        exit 1
    else
         echo -e "${2}... is ${G}success${N}" | tee -a $logs_file # It will show in screen as well as in logs file
    fi

}

cp mongo.repo /etc/yum.repos.d/mongo.repo
validate $? "Adding mongo repo"

dnf install mongodb-org -y &>> $logs_file
validate $? "Install mongodb"

systemctl enable mongod &>> $logs_file
systemctl start mongod &>> $logs_file
validate $? "enable and start mongodb"

sed -i 's/127.0.0.1/0.0.0.0/g' /etc/mongod.conf
validate $? "updating remote conections to mongodb"

systemctl restart mongod
validate $? "restarting mongodb"