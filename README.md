# sysadmin-scripts

Small, commented Bash scripts for everyday Linux support and administration. No exotic dependencies: only tools that ship with pretty much any distribution.

| Script | What it does |
| --- | --- |
| [`sysinfo.sh`](sysinfo.sh) | One-screen summary of a box (OS, CPU, memory, disks, network), ready to paste into a ticket. |
| [`diskusage.sh`](diskusage.sh) | What is filling up the disk, and how to free some space. |
| [`backup.sh`](backup.sh) | Incremental `rsync` snapshots: every snapshot looks complete but only stores what changed. |
| [`netdiag.sh`](netdiag.sh) | "The Internet is down" checklist, layer by layer: interface, IP, gateway, Internet, DNS. Tells you where it breaks. |
| [`check-services.sh`](check-services.sh) | Checks that services are running (systemd or SysV). Can restart them. |
| [`ssh-failed-logins.sh`](ssh-failed-logins.sh) | Top IPs and usernames behind failed SSH logins. |
| [`ssl-expiry.sh`](ssl-expiry.sh) | Days left on TLS certificates, warns before they expire. |
| [`user-audit.sh`](user-audit.sh) | Local accounts, last logins, sudoers, UID 0 and empty passwords. |
| [`mysql-backup.sh`](mysql-backup.sh) | One `mysqldump` per database, credentials from `~/.my.cnf`. |
| [`port-check.sh`](port-check.sh) | Is a TCP port reachable? Pure bash, no `nc` or `telnet` needed. |

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
./ssl-expiry.sh example.com mail.example.com:993
./port-check.sh db01 3306
```

## Example: `netdiag.sh`

```
== 1. Network interfaces ==
  [ OK ] Interfaces up: eth0
== 2. IP addresses ==
  [ OK ] eth0: 192.168.1.34/24
== 3. Default gateway ==
  [ OK ] Gateway 192.168.1.1 is reachable.
== 4. Internet (no DNS) ==
  [ OK ] Internet is reachable (1.1.1.1 answers).
== 5. DNS resolution ==
  [FAIL] Internet works but names do not resolve. Check the DNS servers:
        nameserver 192.168.1.1
```

Here the problem is obvious: the connection works, but the router's DNS is not answering.

## Requirements

Bash 4+, `iproute2`, `iputils` (ping) and `rsync` for backups. Tested on Ubuntu 18.04 and CentOS 7.

## License

MIT
