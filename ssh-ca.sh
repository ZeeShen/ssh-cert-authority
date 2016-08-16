# !/bin/bash -e

SSH_AUTH_SOCK=/tmp/ssh-ca-agent/agent.socket
SSH_CA_SERVER_PORT=8081
HOME=/root

pid=`ps -ef | grep "ssh-cert-authority" | grep -v "grep" | awk '{print $2}'`
log="/var/log/ssh-cert-authority.log"

case "$1" in
start)
    if [ ! -z $pid ]; then
        echo "ssh-cert-authority is running, pid $pid"
        exit
    fi
    ssh_agent=`ps -ef | grep "ssh-agent" | grep "$SSH_AUTH_SOCK" | grep -v "grep"`
    if [ -z "${ssh_agent}" ]; then
        echo "[Warning] No ssh-agent running at socket $SSH_AUTH_SOCK. Start now"
        ssh-agent -a /tmp/ssh-ca-agent/agent.socket
        ssh-add "~/.ssh_ca/staging-ssh-ca"
    fi
    export SSH_AUTH_SOCK
    export SSH_CA_SERVER_PORT
    export HOME
    ssh-cert-authority runserver >> $log 2>&1 &
    echo "start ssh-cert-authority $!: done"
    # todo: rotate log
    ;;
stop)    
    if [ ! -z $pid ]; then
        kill -9 "${pid}"
        echo "stop ssh-cert-authority ${pid}: done"
    else 
        echo "ssh-cert-authority is not running"
    fi
    ;;
reload)
    if [ -z $pid ]; then
        echo "ssh-cert-authority is not running"
        exit
    fi
    curl -s -XPOST "http://localhost:${SSH_CA_SERVER_PORT}/admin/reload?config_path=%2Froot%2F.ssh_ca%2Fsign_certd_config.json"
    ;;
status)
    if [ ! -z $pid ]; then
        echo "ssh-cert-authority is running, pid $pid"
    else 
        echo "ssh-cert-authority is not running"
    fi
    ;;

*)
    echo "Usage: $0 {start|stop|status|reload}"
esac