# iry.pl
Rsync based incremetal backups script

## Installation
You gonna need perl with its standard modules and rsync. No other dependencies.
Download the script via wget:
```
wget https://raw.githubusercontent.com/JaredSpb/iry.pl/master/iry.pl
```

## Usage
Here's a simple example to start a new backup:
```
./iry.pl --dest /media/backup/ rsycnc://backup_user@host.tld:873/module/*
```

You definetly should use ssh tunneling and an rsync password protection for security reasons.
For more details run:
```
./iry.pl --help
```
