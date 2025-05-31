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
    echo -e "$R ERROR:: You are not running with root access $N" | tee -a $LOG_FILE
else
    echo -e "$Y You are running with root access $N" | tee -a $LOG_FILE
fi

VALIDATE() {
    if [ $1 -eq 0 ]; then
        echo -e "$2 is .... $G SUCCESS $N" | tee -a $LOG_FILE
    else
        echo -e "$2 is ..... $R FAILURE $N" | tee -a $LOG_FILE
    fi
}

dnf module disable nodejs -y &>>$LOG_FILE
VALIDATE $? "Disabling nodejs"

dnf module enable nodejs:20 -y &>>$LOG_FILE
VALIDATE $? "Enabling Nodejs 20"

dnf install nodejs -y &>>$LOG_FILE
VALIDATE $? "Installing nodejs version 20"

#check if user already created
id roboshop

if [ $? -ne 0 ]; then
    useradd --system --home /app --shell sbin/nologin --comment "Roboshop System User" roboshop
    VALIDATE $? "Creating System user Roboshop"
else
    echo -e "User roboshop already created... $Y SKIPPING $N"
fi

mkdir -p /app &>>$LOG_FILE
VALIDATE $? "Creating App directory"

curl -o /tmp/user.zip https://roboshop-artifacts.s3.amazonaws.com/user-v3.zip &>>$LOG_FILE
VALIDATE $? "Dowloading user service code to tmp/uzer.zip folder"

cd /app
rm -rf /app/*
VALIDATE $? "Removing content in App folder"

unzip /tmp/user.zip &>>$LOG_FILE
VALIDATE $? "Unzipping user service"

npm install &>>LOG_FILE
#vim /systemd/system/user.service
cp $SCRIPT_DIR/user.service /systemd/system/user.service &>>LOG_FILE
VALIDATE $? "Copying user service info to systemd folder"

systemctl daemon-reload &>>LOG_FILE
VALIDATE $? "Daemon reload- reloading systemd folder adter change"

systemctl enable user 
$VALIDATE $? "Enabling User Service"

systemctl start user &>>$LOG_FILE
VALIDATE $? "Disabling user service"


END_TIME=$(date +%s)
TOTAL_TIME=$(( $END_TIME-$START_TIME ))
echo "Script executed successfully, time taken: $Y $TOTAL_TIME seconds $N"