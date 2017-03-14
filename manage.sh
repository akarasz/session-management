#!/bin/bash

call_on_scripts() {
    local COMMAND=$@

    SESSIONS_HOME=$HOME/.ssh/sessions
    SCRIPTS_HOME=$SESSIONS_HOME/scripts.d

    if [ -d $SCRIPTS_HOME ]; then
        for script in $(find $SCRIPTS_HOME -type f -name '*.sh' | sort); do
            $script $@
        done
    fi
}

call_on_scripts_reversed() {
    local COMMAND=$@

    SESSIONS_HOME=$HOME/.ssh/sessions
    SCRIPTS_HOME=$SESSIONS_HOME/scripts.d

    if [ -d $SCRIPTS_HOME ]; then
        for script in $(find $SCRIPTS_HOME -type f -name '*.sh' | sort -r); do
            $script $@
        done
    fi
}

stop() {
    local SESSION_PID="$1"

    # stop on every ssh session related script
    call_on_scripts_reversed stop $SESSION_PID

    # delete sessions workdir
    rm -rf $SESSIONS_HOME/$SESSION_PID
}

# TODO check if this is a new session

SESSIONS_HOME=$HOME/.ssh/sessions

REMOTE_IP=$(echo $SSH_CONNECTION | cut -d ' ' -f 1)
REMOTE_PORT=$(echo $SSH_CONNECTION | cut -d ' ' -f 2)
LOCAL_IP=$(echo $SSH_CONNECTION | cut -d ' ' -f 3)
LOCAL_PORT=$(echo $SSH_CONNECTION | cut -d ' ' -f 4)

# get pid of current sshd session
SESSION_PID=$(sudo netstat -tpn | sed -n "s%^.* $REMOTE_IP:$REMOTE_PORT.* \([0-9]\+\)/sshd.*$%\1%p")

[ -z "$SESSION_PID" ] && return 1 # abort if no pid found

# since this manage.sh was initiated from .bashrc (before tmux) when session stops this process
# will be hanged up. when this event comes the stop function will be called.
trap "stop $SESSION_PID" SIGHUP SIGINT SIGTERM

SESSION_HOME=$SESSIONS_HOME/$SESSION_PID
mkdir -p $SESSION_HOME
echo "$REMOTE_IP:$REMOTE_PORT" > $SESSION_HOME/remote
echo "$LOCAL_IP:$LOCAL_PORT" > $SESSION_HOME/local

# start on every ssh session related script
call_on_scripts start $SESSION_PID

# sleep, the trap will handle the rest
sleep infinity
