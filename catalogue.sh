#!/bin/bash

USERID=$(id -u)
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"
LOG_FOLDER="/var/log/roboshop-logs"
SCRIPT_NAME=$(echo $0 | cut -d "." -f1)
LOG_FILE="$LOG_FOLDER/$SCRIPT_NAME.log"
SCRIPT_DIR=$PWD

#Create log folder directory before trying to store data into logs
mkdir -p $LOG_FOLDER
echo "Script started executing at : $(date)" | tee -a $LOG_FILE

#check if user has root access
if [ $USERID -ne 0 ]; then
    echo -e "$R ERROR: Please run the command with root access $N" | tee -a $LOG_FILE
    # as there is no root access, exit the process here
    exit 1
else
    echo -e "$Y You are running with root access $N" | tee -a $LOG_FILE
fi

VALIDATE() {
    if [ $1 -eq 0 ]; then
        echo -e "$2 is ...... $G SUCCESS $N" | tee -a $LOG_FILE
    else
        echo -e "$2 is ..... $R FAILURE $N" | tee -a $LOG_FILE
    fi
}

#till here, everything is normal process
#now the actual process which is related to mongodd will be created

#----------------- Actual script starts --------------

dnf module disable nodejs -y &>>$LOG_FILE
VALIDATE $? "Disable Default nodejs version"

dnf module enable nodejs:20 -y &>>LOG_FILE
VALIDATE $? "Enable node js 20 version"

dnf install nodejs -y &>>$LOG_FILE
VALIDATE $? "Install nodejs"

#we face issues-failures whenwe run this entire script from second time onwards, it is good to check roboshop already created or not
id roboshop
if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin --comment "Roboshop Sytem User" roboshop &>>$LOG_FILE
    VALIDATE $? "Creating Systemuser roboshop"
else
    echo -e "Systemuser Roboshop already created.. $Y SKIIPING creation $N"
fi

#mkdir -p /app - if not created, create now
mkdir -p /app
VALIDATE $? "Creating /app directory"

curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip &>>$LOG_FILE
VALIDATE $? "Downloading catalogue"

cd /app
#remove content in /app directory before unzipping unless it causes issues
rm -rf /app/*
VALIDATE $? "remove content from app directory"

unzip /tmp/catalogue.zip &>>$LOG_FILE
VALIDATE $? "unzipping catalogure service"

npm install &>>$LOG_FILE
VALIDATE $? "Installing npm packages-dependencies"

cp $SCRIPT_DIR/catalogue.service /etc/systemd/system/catalogue.service &>>$LOG_FILE

VALIDATE $? "Copying catalogue service to systemd folder"

systemctl daemon-reload &>>$LOG_FILE
VALIDATE $? "Loading after changes in systemd folder"

systemctl enable catalogue &>>$LOG_FILE
VALIDATE $? "Enabling Catalogue service"

systemctl start catalogue
VALIDATE $? "Starting Catalogue service"

#systemctl restart catalogue &>>$LOG_FILE
#VALIDATE $? "Restart Catalogue service"

cp $SCRIPT_DIR/mongodb.repo /etc/yum.repos.d/mongo.repo
VALIDATE $? "copy mongo db repo content..."

dnf install mongodb-mongosh -y &>>$LOG_FILE

VALIDATE $? "Installing mongo client"

#Load data only if catalogue db exists - it will us the index of catalogue db
STATUS=$(mongosh --host mongodb.devopspract.site --eval 'db.getMongo().getDBNames().indexOf("catalogue")')
#indices starts from 0
if [ $STATUS -lt 0 ]; then
    mongosh --host mongodb.devopspract.site </app/db/master-data.js &>>$LOG_FILE
    VALIDATE $? "Loading data into mongodb"
else
    echo -e "Data is already loaded...$Y SKIPPING $N"
fi
