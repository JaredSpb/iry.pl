#!/usr/bin/perl
use strict;
use feature qw|say|;
use Data::Dumper;
use Date::Format;
use Cwd 'abs_path';
use File::stat;


#----------------------------------------
# init
#----------------------------------------

my @sources;

my $conf = {
    '--dest' => undef,
    '--history-depth' => 14,
    '--log-level' => 1,
    '--log-to-term' => 1,
    '--log-to-file' => 0,
    '--password-file' => undef
};

# read args
for(my $i = 0; $i<= $#ARGV; $i++){
    help() if($ARGV[$i] eq '--help');

    if( exists($conf->{$ARGV[$i]}) ) {
	$conf->{$ARGV[$i]} = $ARGV[$i+1];
	$i++;
    } else {
	push(@sources,$ARGV[$i]);
    }
}

# check args
$conf->{'--dest'} = abs_path($conf->{'--dest'});
die "ERROR: Directory $conf->{'--dest'} does not exist" if(!-d $conf->{'--dest'});

$conf->{'--password-file'} = abs_path($conf->{'--password-file'});
if($conf->{'--password-file'}){
    die "ERROR: Password file must have 0600 permissions" unless( 
	sprintf("%04o", stat($conf->{'--password-file'})->mode & 07777) eq "0600" 
    );
}



die "ERROR: No sources defined" if($#sources == -1);

chdir $conf->{'--dest'};

my $tdir = time2str("%Y-%m-%d_%H:%M:%S", time);
my $log_file = ($conf->{'--log-to-file'} ? $tdir.'.log' : '/dev/null');



if($conf->{'--log-to-file'}){
    open LF,'>',$log_file;
}
echo("iry started at: ".localtime());
echo("Destination is: ".$conf->{'--dest'}.'/'.$tdir);
echo("Sources are: ".join(' ',@sources));

#----------------------------------------
# rotate dirs
#----------------------------------------
echo("Rotate dirs");
my @hd = reverse sort grep {-d} grep {/^\d{4}-\d{2}-\d{2}_\d{2}:\d{2}:\d{2}$/} glob('*');

foreach(@hd[$conf->{'--history-depth'}..$#hd]){
    echo("Remove dir: $_",2);
    `rm -rf $_`;
    if(-f $_.'.log'){
        `rm -rf $_.log`;
    }
}

#----------------------------------------
# copy latest dir
#----------------------------------------
echo("Create target dir: $tdir");
mkdir $tdir;

if($#hd != -1){
    echo("Link data from: $hd[0]");
    `cp --preserve=all -Plr $hd[0]/* $tdir`;
}

#----------------------------------------
# rsync
#----------------------------------------
my $rs_cmd = "rsync -a --numeric-ids --delete".( $conf->{'--password-file'} ? " --password-file $conf->{'--password-file'}" : '');
my $rs_cmd_suffix = ' 2>&1';

if($conf->{'--log-level'} == 1){
    $rs_cmd .= ' -v -i' ;
} elsif($conf->{'--log-level'} == 2) {
    $rs_cmd .= ' -v -v -i';
} else {
    $rs_cmd .= ' -q';
}

$rs_cmd .= ' '.join(" ",@sources);
$rs_cmd .= ' '.$conf->{'--dest'}.'/'.$tdir;

$rs_cmd = $rs_cmd.$rs_cmd_suffix;

echo("RSyncing");
echo("rsync cmd is '$rs_cmd'");

open my $rsc, $rs_cmd." |";
while(<$rsc>){
    echo($_);
}

sub echo {
    my $str = shift;
    chomp($str);
    my $level = shift || 1;

    return if($conf->{'--log-level'} < $level);

    if($conf->{'--log-to-file'})
    {
	say LF $str;
    }
    if($conf->{'--log-to-term'})
    {
	say $str;
    }
}

sub help{
say q|
iry.pl - Iterated Rsync
This script is used to make incremetal backups, saving old iteration results.
Usage:
iry.pl OPTIONS SRC [SRC]

Otions are:

    --dest DIR                Destination directory. Required.

    --password-file FILE      File containing password for remote rsync daemon. This file must have 0600 permissions.

    --history-depth NUM       Keep these number of results of previous script runs. Defaults to 14.

    --log-level NUM           Log level from 0 (log nothing) to 2 (log almost all we can). Defaults to 1.

    --log-to-term NUM         1 - print log to terminal (default), 0 - do not log to terminal.

    --log-to-file NUM         same as previous option but applies to log file. Defaults to 0.

    --help                    Show this message and exit.


Each option (except of --help) must be followed by its value. All other arguments are treated as source.


iry.pl creates a directory named after current date-time (YYYY-MM-DD_HH:MM:SS) in the destination dir.
Then it copies files from the previous backup using hardlinking. Then old backup directories are
removed (see --history-depth option above). And at last rsync from all the sources to that dir is run.

Logging can be performed both to terminal and log file as requsted by user. log file is stored in
destination dir and named after current date-time (YYYYMMDD-HHMMSS.log).

Examples:

     iry.pl --dest /media/backup/critical_data_history --history-depth 30 --log-level 2 --log-to-file 1 /home/user/critical_data

     iry.pl --dest /home/backups --log-to-term 0 --log-to-file 1 rsync://backup_user@example.com/module/*

Note that rsyncing from remote rsync daemon is not encrypted. It is usefull create ssh tunnel before you run iry.pl.
This example asumes you have ssh configured to use key-based auth:

     # create encrypted managed connection
     ssh -M -S ~/.ssh/backup_connection -Nf -L 127.1:3333:127.1:873 user@example.com
     # backup the files
     iry.pl --dest /home/backups --log-to-term 0 --log-to-file 1 rsync://backup_user@localhost:3333/module/*
     # close created connection
     ssh -S ~/.ssh/backup_connection -O exit user@example.com
|;
exit;
}
