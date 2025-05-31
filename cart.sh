#!/bin/bash

USERID=$(id -u)
R="\e[31m"
G="\e[32m"
N="\e[0m"
Y="\e[33m"
SCRIPT_NAME=$(echo $0 | cut -d "." -f1)
LOG_FOLDER="/var/log/roboshop-logs"
LOG_FILE="$LOG_FOLDER/$SCRIPT_NAME.log"
SCRIPT_DIR=$PWD

mkdir -p $LOG_FOLDER
echo "Script started executing at : $(date)" | tee -a $LOG_FILE

#Check if user has root access
if [ $USERID -ne 0 ]
then
    echo -e "$R ERROR:: Please run the command with sudo access $N" | tee -a $LOG_FILE
    exit 1
else
    echo -e "$Y You are running with root access $N" | tee -a $LOG_FILE
fi

VALIDATE() {
    if [ $1 -eq 0 ]
    then
        echo -e "$2 is ..... $G SUCCESS $N" | tee -a $LOG_FILE
    else
        echo -e "$2 is ...... $R FAILURE $N" | tee -a $LOG_FILE
        exit 1
    fi
}

dnf module disable nodejs -y &>>$LOG_FILE
VALIDATE $? "Disabling node js default version"

dnf module enable nodejs:20 -y &>>$LOG_FILE
VALIDATE $? "Enabling nodejs version 20"

dnf install nodejs -y &>>$LOG_FILE
VALIDATE $? "Installing noder js version 20"

id roboshop
if [ $? -ne 0 ]
then 
    useradd --system --home /app --shell /sbin/nologin --comment "Roboshop System User" roboshop &>>$LOG_FILE
    VALIDATE $? "Creating System user Roboshop"

else
    echo -e "User already created... $Y $SKIPPING $N" | tee -a $LOG_FILE

fi

mkdir -p /app
VALIDATE $? "Creating app directory"

curl -o /tmp/cart.zip https://roboshop-artifacts.s3.amazonaws.com/cart-v3.zip &>>$LOG_FILE
VALIDATE $? "Dowloading cart service"

rm -rf /app/* &>>$LOG_FILE
VALIDATE $? "Remove content from app directly"

cd /app


unzip /tmp/cart.zip &>>$LOG_FILE
VALIDATE $? "Unzipping cart"

npm install &>>$LOG_FILE
VALIDATE $? "Installing node pacaking dependencies"

cp $SCRIPT_DIR/cart.service /etc/systemd/system/cart.service
VALIDATE $? "Copy cart sevice info to systemd folder"

systemctl daemon-reload &>>$LOG_FILE
VALIDATE $? "Deamon-reload the changes in systemd folder"

systemctl enable cart &>>$LOG_FILE
VALIDATE $? "Enabling cart"

systemctl start cart &>>$LOG_FILE
VALIDATE $? "Starting cart service"



