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

if [ USERID -ne 0 ]; then
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

echo "Please enter rabbitmq password to set up"
read -p RABBITMQ_PASSWORD

cp $SCRIPT_DIR/rabbitmq.repo /etc/yum.repos.d/rabbitmq.repo &>>$LOG_FILE
VALIDATE $? "Copying rabbit mq repo"

dnf install rabbitmq-server -y &>>$LOG_FILE
VALIDATE $? "Installing rabbit mq server"

systemctl enable rabbitmq-server &>>$LOG_FILE
VALIDATE $? "Enabling RabbitMq server"

systemctl start rabbitmq-server &>>$LOG_FILE
VALIDATE $? "Starting RabbitMq server"

# RabbitMQ comes up with default username/password guest/guest but using this we connect to rabbitmq, we need to create one user for application

rabbitmqctl add_user roboshop $RABBITMQ_PASSWORD
VALIDATE $? "Creating new user for rabbit mq server"

rabbitmqctl set_permissions -p / roboshop ".*" ".*" ".*"
VALIDATE $? "Set rabbitmq user permissions"

#systemctl restart rabbitmq-server
#VALIDATE $? "Restarting Rabbit mq server"

END_TIME=$(date +%s)
TOTAL_TIME=$(( $END_TIME-$START_TIME ))

echo -e "Script executed successfully in $Y $TOTAL_TIME seconds $N"





