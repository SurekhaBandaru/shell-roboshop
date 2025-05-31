#!/bin/bash

START_TIME=$(date +%s)
USERID=$(id -u)
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

LOG_FOLDER="/var/log/roboshop-logs"
SCRIPT_NAME=$(echo $0 | cut -d "." -f1)
LOG_FILE="$LOG_FOLDER/$SCRIPT_NAME.log"
SCRIPT_DIR=$PWD

mkdir -p $LOG_FOLDER

echo "Script started executing at : $(date)" | tee -a $LOG_FILE

if [ $USERID -ne 0 ]; then
    echo -e "$R ERROR::Please run the script with root access $N" | tee -a $LOG_FILE
    exit 1
else
    echo -e "$Y You are running with root access $N" | tee -a $LOG_FILE
fi

VALIDATE() {
    if [ $1 -eq 0 ]; then
        echo -e "$2 is ..... $G SUCCESS $N" | tee -a $LOG_FILE
    else
        echo -e "$2 is ...... $R FAILURE $N" | tee -a $LOG_FILE
        exit 1
    fi
}

dnf install python3 gcc python3-devel -y &>>$LOG_FILE
VALIDATE $? "Installing python version 3 packages"

id roboshop
if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin --comment "Roboshop System User" roboshop &>>$LOG_FILE
    VALIDATE $? "Creating system user"
else
    echo -e "User already created...... $Y SKIPPING $N" | tee -a $LOG_FILE
fi

mkdir -p /app
VALIDATE $? "Creating app directory/folder"

curl -L -o /tmp/payment.zip https://roboshop-artifacts.s3.amazonaws.com/payment-v3.zip &>>$LOG_FILE
VALIDATE $? "Downloading payment service code"


rm -rf /app/*
VALIDATE $? "Removing content from app directory"
cd /app
unzip /tmp/payment.zip &>>$LOG_FILE
VALIDATE $? "Unzipping payment service code"

pip3 install -r requirements.txt &>>$LOG_FILE
VALIDATE $? "Installing python dependencies"

cp $SCRIPT_DIR/payment.service /etc/systemd/system/payment.service &>>$LOG_FILE
VALIDATE $? "Copying payment service info to system directory"

systemctl daemon-reload &>>$LOG_FILE
VALIDATE $? "deamon reload system directory changes"

systemctl enable payment &>>$LOG_FILE
VALIDATE $? "Enabling payment"

systemctl start payment &>>$LOG_FILE
VALIDATE $? "Starting payment"

END_TIME=$(date +%s)
TOTAL_TIME=$(($END_TIME - $START_TIME))

echo -e "Script executed successfully, time taken: $Y $TOTAL_TIME seconds $N" | tee -a $LOG_FILE
