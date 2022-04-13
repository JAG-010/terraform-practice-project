cat << EOF >> ~/.ssh/config

Host ${hostname}
    HostName ${hostname}
    User ${User}
    IdentityFile ${identityfile}
EOF    