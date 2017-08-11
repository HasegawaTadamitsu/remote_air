#!/bin/sh

LOG_FILE=/tmp/remote_air.log
rm -rf $LOG_FILE

nohup ruby remote_air.rb 2>&1 |tee -a $LOG_FILE  

#passenger start -p 4567

