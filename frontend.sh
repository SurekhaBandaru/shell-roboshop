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

#Create log folder directory befire trying to store data into logs
#creates if not created earler
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

#create log directiry
#mkdir -p $LOG_FILE

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

dnf module disable nginx -y &>>$LOG_FILE
VALIDATE $? "Disabling current nginx version"

dnf module enable nginx:1.24 -y &>>$LOG_FILE
VALIDATE $? "Enabling required nginx version :1.24"

dnf install nginx -y &>>$LOG_FILE
VALIDATE $? "Installing Nginx"

systemctl enable nginx  &>>$LOG_FILE
#VALIDATE $? "Enabling Nginx"

#systemctl start nginx
#VALIDATE $? "Enabling and starting nginx"

rm -rf /usr/share/nginx/html/* &>>$LOG_FILE
VALIDATE $? "Removing defalut content"

curl -o /tmp/frontend.zip https://roboshop-artifacts.s3.amazonaws.com/frontend-v3.zip &>>$LOG_FILE
VALIDATE $? "Downloading frontend code"

cd /usr/share/nginx/html

unzip /tmp/frontend.zip &>>$LOG_FILE
VALIDATE $? "Unzipping frontend folder"

#Delete the defult content
rm -rf /etc/nginx/nginx.conf &>>$LOG_FILE
VALIDATE $? "Removing default content in nginx config file"

#copy the content stored in local file nginx.conf to nginx's config location, local file name can be anything.conf
cp $SCRIPT_DIR/nginx.conf /etc/nginx/nginx.conf
VALIDATE $? "Copying content into nginx conf"

systemctl start nginx 
VALIDATE $? "Restarting nginx"