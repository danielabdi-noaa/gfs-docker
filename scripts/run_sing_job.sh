#!/bin/bash

IPC_FILE=$HOME/.servinp
OUT_FILE=$HOME/.output.log

rm -rf $IPC_FILE $OUT_FILE
touch $IPC_FILE

#read and execute commands
tail -f $IPC_FILE 2>/dev/null |
while read line; do
   cat /dev/null >$OUT_FILE
   bash -c "$line" &>$OUT_FILE
   echo $? &>>$OUT_FILE
   cat /dev/null >$IPC_FILE
done &
