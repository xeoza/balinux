#!/bin/bash
DEBUG=false

daemon_name="diskfree"

log_dir="/var/local/log/$daemon_name"
log_file="$log_dir/$daemon_name-"`date +"%Y-%m-%d"`".log"
out_file_dir="/var/local/$daemon_name"

pid_file="/tmp/monitor/$daemon_name.pid"
pid_dir="/tmp/monitor"

# Log maxsize in KB
log_max_size=1024   # 1 Mb

do_commands() {
    # This is where you put all the commands for the daemon.
    out_file="$daemon_name""_output_"`date +"%Y-%m-%d+%H:%M:%S"`

    df --output=source,fstype,itotal,iused,ipcent,size,used,pcent,target | awk 'NR == 1 || $1 ~ /^\/dev/ {print}' > "$out_file_dir/$out_file"

    filecount=`ls -1 $out_file_dir | grep "$daemon_name""_output_" | wc -l`
    if [ $filecount -gt 3 ]; then
        rm `ls -t $out_file_dir -d -1 $out_file_dir/{*,.*} | grep "$daemon_name""_output_" | tail -n +3`
    fi

    sleep 60 & sleep_pid=$! ; wait
}

# -----------------------------------------------------------------
# This part is for fun, if you consider shell scripts fun- and I do.
process_USR1() {
    echo 'Got signal USR1'
    echo 'Did you notice that the signal was acted upon only after the sleep was done'
    echo 'in the while loop? Interesting, yes? Yes.'
    exit 0
}
# End of fun. Now on to the business end of things.
# -----------------------------------------------------------------

process_term() {
    kill $sleep_pid
    echo "Exiting `cat $pid_file`...\n" > $log_file
    rm $pid_file
    exit 0
}

trap 'process_USR1' SIGUSR1
trap 'process_term' SIGTERM

print_debug() {
    whatiam="$1"; tty="$2"
    [[ "$tty" != "not a tty" ]] && {
        echo "" >$tty
        echo "$whatiam, PID $$" >$tty
        ps -o pid,sess,pgid -p $$ >$tty
        tty >$tty
    }
}

setup_daemon() {
        # Make sure that the directories work.
        if [ ! -d "$pid_dir" ]; then
                mkdir "$pid_dir"
        fi

        if [ ! -d "$log_dir" ]; then
                mkdir -p "$log_dir"
        fi

        if [ ! -d "$out_file_dir" ]; then
                mkdir "$out_file_dir"
        fi

        if [ ! -f "$log_file" ]; then
                touch "$log_file"
        else
                # Check to see if we need to rotate the logs.
                size=$((`ls -l "$log_file" | cut -d " " -f 5`/1024))
                if [[ $size -gt $log_max_size ]]; then
                        mv $log_file "$log_file.old"
                        touch "$log_file"
                fi
        fi
}

restart_daemon() {
    pid=`cat $pid_file`
    kill "-SIGTERM" $pid
    tty=$(tty)
    setsid $me_DIR/$me_FILE "--child" "$tty" "$@" &
    echo $! > $pid_file
}


me_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
me_FILE=$(basename $0)
cd /

setup_daemon

#### restarting daemon
if [ "$1" = "--restart" ] ; then
    restart_daemon

    exit 0
fi


#### CHILD HERE --------------------------------------------------------------------->
if [ "$1" = "--child" ] ; then   # 2. We are the child. We don't need to fork again.
    shift; tty="$1"; shift

    $DEBUG && print_debug "*** CHILD, NEW SESSION, NEW PGID" "$tty"
    umask 0

    $DEBUG && [[ "$tty" != "not a tty" ]] && echo "CHILD OUT" >$tt

    exec >/tmp/outfile
    exec 2>/tmp/errfile
    exec 0</dev/null

    shift; tty="$1"; shift

    $DEBUG && print_debug "*** DAEMON" "$tty"
                               # The real stuff goes here. To exit, see fun (above)
    $DEBUG && [[ "$tty" != "not a tty" ]]  && echo NOT A REAL DAEMON. NOT RUNNING WHILE LOOP. >$tty

    $DEBUG || {
        while true; do
            echo "Change this loop, so this silly no-op goes away." >/dev/null
            echo "Do something useful with your life, young man." >/dev/null
            do_commands
        done
    }

    exit 0
fi

##### ENTRY POINT HERE -------------------------------------------------------------->
if [ "$1" != "--forked" ] ; then # 1. This is where the original call starts.
    tty=$(tty)
    $DEBUG && print_debug "*** PARENT" "$tty"

    setsid $me_DIR/$me_FILE "--child" "$@" &

    if [ ! -d $pid_dir ] ; then
        mkdir $pid_dir
    fi
    echo $! > $pid_file

    $DEBUG && [[ "$tty" != "not a tty" ]] && echo "PARENT OUT" >$tty
    exit 0
fi
