#!/bin/bash
START_TIME=$(date +%s) #date in seconds format
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

if [ USERID -ne 0 ]; then
    echo -e "$R ERROR ... please run the script with sudo access$N" | tee -a $LOG_FILE
    exit 1
else
    echo -e "$Y You are running with root access $N" | tee -a $LOG_FILE
fi

echo "Please enter mysql root password:"
read -s MYSQL_ROOT_PASSWORD

dnf install mysql-server -y &>>$LOG_FILE
VALIDATE $? "Installing mysql server"

systemctl enable mysqld &>>$LOG_FILE
VALIDATE $? "Enabling Mysql Server"

systemctl start mysqld &>>$LOG_FILE
VALIDATE $? "Starting mysql Server"

mysql_secure_installation --set-root-pass $MYSQL_ROOT_PASSWORD &>>$LOG_FILE
VALIDATE $? "Setting up mysql root password"

END_TIME=$(date +%s)

TOTAL_TIME=$(($END_TIME - $START_TIME))

echo -e "Script executed successfully, $Y time taken to execute $TOTAL_TIME seconds $N" | tee -a $LOG_FILE
