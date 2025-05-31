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

echo "Enter password to connect mysql"
read -p MYSQL_ROOT_PASSWORD

dnf install maven -y
VALIDATE $? "Installing maven and java"

id roboshop
if [ $? -ne 0 ]; then

    useradd --sytem --home /app --shell sbin/nologin --comment "Roboshop System User" roboshop
    VALIDATE $? "Creating Roboshop system user"
else
    echo -e "Rooboshop user already created .... $Y SKIPPING $N" | tee -a $LOG_FILE
fi

mkdir -p /app &>>$LOG_FILE
VALIDATE $? "Creating app directory"

curl -L -o /tmp/shipping.zip https://roboshop-artifacts.s3.amazonaws.com/shipping-v3.zip &>>$LOG_FILE
VALIDATE $? "Downloading shipping service"

cd /app

rm -rf /app/*
VALIDATE $? "Removing content from app directory"

unzip /tmp/shipping.zip &>>$LOG_FILE
VALIDATE $? "Unzipping Shipping service"

mvn clean package &>>$LOG_FILE
VALIDATE $? "Creating jar file - packaging the shipping application"

mv /target/shipping-1.0.jar shipping.jar &>>$LOG_FILE
VALIDATE $? "move and renaming shipping jar"

cp $SCRIPT_DIR/shipping.service /etc/systemd/system/shipping.service &>>$LOG_FILE
VALIDATE $? "Copying sipping service to system directory"

systemctl daemon-reload
VALIDATE $? "Daemon reload system directory"

systemctl enable shipping &>>$LOG_FILE
VALIDATE $? "Enable Shipping"

systemctl start shipping &>>$LOG_FILE
VALIDATE $? "Starting Shipping" &>>$LOG_FILE

dnf install mysql -y &>>$LOG_FILE
VALIDATE $? "Installing mysql client"

#Checking whether data already loaded or not in db
mysql -h mysql.devopspract.site -uroot -p$MYSQL_ROOT_PASSWORD -e 'use cities' &>>$LOG_FILE

if [ $? -ne 0 ]; then
    mysql -h mysql.devopspract.site -uroot -p$MYSQL_ROOT_PASSWORD </app/db/schema.sql &>>$LOG_FILE

    mysql -h mysql.devopspract.site -uroot -p$MYSQL_ROOT_PASSWORD </app/db/app-user.sql &>>$LOG_FILE

    mysql -h mysql.devopspract.site -uroot -p$MYSQL_ROOT_PASSWORD </app/db/master-data.sql &>>$LOG_FILE
    VALIDATE $? "Loading data into Mysql"

else
    echo -e "Data is already loaded into Mysql .... $Y SKIPPING $N"
fi

systemctl restart shipping &>>$LOG_FILE

VALIDATE $? "Restarting Shipping Service"

END_TIME=$(date +%s)
TOTAL_TIME = $(($END_TIME - $START_TIME))

echo "Script executed successfully, $Y time taken: $TOTAL_TIME seconds $N" | tee -a $LOG_FILE
