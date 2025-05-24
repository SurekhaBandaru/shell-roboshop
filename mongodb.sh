#!/bin/bash

USERID=$(id -u)
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"
LOG_FOLDER="/var/log/roboshopshellscript-logs"
SCRIPT_NAME=$(echo $0 | cut -d "." -f1)
LOG_FILE="$LOG_FOLDER/$SCRIPT_NAME.log"
SCRIPT_DIR=$PWD

#Create log folder directory befire trying to store data into logs
#creates if not created earler
mkdir -p $LOG_FOLDER
echo "Script started executing at : $(date)" | tee -a $LOG_FILE

#check if user has root access
if [ $USERID -ne 0]; then
    echo -e "$R ERROR: Please run the command with root access $N" | tee -a $LOG_FILE
    # as there is no root access, exit the process here
    exit 1
else
    echo -e "$N You are running with root access $N" | tee -a $LOG_FILE
fi

#create log directiry
mkdir $LOG_FILE

VALIDATE() {
    if [ $1 -eq 0 ]; then
        echo -e "$2 is ...... $G SUCCESS $N" | tee -a $LOG_FILE
    else
        echo -e "$2 is ..... $R FAILURE $N" | tee -a $LOG_FILE
    fi
}

#till here, everything is normal process
#now the actual process which is related to mongodb will be created

#----------------- Actual script starts --------------

#create a repo file and paste the repo info there eg: mongodb.repo - can be any readable name
# copy the info of mongodb.repo to below location
cp $SCRIPT_DIR/mongodb.repo /etc/yum.repos.d/mongo.repo

VALIDATE $? "copying mongodb repo"
#install mongo db
dnf install mongodb-org -y &>>$LOG_FILE
VALIDATE $? "Installing mongo db server"

#by default mongodb is locally accessible, so we need to change that 127.0.0.1 to internet access 0.0.0.0 at
#/etc/mongod.conf

#enable mongodb
systemctl enable mongod &>>$LOG_FILE

VALIDATE $? "Enabling mongodb" 

#start mongodb
systemctl start mongod &>>$LOG_FILE
VALIDATE $? "Starting mongodb" 

#s -- substiture
#replace (g indicates replace) 127.0.0.1 with 0.0.0.0 at /etc/mongod.conf
sed -i 's/127.0.0.1/0.0.0.0/g' /etc/mongod.conf
# $? previously (last) executed command status
VALIDATE $? "Editing mongo db conf file for remote connection"

systemctl restart mongod &>>$LOG_FILE
VALIDATE $? "Restarting mongodb"

