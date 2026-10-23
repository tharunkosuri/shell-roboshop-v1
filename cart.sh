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
validate $? "Disabling Node.js module"

dnf module enable nodejs:24 -y &>> $logs_file
validate $? "Enabling Node.js 24 module"

dnf install nodejs -y &>> $logs_file
validate $? "Installing nodejs 24"

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

curl -L -o /tmp/cart.zip https://raw.githubusercontent.com/daws-92s/roboshop-documentation/refs/heads/main/artifacts/cart-v4.zip
validate $? "Downloading cart"

cd /app
unzip /tmp/cart.zip &>> $logs_file
validate $? "Unzipping User"

npm install &>> $logs_file
validate $? "Installing dependencies"

sed -i "s/DOMAIN_NAME/$domain_name/g" "$scripts_dir/cart.service"
cp "$scripts_dir/cart.service" /etc/systemd/system/cart.service

systemctl daemon-reload &>> $logs_file
systemctl enable cart &>> $logs_file
systemctl start cart &>> $logs_file
validate $? "enabling and starting cart"

systemctl restart cart
validate $? "Restarting cart"

echo "$(timestamp) [INFO] Script Completed in $SECONDS seconds" | tee -a $logs_file
echo "$(timestamp) [INFO] ====== Script Completed execution ======" | tee -a $logs_file