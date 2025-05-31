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

dnf install golang -y
VALIDATE $? "Installing golang"

id roboshop
if [ $? -ne 0 ]
then
    useradd --system --home /app --shell /sbin/nologin --comment "Roboshop System User" roboshop
    VALIDATE $? "Creating system user roboshop"
else
    echo -e "Roboshop user alrad created... $Y SKIPPING $N" | tee -a $LOG_FILE
fi

mkdir -p /app

curl -L -o /tmp/dispatch.zip https://roboshop-artifacts.s3.amazonaws.com/dispatch-v3.zip &>>$LOG_FILE


#remove the content in app directot not /app
rm -rf /app/*
cd /app

unzip /tmp/dispatch.zip &>>$LOG_FILE
VALIDATE $? "Unzipping dispatch service"

got mod init dispatch &>>$LOG_FILE
go get &>>$LOG_FILE
VALIDATE $? "Installing dependencies"
go build &>>$LOG_FILE
VALIDATE $? "Build dispatch service"

cp $SCRIPT_DIR/dispatch.service /etc/systemd/system/dispatch.service &>>$LOG_FILE
VALIDATE $? "Copying dipatch service info to system directory"

systemctl daemon-reload &>>$LOG_FILE
VALIDATE $? "Deamon reload system directory"

systemctl enable dispatch &>>$LOG_FILE
VALIDATE $? "Enabling dispatch service"

systemctl start dispatch &>>$LOG_FILE
VALIDATE $? "Starting dispatch service"

END_TIME=$(date +%s)
TOTAL_TIME=$(( $END_TIME-$START_TIME))

echo -e "Script executed successfully, time taken: $Y $TOTAL_TIME seconds $N" | tee -a $LOG_FILE


