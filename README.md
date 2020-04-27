# sysadmin-scripts

Small, commented Bash scripts for everyday Linux support and administration. No exotic dependencies: only tools that ship with pretty much any distribution.

| Script | What it does |
| --- | --- |
| [`sysinfo.sh`](sysinfo.sh) | One-screen summary of a box (OS, CPU, memory, disks, network), ready to paste into a ticket. |
| [`diskusage.sh`](diskusage.sh) | What is filling up the disk, and how to free some space. |
| [`backup.sh`](backup.sh) | Incremental `rsync` snapshots: every snapshot looks complete but only stores what changed. |
| [`netdiag.sh`](netdiag.sh) | "The Internet is down" checklist, layer by layer: interface, IP, gateway, Internet, DNS. Tells you where it breaks. |
| [`check-services.sh`](check-services.sh) | Checks that services are running (systemd or SysV). Can restart them. |

## Usage

```bash
git clone https://github.com/kcurtet/sysadmin-scripts.git
cd sysadmin-scripts
chmod +x *.sh

./sysinfo.sh > "$(hostname)-info.txt"
./diskusage.sh / 15
./backup.sh /home/kevin/docs /mnt/backup/docs 7
./netdiag.sh
./check-services.sh sshd nginx
```

## Requirements

Bash 4+, `iproute2`, `iputils` (ping) and `rsync` for backups. Tested on Ubuntu 18.04 and CentOS 7.

## License

MIT
