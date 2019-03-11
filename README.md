# iry.pl
Rsync based incremetal backups script

## Installation
You gonna need perl with its standard modules, Date::Format and rsync. No other dependencies.
Debian-based distros provide Date::Format with a 'libtimedate-perl' package.
Download the script via wget:
```
wget https://raw.githubusercontent.com/JaredSpb/iry.pl/master/iry.pl
```

## Usage
Here's a simple example to start a new backup:
```
./iry.pl --dest /media/backup/ rsync://backup_user@host.tld:873/module/*
```

You definetly should use ssh tunneling and an rsync password protection for security reasons.
For more details run:
```
./iry.pl --help
```
