[Unit]
Description=Repair orphaned passwd/group shadow database entries
DefaultDependencies=no
After=local-fs.target
Before=systemd-sysusers.service

[Service]
Type=oneshot
ExecStart=/usr/libexec/repair-accounts.sh
RemainAfterExit=yes

[Install]
WantedBy=sysinit.target
