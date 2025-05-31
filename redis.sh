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
    exit 1
else
    echo -e "$Y You are running with root access $N" | tee -a $LOG_FILE
fi

VALIDATE() {
    if [ $1 -eq 0 ]
    then
        echo -e "$2 is .... $G SUCCESS $N" | tee -a $LOG_FILE
    else
        echo -e "$2 is ..... $R FAILURE $N" | tee -a $LOG_FILE
    fi
}

#disable default version
dnf module disable redis -y &>>$LOG_FILE
VALIDATE $? "Disabling redis default version"

#enable default version
dnf module enable redis:7 -y &>>$LOG_FILE
VALIDATE $? "Enabling redis 7"

#install redis
dnf install redis -y &>>$LOG_FILE
VALIDATE $? "Installing redis 7"

#change 127.0.0.1 to internet accessible 0.0.0.0
#protectedmode to no
sed -i -e 's/127.0.0.1/0.0.0.0/g' -e '/protected-mode/ c protected-mode no' /etc/redis/redis.conf
VALIDATE $? "allow remote access and change protected mode to no"

systemctl enable redis &>>$LOG_FILE
VALIDATE $? "Enabling redis"

systemctl start redis &>>$LOG_FILE
VALIDATE $? "Starting redis"

# %s is to display date in seconds format
END_TIME=$(date +%s)
TOTAL_TIME=$(($END_TIME-$START_TIME))
echo -e "Script Execution completed successfully, $Y time taken: $TOTAL_TIME seconds $N" | tee -a $LOG_FILE