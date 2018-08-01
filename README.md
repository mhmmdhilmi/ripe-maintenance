# RIPE GSM Maintenance

Script for maintenance modem and route on GSM RIPE devices


## Prerequisites

* RIPE GSM device
* Telegram bot

## Qiuck Start

All of the script use Bash shell

### Installing


```
$ git clone https://github.com/mhmmdhilmi/ripe-maintenance.git
$ sudo chmod +x -R ripe-maintenance
```

before run the script you need to change token and chat id from your own bot, now run the script

```
$ ./maintenance.sh
```

## Running the tests

this script can be run periodicly by set the job with crontab. My system runs this script every one hour everyday

