#! /bin/bash

function format_for_sql {
	echo $1 | awk -F "|" '{out = "\""$1"\"";for(i=2;i<=NF;i++){out=out",\""$i"\""};print out}'
}

function add_value {
	sqlite3 ${1} "PRAGMA foreign_keys = ON;INSERT INTO ${2} VALUES (${3});"
}

function remove_last_char {
	echo $1 | sed 's/.\{1\}$//g'
}

db_name=$1
data=$2


wget_output=$(mktemp --tmpdir tab1.XXXXXXXX)



[[ ! -n $data ]] && exit 1

id=$(echo $data | cut -f4 -d"|")
value=$(echo $data | cut -f5- -d"|")
sql_value=$(format_for_sql $value)

rapp_file=$(echo $data | cut -f1 -d"|")
rapp_local=$(echo $data | cut -f2 -d"|")
rapp_dist=$(echo $data | cut -f3 -d"|")

[[ ${rapp_dist: -1} = "/" ]] && rapp_dist=$(remove_last_char ${rapp_dist})

wget -a ${wget_output} -N -v -P "${rapp_local}" "${rapp_dist}/${rapp_file}"

status=$(cat ${wget_output} | tail -5 | sed '/^$/d' | tail -1)

add_value ${db_name} "cron_task" "NULL,${sql_value},\"$(date)\",\"${status}\""

rm -f $wget_output
