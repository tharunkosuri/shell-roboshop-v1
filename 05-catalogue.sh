#!/bin/bash

user_id=$(id -u)
logs_folder="/var/log/roboshop"
logs_file="${logs_folder}/${0}.log"  # scriptname saved as logfile name
domain_name="tharundevops.store"
scripts_dir=$(dirname "$(realpath "$0")") # $0 represents script name So, realpath $0 represents full path of script name
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
        echo -e "$(timestamp) [ERROR] ${2}... is ${R}failed${N}" | tee -a $logs_file  # It will show in screen as well as in logs file
        exit 1
    else
         echo -e "$(timestamp) [INFO] ${2}... is ${G}success${N}" | tee -a $logs_file # It will show in screen as well as in logs file
    fi

}

echo "$(timestamp) [INFO] ====== Script started execution ======" | tee -a $logs_file

dnf module disable nodejs -y &>> $logs_file
dnf module enable nodejs:24 -y &>> $logs_file
dnf install nodejs -y &>> $logs_file
validate $? "Instaling Nodejs 24"

id roboshop &>> $logs_file
if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>> $logs_file
    validate $? "Creating the system user for Nodejs"
else 
    echo -e "$(timestamp) [INFO] System user Roboshop already exixt.. ${Y}SKIPPING${N}"
fi

rm -rf /app
validate $? "Removing old code"

mkdir -p /app &>> $logs_file
validate $? "Creating app directory"

curl -L -o /tmp/catalogue.zip https://raw.githubusercontent.com/daws-92s/roboshop-documentation/refs/heads/main/artifacts/catalogue-v4.zip &>> $logs_file
validate $? "Downloading Catalogue"

cd /app
unzip /tmp/catalogue.zip &>> $logs_file
validate $? "Unzipping Catalogue"

npm install &>> $logs_file
validate $? "Installing dependencies"

sed -i "s/DOMAIN_NAME/$domain_name/g" "$scripts_dir/catalogue.service"
cp "$scripts_dir/catalogue.service" /etc/systemd/system/catalogue.service

systemctl daemon-reload &>> $logs_file
systemctl enable catalogue &>> $logs_file
systemctl start catalogue &>> $logs_file
validate $? "enabling and starting catalogue"

cp "$scripts_dir/catalogue.service" /etc/yum.repos.d/mongo.repo
validate $? "validate mongo.repo"

dnf install mongodb-mongosh -y &>> $logs_file
validate $? "Installing MongoDB Client"

product_count=$(mongosh --host mongodb.${domain_name} --quiet --eval 'db.getSiblingDB("catalogue").products.countDocuments()')
validate $? "Connecting to MongoDB"

if [ ${product_count} -eq 0 ]; then
    mongosh --host "mongodb.${domain_name}" </app/db/master-data.js
    validate $? "Loading Products"
else 
    echo "$(timestamp) [INFO] Products are already loaded.. ${Y}SKIPPING${N}"
fi

systemctl restart catalogue &>> $logs_file
validate $? "Restarting Catalogue"

echo "$(timestamp) [INFO] Script Completed in $SECONDS seconds" | tee -a $logs_file
echo "$(timestamp) [INFO] ====== Script Completed execution ======" | tee -a $logs_file

