#!/bin/bash

USERID=$(id -u)
R="\e[31m"
G="\e[32m"
N="\e[0m"
Y="\e[33m"
SCRIPT_NAME=$(echo $0 | cut -d "." -f1)
LOG_FOLDER="/var/log/roboshop-logs"
LOG_FILE="$LOG_FOLDER/$SCRIPT_NAME"
SCRIPT_DIR=$PWD

mkdir -p $LOG_FOLDER
echo "Script started executing at : $(date)" | tee -a $LOG_FILE

#Check if user has root access
if [ $USERID -ne 0]; then
    echo -e "$R ERROR:: Please run the command with sudo access $N"
    exit 1
else
    echo -e "You are running with root access"
fi

VALIDATE() {
    if [$1 -eq 0]; then
        echo -e "$2 is ..... $G SUCCESS $N" | tee -a $LOG_FILE
    else
        echo -e "$2 is ...... $R FAILURE $N" | tee -a $LOG_FILE
    fi
}

dnf module disable nodejs -y &>>$LOG_FILE
VALIDATE $? "Disabling node js default version"

dnf module enable nodejs:20 -y &>>$LOG_FILE
VALIDATE $? "Enabling nodejs version 20"

dnf install nodejs -y &>>$LOG_FILE
VALIDATE $? "Installing noder js version 20"

id roboshop
if[ $? -ne 0]
then 
    useradd --system --home /app --shell sbin/nologin --comment "Roboshop System User" roboshop
    VALIDATE $? "Creating System user Roboshop"

else
    echo "User already created... $Y $SKIPPING $N" | tee -a &LOG_FILE
fi


curl -L -o /tmp/cart.zip https://roboshop-artifacts.s3.amazonaws.com/cart-v3.zip &>>$LOG_FILE

mkdir -p /app
VALIDATE $? "Creating app directory"

cd /app

rm -rf /app/*  &>>$LOG_FILE
VALIDATE $? "Remove content from app directly"

upzip /tmp/cart.zip 
VALIDATE $? "Unzipping cart"

npm install &>>$LOG_FILE
VALIDATE $? "Installing node pacaking dependencies"

cp $SCRIPT_DIR/cart.service /etc/systemd/system/cart.service &>>$LOG_FILE
VALIDATE $? "Copy cart sevice info to systemd folder"

systemctl daemon-reload &>>$LOG_FILE
VALIDATE $? "Deamon-reload the changes in systemd folder"

systemctl enable cart
VALIDATE $? "Enabling cart"

systemctl start cart &>>$LOG_FILE
VALIDATE $? "Starting cart service"



