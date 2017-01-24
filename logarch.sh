#!/bin/bash
host=$1
log_dir=/var/log
backup_dir=/root/backup/log/$host

nginx_src_dir=$log_dir/nginx
nginx_dst_dir=$backup_dir/nginx

apache_src_dir=$log_dir/apache2
apache_dst_dir=$backup_dir/apache2

httpd_src_dir=/var/log/httpd-logs
httpd_dst_dir=$backup_dir/httpd-logs

isp_src_dir=/var/www

exim_src_dir=$log_dir/exim4
exim_dst_dir=$backup_dir/exim4

kernel_dst_dir=$backup_dir/kernel
syslog_dst_dir=$backup_dir/syslog
auth_dst_dir=$backup_dir/auth
tmplist=/tmp/tmp.lst
isplist=/tmp/isp.lst
loglist=/tmp/log.lst

#find $nginx_dir -name error.*.gz  > $tmplist
function month2num ()
        {
        sed 's/Jan/01/' | sed 's/Feb/02/' | sed 's/Mar/03/' | sed 's/Apr/04/' |                                           sed 's/May/05/' | sed 's/Jun/06/' | sed 's/Jul/07/' | sed 's/Aug/08/' | sed 's/S                                          ep/09/' | sed 's/Oct/10/' | sed 's/Nov/11/' | sed 's/Dec/12/'
        }

function system_format ()
        {
        year=`echo $date_  | awk '{print $4}'`
        month=`echo $date_ | awk '{print $1}' | month2num`
        day=`echo $date_   | awk '{print $2}'`
        clock=`echo $date_ | awk '{print $3}' | head -q -c 5`
        }

function access_format ()
        {
        year=`echo $date_  | awk '{print $3}'`
        month=`echo $date_ | awk '{print $2}' | month2num`
        day=`echo $date_   | awk '{print $1}'`
        clock=`echo $date_ | awk '{print $4}'`
        }

function nginx_access ()
        {
#        start_date=`zcat $1 | head -n 1 | sed -e 's/^.*\[//' | head -q -c 17 |                                            month2num | sed 's/\//-/g' | sed 's/\ /-/'`
#        stop_date=`zcat $1 | tail -n 1 | sed -e 's/^.*\[//' | head -q -c 17 |                                            month2num | sed 's/\//-/g' | sed 's/\ /-/'`
        date_=`zcat $1 | head -n 1 | sed -e 's/^.*\[//' | head -q -c 17 |  month                                          2num | sed 's/\//\ /g' | sed 's/:/\ /'`
        access_format
        start_date=$year'_'$month'_'$day'_'$clock
        date_=`zcat $1 | tail -n 1 | sed -e 's/^.*\[//' | head -q -c 17 |  month                                          2num | sed 's/\//\ /g' | sed 's/:/\ /'`
        access_format
        stop_date=$year'_'$month'_'$day'_'$clock
        }

function nginx_error ()
        {
        start_date=`zcat $1  | head -n 1 | head -q -c 16 | sed 's/\//_/g' | sed                                           's/\ /_/'`
        stop_date=`zcat $1  | tail -n 1 | head -q -c 16 | sed 's/\//_/g' | sed '                                          s/\ /_/'`
        }

function apache_access ()
        {
        #24 Oct 2014 06:56
        date_=`zcat $1 | head -n 1 | sed -e 's/^.*\[//' | head -q -c 17 |  month                                          2num | sed 's/\//\ /g' | sed 's/:/\ /'`
        access_format
        start_date=$year'_'$month'_'$day'_'$clock
        date_=`zcat $1 | tail -n 1 | sed -e 's/^.*\[//' | head -q -c 17 |  month                                          2num | sed 's/\//\ /g' | sed 's/:/\ /'`
        access_format
        stop_date=$year'_'$month'_'$day'_'$clock
        }

function apache_error ()
        {
        #Fri Oct 24 06:56:26 2014
        date_=`zcat $1 | head -n 1 | sed -e 's/\[//' | head -q -c 24 | tail -q -                                          c 20`
        system_format
        start_date=$year'_'$month'_'$day'_'$clock
        date_=`zcat $1 | tail -n 1 | sed -e 's/\[//' | head -q -c 24 | tail -q -                                          c 20`
        system_format
        stop_date=$year'_'$month'_'$day'_'$clock
        }

function exim ()
        {
        start_date=`zcat $1 | head -n 1 | head -q -c 16 | sed -e 's/-/_/g' | sed                                           's/\ /_/'`
        stop_date=`zcat $1 | tail -n 1 | head -q -c 16 | sed -e 's/-/_/g' | sed                                           's/\ /_/'`
        }

function sys_log ()
        {
        date_=`zcat $1 | head -n 1 | head -q -c 20`
        system_format
        year=`stat $1 -c %x | head -q -c 4`
        start_date=$year'_'$month'_'$day'_'$clock
        date_=`zcat $1 | tail -n 1 | head -q -c 20`
        system_format
        year=`stat $1 -c %x | head -q -c 4`
        stop_date=$year'_'$month'_'$day'_'$clock
        }


function fpm ()
        {
        start_date=`zcat $1 | grep -v ^PHP | grep -v ^$ | head -n 1 | head -q -c                                           16 | sed -e 's/\//_/g' | sed 's/\ /_/'`
        stop_date=`zcat $1  | grep -v ^PHP | grep -v ^$ | tail -n 1 | head -q -c                                           16 | sed -e 's/\//_/g' | sed 's/\ /_/'`
        }


function rename_logfile () # $src_dir  $dst_dir  $logtype  $logname
        {
#       $src_dir=$1
#       $dst_dir=$2
#       $logtype=$3
        if [ "$3" = "isp" ]; then
                ls -l /var/www/ | grep ^d | awk '{print $9}' | grep -v httpd-cer                                          t | grep -v httpd-logs | grep -v nginx-logs | grep -v default | grep -v h0 | gre                                          p -v nadegda-sm > $loglist
                               while read line
                               do
                                        ls -1 /var/www/$line/data/logs  | grep a                                          ccess | grep gz$   > $isplist
                                        while read log
                                        do
                                                filename=/var/www/$line/data/log                                          s/$log
                                                apache_access $filename
                                                name=`echo $filename | sed  -e "                                          s/\.log.*.gz$/log.$start_date-$stop_date.gz/" | sed -e 's/accesslog/access.log/'                                           | awk -F/ '{print $7}'`
                                                echo $2/$name
                                                echo $filename
                                                cp $filename $2/$name
                                                rm $filename
                                        done < $isplist

                                        ls -1 /var/www/$line/data/logs  | grep e                                          rror | grep gz$   > $isplist
                                        while read log
                                        do
                                                filename=/var/www/$line/data/log                                          s/$log
                                                apache_error $filename
                                                name=`echo $filename | sed  -e "                                          s/\.log.*.gz$/log.$start_date-$stop_date.gz/" | sed -e 's/errorlog/error.log/' |                                           awk -F/ '{print $7}'`
                                                echo $2/$name
                                                echo $filename
                                                cp $filename $2/$name
                                                rm $filename
                                        done < $isplist
                               done < $loglist

        else
        ls -1 $1  | grep $4.*.gz  > $tmplist
        while read line
        do
                src_dir=$1
                dst_dir=$2
                logtype=$3
                logname=$4
                filename=$src_dir/$line

                case $logtype in

                        nginx)
                                if [ "$logname" = "access" ]; then
                                #       echo 'nginx_access'
                                        nginx_access $filename
                                else
                                #       echo 'nginx_error'
                                        nginx_error $filename
                                fi
                                ;;

                        apache)
                                if [ "$logname" = "access" ]; then
                                #       echo 'apache_access'
                                        apache_access $filename
                                else
                                #       echo 'apache_error'
                                        apache_error $filename
                                fi
                                ;;

                        exim)
                                exim $filename
                                ;;
                        fpm)
                                fpm $filename
                                ;;

                        httpd)
                                if [ "$logname" = "access" ]; then
                                        apache_access $filename
                                else
                                        apache_error $filename
                                fi
                                ;;
                        *)
#                               echo 'syslog'
                                sys_log $filename
                                ;;
                esac
                #echo $start_date
                #echo $stop_date
                name=`echo $line | sed  -e "s/log.*.gz/log.$start_date-$stop_dat                                          e.gz/"`
                echo $name

        cp $filename $dst_dir/$name && rm $filename
        echo $filename
        done < $tmplist
        fi
        }
#rename_logfile $isp_src_dir $httpd_dst_dir  isp

rename_logfile $httpd_src_dir $httpd_dst_dir  httpd access
rename_logfile $httpd_src_dir $httpd_dst_dir  fpm error
rename_logfile $apache_src_dir $apache_dst_dir apache access
rename_logfile $apache_src_dir $apache_dst_dir apache error
rename_logfile $nginx_src_dir $nginx_dst_dir nginx access
rename_logfile $nginx_src_dir $nginx_dst_dir nginx error
rename_logfile $exim_src_dir $exim_dst_dir exim mainlog
rename_logfile $log_dir $syslog_dst_dir syslog syslog
rename_logfile $log_dir $auth_dst_dir auth auth
rename_logfile $log_dir $kernel_dst_dir kern kern
exit 0
