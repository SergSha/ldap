<h3>### LDAP ###</h3>

<h4>Описание домашнего задания</h4>

<ol>
<li>Установить FreeIPA;</li>
<li>Написать Ansible playbook для конфигурации клиента;</li>
<li>*Настроить аутентификацию по SSH-ключам;</li>
<li>**Firewall должен быть включен на сервере и на клиенте.</li>
</ol>

<p>Формат сдачи ДЗ - vagrant + ansible</p>

<h4>Создание стенда FreeIPA</h4>

<p>В домашней директории создадим директорию ldap, в котором будут храниться настройки виртуальных машин:</p>

<pre>[user@localhost otus]$ mkdir ./ldap
[user@localhost otus]$</pre>

<p>Перейдём в директорию ldap:</p>

<pre>[user@localhost otus]$ cd ./ldap/
[user@localhost ldap]$</pre>

<p>Создадим файл Vagrantfile:</p>

<pre>[user@localhost ldap]$ vi ./Vagrantfile</pre>

<p>Заполним следующим содержимым:</p>

<pre># -*- mode: ruby -*-
# vi: set ft=ruby :

MACHINES = {
  :ipaserver => {
    :box_name => "centos/7",
    :vm_name => "ipaserver",
    :ip => '192.168.50.10',
    :mem => '2048'
  },
  :ipaclient => {
    :box_name => "centos/7",
    :vm_name => "ipaclient",
    :ip => '192.168.50.11',
    :mem => '1048'
  }
}
Vagrant.configure("2") do |config|
  MACHINES.each do |boxname, boxconfig|
    config.vm.define boxname do |box|
      box.vm.box = boxconfig[:box_name]
      box.vm.host_name = boxname.to_s
      box.vm.network "private_network", ip: boxconfig[:ip]
      box.vm.provider :virtualbox do |vb|
        vb.customize ["modifyvm", :id, "--memory", boxconfig[:mem]]
      end
#      if boxconfig[:vm_name] == "ipaclient"
#        box.vm.provision "ansible" do |ansible|
#          ansible.playbook = "ansible/playbook.yml"
#          ansible.inventory_path = "ansible/hosts"
#          ansible.become = true
#          #ansible.verbose = "vvv"
#          ansible.host_key_checking = "false"
#          ansible.limit = "all"
#        end
#      end
    end
  end
end</pre>

<p>Запустим эти виртуальные машины:</p>

<pre>[user@localhost ldap]$ vagrant up</pre>

<p>Проверим состояние созданной и запущенной машины:</p>

<pre>[user@localhost ldap]$ vagrant status
Current machine states:

ipaserver                    running (virtualbox)
ipaclient                    running (virtualbox)

This environment represents multiple VMs. The VMs are all listed
above with their current state. For more information about a specific
VM, run `vagrant status NAME`.
[user@localhost ldap]$</pre>

<h4>Создание и настройка сервера FreeIPA</h4>

<p>Заходим на ВМ server и зайдём под пользователем root:</p>

<pre>[user@localhost ldap]$ vagrant ssh ipaserver
[vagrant@ipaserver ~]$ sudo -i
[root@ipaserver ~]# </pre>

<p>Имя сервера:</p>

<pre>[root@ipaserver ~]# hostname
<b>ipaserver</b>
[root@ipaserver ~]#</pre>

<p>Для корректной работы сервера зададим ему полное доменное имя (FQDN):</p>

<pre>[root@ipaserver ~]# hostnamectl set-hostname ipaserver.sergsha.local
[root@ipaserver ~]#</pre>

<pre>[root@ipaserver ~]# hostname
<b>ipaserver.sergsha.local</b>
[root@ipaserver ~]#</pre>

<p>Установим нужный часовой пояс (в данном случае Europe/Moscow):</p>

<pre>[root@ipaserver ~]# timedatectl set-timezone Europe/Moscow</pre>

<pre>[root@ipaserver ~]# timedatectl status
      Local time: Mon 2022-10-31 10:41:08 MSK
  Universal time: Mon 2022-10-31 07:41:08 UTC
        RTC time: Mon 2022-10-31 07:41:06
       Time zone: Europe/Moscow (MSK, +0300)
     NTP enabled: yes
NTP synchronized: yes
 RTC in local TZ: no
      DST active: n/a
[root@ipaserver ~]#</pre>

<p>проверим работу сервиса синхронизации времени chronyd:</p>

<pre>[root@ipaserver ~]# systemctl status chronyd
● chronyd.service - NTP client/server
   Loaded: loaded (/usr/lib/systemd/system/chronyd.service; enabled; vendor preset: enabled)
   Active: active (running) since Fri 2022-10-28 08:58:24 MSK; 3 days ago
     Docs: man:chronyd(8)
           man:chrony.conf(5)
 Main PID: 346 (chronyd)
   CGroup: /system.slice/chronyd.service
           └─346 /usr/sbin/chronyd

Oct 29 01:12:16 ipaserver.sergsha.local chronyd[346]: Selected source 193.99....
Oct 29 09:14:59 ipaserver.sergsha.local chronyd[346]: Selected source 92.222....
Oct 29 15:33:50 ipaserver.sergsha.local chronyd[346]: Selected source 193.99....
Oct 29 18:06:18 ipaserver.sergsha.local chronyd[346]: Selected source 188.68....
Oct 29 19:32:35 ipaserver.sergsha.local chronyd[346]: Selected source 193.99....
Oct 29 23:31:31 ipaserver.sergsha.local chronyd[346]: Selected source 92.222....
Oct 30 08:58:02 ipaserver.sergsha.local chronyd[346]: Selected source 193.99....
Oct 30 15:17:25 ipaserver.sergsha.local chronyd[346]: Selected source 92.222....
Oct 30 20:47:18 ipaserver.sergsha.local chronyd[346]: Selected source 193.99....
Oct 30 23:05:09 ipaserver.sergsha.local chronyd[346]: Selected source 92.222....
Hint: Some lines were ellipsized, use -l to show in full.
[root@ipaserver ~]#</pre>

<p>Так как DNS пока ещё не настроен, добавим строки в файл /etc/hosts:</p>

<pre>[root@ipaserver ~]# echo -e "192.168.50.10 ipaserver.sergsha.local ipaserver.sergsha.local\n192.168.50.11 ipaclient.sergsha.local ipaclient.sergsha.local" >> /etc/hosts
[root@ipaserver ~]#</pre>

<pre>[root@ipaserver ~]# less /etc/hosts
127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4
::1         localhost localhost.localdomain localhost6 localhost6.localdomain6
127.0.1.1 ipaserver ipaserver
192.168.50.10 ipaserver.sergsha.local ipaserver.sergsha.local
192.168.50.11 ipaclient.sergsha.local ipaclient.sergsha.local</pre>

<p>Отключим SELinux:</p>

<pre>[root@ipaserver ~]# setenforce 0
[root@ipaserver ~]# sed -i 's/^SELINUX=.*/SELINUX=permissive/g' /etc/selinux/config
[root@ipaserver ~]# getenforce
Permissive
[root@ipaserver ~]#</pre>

<p>Firewalld пока отключен:</p>

<pre>[root@ipaserver ~]# systemctl status firewalld
● firewalld.service - firewalld - dynamic firewall daemon
   Loaded: loaded (/usr/lib/systemd/system/firewalld.service; disabled; vendor preset: enabled)
   Active: inactive (dead)
     Docs: man:firewalld(1)
[root@ipaserver ~]#</pre>

<p>Установим необходимые пакеты для IPA сервера:</p>

<pre>[root@ipaserver ~]# yum update nss -y</pre>

<pre>[root@ipaserver ~]# yum install ipa-server ipa-server-dns -y</pre>

<!-- <pre>[root@ipaserver ~]# yum install bind-dyndb-ldap -y</pre> -->

<p>Выполним конфигурирование сервера IPA:</p>

<pre>[root@ipaserver ~]# ipa-server-install --setup-dns

The log file for this installation can be found in /var/log/ipaserver-install.log
==============================================================================
This program will set up the IPA Server.

This includes:
  * Configure a stand-alone CA (dogtag) for certificate management
  * Configure the Network Time Daemon (ntpd)
  * Create and configure an instance of Directory Server
  * Create and configure a Kerberos Key Distribution Center (KDC)
  * Configure Apache (httpd)
  * Configure DNS (bind)
  * Configure the KDC to enable PKINIT

To accept the default shown in brackets, press the Enter key.

WARNING: conflicting time&date synchronization service 'chronyd' will be disabled
in favor of ntpd

Enter the fully qualified domain name of the computer
on which you're setting up server software. Using the form
<hostname>.<domainname>
Example: master.example.com.


Server host name [ipaserver.sergsha.local]:

Warning: skipping DNS resolution of host ipaserver.sergsha.local
The domain name has been determined based on the host name.

Please confirm the domain name [sergsha.local]:

The kerberos protocol requires a Realm name to be defined.
This is typically the domain name converted to uppercase.

Please provide a realm name [SERGSHA.LOCAL]:
Certain directory server operations require an administrative user.
This user is referred to as the Directory Manager and has full access
to the Directory for system management tasks and will be added to the
instance of directory server created for IPA.
The password must be at least 8 characters long.

Directory Manager password:
Password (confirm):

The IPA server requires an administrative user, named 'admin'.
This user is a regular system account used for IPA server administration.

IPA admin password:
Password (confirm):

Checking DNS domain sergsha.local., please wait ...
Do you want to configure DNS forwarders? [yes]:
Following DNS servers are configured in /etc/resolv.conf: 10.0.2.3
Do you want to configure these servers as DNS forwarders? [yes]: no
Enter an IP address for a DNS forwarder, or press Enter to skip: 8.8.8.8
DNS forwarder 8.8.8.8 added. You may add another.
Enter an IP address for a DNS forwarder, or press Enter to skip: 8.8.4.4
DNS forwarder 8.8.4.4 added. You may add another.
Enter an IP address for a DNS forwarder, or press Enter to skip:
Checking DNS forwarders, please wait ...
Do you want to search for missing reverse zones? [yes]:
Do you want to create reverse zone for IP 192.168.50.10 [yes]:
Please specify the reverse zone name [50.168.192.in-addr.arpa.]:
Using reverse zone(s) 50.168.192.in-addr.arpa.

The IPA Master Server will be configured with:
Hostname:       ipaserver.sergsha.local
IP address(es): 192.168.50.10
Domain name:    sergsha.local
Realm name:     SERGSHA.LOCAL

BIND DNS server will be configured to serve IPA domain with:
Forwarders:       8.8.8.8, 8.8.4.4
Forward policy:   only
Reverse zone(s):  50.168.192.in-addr.arpa.

Continue to configure the system with these values? [no]: yes
...
The ipa-client-install command was successful

==============================================================================
Setup complete

Next steps:
        1. You must make sure these network ports are open:
                TCP Ports:
                  * 80, 443: HTTP/HTTPS
                  * 389, 636: LDAP/LDAPS
                  * 88, 464: kerberos
                  * 53: bind
                UDP Ports:
                  * 88, 464: kerberos
                  * 53: bind
                  * 123: ntp

        2. You can now obtain a kerberos ticket using the command: 'kinit admin'
           This ticket will allow you to use the IPA tools (e.g., ipa user-add)
           and the web user interface.

Be sure to back up the CA certificates stored in /root/cacert.p12
These files are required to create replicas. The password for these
files is the Directory Manager password
[root@ipaserver ~]#</pre>

<p>Попробуем запросить билет Kerberos для пользователя admin непосредственно на самом сервере IPA (вводим пароль администратора, который указывали при конфигурировании FreeIPA):</p>

<pre>[root@ipaserver ~]# kinit admin
Password for admin@SERGSHA.LOCAL:
[root@ipaserver ~]#</pre>

<p>Проверяем, что получилось выписать билет Kerberos:</p>

<pre>[root@ipaserver ~]# klist
Ticket cache: KEYRING:persistent:0:0
Default principal: admin@SERGSHA.LOCAL

Valid starting       Expires              Service principal
10/31/2022 11:23:13  11/01/2022 11:23:04  krbtgt/SERGSHA.LOCAL@SERGSHA.LOCAL
[root@ipaserver ~]#</pre>

<p>Как мы видим, мы получили билет Kerberos.</p>

<p>Проверим статус всех подсистем FreeIPA:</p>

<pre>[root@ipaserver ~]# ipactl status
Directory Service: RUNNING
krb5kdc Service: RUNNING
kadmin Service: RUNNING
named Service: RUNNING
httpd Service: RUNNING
ipa-custodia Service: RUNNING
ntpd Service: RUNNING
pki-tomcatd Service: RUNNING
ipa-otpd Service: RUNNING
ipa-dnskeysyncd Service: RUNNING
ipa: INFO: The ipactl command was successful
[root@ipaserver ~]#</pre>

<p>Как видно, все сервисы запущены.</p>

<p>Создаем нового пользователя, например, ipetrov:</p>

<pre>[root@ipaserver ~]# ipa user-add ipetrov --first=Ivan --last=Petrov  --email=ipetrov@email.ru --shell=/bin/bash --password
Password:
Enter Password again to verify:
--------------------
Added user "ipetrov"
--------------------
  User login: ipetrov
  First name: Ivan
  Last name: Petrov
  Full name: Ivan Petrov
  Display name: Ivan Petrov
  Initials: IP
  Home directory: /home/ipetrov
  GECOS: Ivan Petrov
  Login shell: /bin/bash
  Principal name: ipetrov@SERGSHA.LOCAL
  Principal alias: ipetrov@SERGSHA.LOCAL
  User password expiration: 20221031092004Z
  Email address: ipetrov@email.ru
  UID: 1192400001
  GID: 1192400001
  Password: True
  Member of groups: ipausers
  Kerberos keys available: True
[root@ipaserver ~]#</pre>

<p>Включаем firewalld:</p>

<pre>[root@ipaserver ~]# systemctl enable firewalld --now
Created symlink from /etc/systemd/system/dbus-org.fedoraproject.FirewallD1.service to /usr/lib/systemd/system/firewalld.service.
Created symlink from /etc/systemd/system/multi-user.target.wants/firewalld.service to /usr/lib/systemd/system/firewalld.service.
[root@ipaserver ~]#</pre>

<p>В firewalld откроем порты, необходимые для работы FreeIPA:</p>

<!-- <pre>firewall-cmd --permanent --add-service={http,https,ldap,ldaps,kerberos,bind,ntp} && firewall-cmd --reload</pre> -->

<pre>[root@ipaserver ~]# firewall-cmd --permanent --add-port={80,443}/tcp --add-port={389,636}/tcp --add-port={88,464}/{tcp,udp} --add-port=53/{tcp,udp} --add-port=123/udp && firewall-cmd --reload
success
success
[root@ipaserver ~]#</pre>

<p>Проверим работу сервиса firewalld:</p>

<pre>[root@ipaserver ~]# systemctl status firewalld
● firewalld.service - firewalld - dynamic firewall daemon
   Loaded: loaded (/usr/lib/systemd/system/firewalld.service; enabled; vendor preset: enabled)
   Active: active (running) since Mon 2022-10-31 13:00:08 MSK; 10min ago
     Docs: man:firewalld(1)
 Main PID: 9968 (firewalld)
   CGroup: /system.slice/firewalld.service
           └─9968 /usr/bin/python2 -Es /usr/sbin/firewalld --nofork --nopid

Oct 31 13:00:07 ipaserver.sergsha.local systemd[1]: Starting firewalld - dynamic ....
Oct 31 13:00:08 ipaserver.sergsha.local systemd[1]: Started firewalld - dynamic f....
Oct 31 13:00:08 ipaserver.sergsha.local firewalld[9968]: WARNING: AllowZoneDriftin...
Oct 31 13:08:49 ipaserver.sergsha.local firewalld[9968]: WARNING: AllowZoneDriftin...
Hint: Some lines were ellipsized, use -l to show in full.
[root@ipaserver ~]#</pre>

<h4>Создание и настройка клиентского сервера FreeIPA</h4>

<p>В отдельном окне подключимся по ssh к серверу ipaclient и войдём под пользователем root:</p>

<pre>[user@localhost ldap]$ vagrant ssh ipaclient
Last login: Fri Oct 28 06:00:22 2022 from 192.168.50.1
[vagrant@ipaclient ~]$ sudo -i
[root@ipaclient ~]#</pre>

[root@ipaclient ~]# hostname
ipaclient
[root@ipaclient ~]#

<p>Для корректной работы сервера зададим ему полное доменное имя (FQDN):</p>

<pre>[root@ipaserver ~]# hostnamectl set-hostname ipaclient.sergsha.local
[root@ipaserver ~]#</pre>

<pre>[root@ipaclient ~]# hostname
<b>ipaclient.sergsha.local</b>
[root@ipaclient ~]#</pre>

<p>Установим нужный часовой пояс (в данном случае Europe/Moscow):</p>

<pre>[root@ipaclient ~]# timedatectl set-timezone Europe/Moscow
[root@ipaclient ~]#</pre>

<pre>[root@ipaclient ~]# timedatectl status
      Local time: Mon 2022-10-31 14:17:55 MSK
  Universal time: Mon 2022-10-31 11:17:55 UTC
        RTC time: Mon 2022-10-31 11:17:53
       Time zone: Europe/Moscow (MSK, +0300)
     NTP enabled: yes
NTP synchronized: yes
 RTC in local TZ: no
      DST active: n/a
[root@ipaclient ~]#</pre>

<p>Так как DNS пока ещё не настроен, добавим строки в файл /etc/hosts:</p>

<pre>[root@ipaclient ~]# echo -e "192.168.50.10 ipaserver.sergsha.local ipaserver.sergsha.local\n192.168.50.11 ipaclient.sergsha.local ipaclient.sergsha.local" >> /etc/hosts
[root@ipaclient ~]#</pre>

<pre>[root@ipaclient ~]# less /etc/hosts
127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4
::1         localhost localhost.localdomain localhost6 localhost6.localdomain6
127.0.1.1 ipaclient ipaclient
192.168.50.10 ipaserver.sergsha.local ipaserver.sergsha.local
192.168.50.11 ipaclient.sergsha.local ipaclient.sergsha.local</pre>

<p>Отключим SELinux:</p>

<pre>[root@ipaclient ~]# setenforce 0
[root@ipaclient ~]# sed -i 's/^SELINUX=.*/SELINUX=permissive/g' /etc/selinux/config
[root@ipaclient ~]# getenforce
Permissive
[root@ipaclient ~]#</pre>

<p>Firewalld пока отключен:</p>

<pre>[root@ipaclient ~]# systemctl status firewalld
● firewalld.service - firewalld - dynamic firewall daemon
   Loaded: loaded (/usr/lib/systemd/system/firewalld.service; disabled; vendor preset: enabled)
   Active: inactive (dead)
     Docs: man:firewalld(1)
[root@ipaclient ~]#</pre>

<p>Устанавливаем пакет для клиента FreeIPA:</p>

<pre>[root@ipaclient ~]# yum install ipa-client -y</pre>

<p>Присоединим нашего клиента к домену FreeIPA:</p>

<pre>[root@ipaclient ~]# ipa-client-install --mkhomedir
WARNING: ntpd time&date synchronization service will not be configured as
conflicting service (chronyd) is enabled
Use --force-ntpd option to disable it and force configuration of ntpd

DNS discovery failed to determine your DNS domain
Provide the domain name of your IPA server (ex: example.com): sergsha.local
Provide your IPA server name (ex: ipa.example.com): ipaserver.sergsha.local
The failure to use DNS to find your IPA server indicates that your resolv.conf file is not properly configured.
Autodiscovery of servers for failover cannot work with this configuration.
If you proceed with the installation, services will be configured to always access the discovered server for all operations and will not fail over to other servers in case of failure.
Proceed with fixed values and no DNS discovery? [no]: yes
Client hostname: ipaclient.sergsha.local
Realm: SERGSHA.LOCAL
DNS Domain: sergsha.local
IPA Server: ipaserver.sergsha.local
BaseDN: dc=sergsha,dc=local

Continue to configure the system with these values? [no]: yes
Skipping synchronizing time with NTP server.
User authorized to enroll computers: admin
Password for admin@SERGSHA.LOCAL:
Successfully retrieved CA cert
    Subject:     CN=Certificate Authority,O=SERGSHA.LOCAL
    Issuer:      CN=Certificate Authority,O=SERGSHA.LOCAL
    Valid From:  2022-10-31 08:01:25
    Valid Until: 2042-10-31 08:01:25

Enrolled in IPA realm SERGSHA.LOCAL
Created /etc/ipa/default.conf
New SSSD config will be created
Configured sudoers in /etc/nsswitch.conf
Configured /etc/sssd/sssd.conf
Configured /etc/krb5.conf for IPA realm SERGSHA.LOCAL
trying https://ipaserver.sergsha.local/ipa/json
[try 1]: Forwarding 'schema' to json server 'https://ipaserver.sergsha.local/ipa/json'
trying https://ipaserver.sergsha.local/ipa/session/json
[try 1]: Forwarding 'ping' to json server 'https://ipaserver.sergsha.local/ipa/session/json'
[try 1]: Forwarding 'ca_is_enabled' to json server 'https://ipaserver.sergsha.local/ipa/session/json'
Systemwide CA database updated.
Hostname (ipaclient.sergsha.local) does not have A/AAAA record.
Failed to update DNS records.
Missing A/AAAA record(s) for host ipaclient.sergsha.local: 192.168.50.11.
Missing reverse record(s) for address(es): 192.168.50.11.
Adding SSH public key from /etc/ssh/ssh_host_rsa_key.pub
Adding SSH public key from /etc/ssh/ssh_host_ecdsa_key.pub
Adding SSH public key from /etc/ssh/ssh_host_ed25519_key.pub
[try 1]: Forwarding 'host_mod' to json server 'https://ipaserver.sergsha.local/ipa/session/json'
Could not update DNS SSHFP records.
SSSD enabled
Configured /etc/openldap/ldap.conf
Configured /etc/ssh/ssh_config
Configured /etc/ssh/sshd_config
Configuring sergsha.local as NIS domain.
Client configuration complete.
The ipa-client-install command was successful
[root@ipaclient ~]#</pre>

<p>Включаем firewalld:</p>

<pre>[root@ipaclient ~]# systemctl enable firewalld --now
Created symlink from /etc/systemd/system/dbus-org.fedoraproject.FirewallD1.service to /usr/lib/systemd/system/firewalld.service.
Created symlink from /etc/systemd/system/multi-user.target.wants/firewalld.service to /usr/lib/systemd/system/firewalld.service.
[root@ipaclient ~]#</pre>

<p>В firewalld откроем порты, необходимые для работы FreeIPA:</p>

<pre>[root@ipaclient ~]# firewall-cmd --permanent --add-port={80,443}/tcp --add-port={389,636}/tcp --add-port={88,464}/{tcp,udp} --add-port=53/{tcp,udp} --add-port=123/udp && firewall-cmd --reload
success
success
[root@ipaclient ~]#</pre>

<p>Проверим работу сервиса firewalld:</p>

<pre>[root@ipaclient ~]# systemctl status firewalld
● firewalld.service - firewalld - dynamic firewall daemon
   Loaded: loaded (/usr/lib/systemd/system/firewalld.service; enabled; vendor preset: enabled)
   Active: active (running) since Mon 2022-10-31 15:47:26 MSK; 8min ago
     Docs: man:firewalld(1)
 Main PID: 24403 (firewalld)
   CGroup: /system.slice/firewalld.service
           └─24403 /usr/bin/python2 -Es /usr/sbin/firewalld --nofork --nopid

Oct 31 15:47:25 ipaclient.sergsha.local systemd[1]: Starting firewalld - dyna...
Oct 31 15:47:26 ipaclient.sergsha.local systemd[1]: Started firewalld - dynam...
Oct 31 15:47:26 ipaclient.sergsha.local firewalld[24403]: WARNING: AllowZoneD...
Hint: Some lines were ellipsized, use -l to show in full.
[root@ipaclient ~]#</pre>

<p>Попробуем заполучить билет Kerberos для пользователя ipetrov:</p>

<pre>[root@ipaclient ~]# kinit ipetrov
Password for ipetrov@SERGSHA.LOCAL:
[root@ipaclient ~]#</pre>

<p>Проверяем, получилось ли у нас выписать билет Kerberos:</p>

<pre>[root@ipaclient ~]# klist
Ticket cache: KEYRING:persistent:0:0
Default principal: ipetrov@SERGSHA.LOCAL

Valid starting       Expires              Service principal
10/31/2022 15:53:24  11/01/2022 15:53:14  krbtgt/SERGSHA.LOCAL@SERGSHA.LOCAL
[root@ipaclient ~]#</pre>

<p>Теперь попробуем зайти под пользователем ipetrov:</p>

<pre>[root@ipaclient ~]# su - ipetrov
Creating home directory for ipetrov.
[ipetrov@ipaclient ~]$</pre>

<p>Как видим, мы смогли зайти под пользователем ipetrov.</p>

<p>Сгенерируем ssh-ключ для пользователя ipetrov:</p>

<pre>[ipetrov@ipaclient ~]$ ssh-keygen -t rsa -b 4096 -f /home/ipetrov/.ssh/ipetrov
Generating public/private rsa key pair.
Enter passphrase (empty for no passphrase):
Enter same passphrase again:
Your identification has been saved in /home/ipetrov/.ssh/ipetrov.
Your public key has been saved in /home/ipetrov/.ssh/ipetrov.pub.
The key fingerprint is:
SHA256:v/dMqBPM2XVj/TlAw4hbIbJdJsphrJLPNPE87j38mVE ipetrov@ipaclient.sergsha.local
The key's randomart image is:
+---[RSA 4096]----+
|      .+ o.++    |
|     .o.*.=o +   |
|    . =+ .o . . .|
|   o + + .   ..oo|
|    = o So o Eo.+|
|     o . .= o. o.|
|      . o .o. . .|
|       . +.o=o   |
|          =* .o  |
+----[SHA256]-----+
[ipetrov@ipaclient ~]$</pre>

<p>Скопируем содержимое публичного ключа для передачи в настройки FreeIPA для пользователя ipetrov:</p>

<pre>[ipetrov@ipaclient ~]$ less ./.ssh/ipetrov.pub
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCxqQNj4GMsD9ikb73ETn1jpw2bo2gK//lTwYLbBpTD9Rb9NAsgfUkaT0V88Y8vzW0lSJxR72wqTJHHC4SEcxN8Vepa8Ub9sbmQgZXSSSXRdWqBEpSnouA7kT7GHG/BQJntWpBcqID5Dm4m6OHqz9oH7S4g5XVwNxA4E0HZzVuHSx11CUvmv3XrTJkWomvAEZhsl2lmvTsEsESYQMGgbHSTbmhv9ct/C//3X1Lt0TORuJSXDjRtdSOs+WZp5vIXeTdOpVSr5aSX3waLWx1L/HfbeCOXPuFrRbxkuSJaB36X41g5h3fwjr0KAHra+/w36PKbehkJTBS9SfG+M5BxhokUvEatibXuiT8wkODW5gbwoEd22DnWXWF3calsbboPSGAXXXhS5dFNIo2LDl7bvycOZEKUDTRX0es/AP4XgbHbPkH3mDlKKwJN70toSD1E13lG9m1XI7nADvQ72xGKTZSO8MnlEAIN0HjbZg6hdSuNINh1pbAZv8LBm2DFfiyWNLoln/YeBuYzKzoZMyGOnfRg6uFZrFfYDbzwKpVQzaCBE5ZyEwgpTfkPcYuB6oiyvzlptEwHZqimVgX6FgP235Bp92M4vIkqYcxYKA0/sjrEYhzPifk0O1h6zrkBhnnwYJlh10TBUCHJGWfzx7NNwIzLAaDmC2wpamE7EU4s0xQ23w== ipetrov@ipaclient.sergsha.local</pre>

<p>На сервере ipaserver запустим следующую команду:</p>

<pre>[root@ipaserver ~]# ipa user-mod ipetrov --sshpubkey="ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCxqQNj4GMsD9ikb73ETn1jpw2bo2gK//lTwYLbBpTD9Rb9NAsgfUkaT0V88Y8vzW0lSJxR72wqTJHHC4SEcxN8Vepa8Ub9sbmQgZXSSSXRdWqBEpSnouA7kT7GHG/BQJntWpBcqID5Dm4m6OHqz9oH7S4g5XVwNxA4E0HZzVuHSx11CUvmv3XrTJkWomvAEZhsl2lmvTsEsESYQMGgbHSTbmhv9ct/C//3X1Lt0TORuJSXDjRtdSOs+WZp5vIXeTdOpVSr5aSX3waLWx1L/HfbeCOXPuFrRbxkuSJaB36X41g5h3fwjr0KAHra+/w36PKbehkJTBS9SfG+M5BxhokUvEatibXuiT8wkODW5gbwoEd22DnWXWF3calsbboPSGAXXXhS5dFNIo2LDl7bvycOZEKUDTRX0es/AP4XgbHbPkH3mDlKKwJN70toSD1E13lG9m1XI7nADvQ72xGKTZSO8MnlEAIN0HjbZg6hdSuNINh1pbAZv8LBm2DFfiyWNLoln/YeBuYzKzoZMyGOnfRg6uFZrFfYDbzwKpVQzaCBE5ZyEwgpTfkPcYuB6oiyvzlptEwHZqimVgX6FgP235Bp92M4vIkqYcxYKA0/sjrEYhzPifk0O1h6zrkBhnnwYJlh10TBUCHJGWfzx7NNwIzLAaDmC2wpamE7EU4s0xQ23w== ipetrov@ipaclient.sergsha.local"
-----------------------
Modified user "ipetrov"
-----------------------
  User login: ipetrov
  First name: Ivan
  Last name: Petrov
  Home directory: /home/ipetrov
  Login shell: /bin/bash
  Principal name: ipetrov@SERGSHA.LOCAL
  Principal alias: ipetrov@SERGSHA.LOCAL
  Email address: ipetrov@email.ru
  UID: 1192400001
  GID: 1192400001
  SSH public key: ssh-rsa
                  AAAAB3NzaC1yc2EAAAADAQABAAACAQCxqQNj4GMsD9ikb73ETn1jpw2bo2gK//lTwYLbBpTD9Rb9NAsgfUkaT0V88Y8vzW0lSJxR72wqTJHHC4SEcxN8Vepa8Ub9sbmQgZXSSSXRdWqBEpSnouA7kT7GHG/BQJntWpBcqID5Dm4m6OHqz9oH7S4g5XVwNxA4E0HZzVuHSx11CUvmv3XrTJkWomvAEZhsl2lmvTsEsESYQMGgbHSTbmhv9ct/C//3X1Lt0TORuJSXDjRtdSOs+WZp5vIXeTdOpVSr5aSX3waLWx1L/HfbeCOXPuFrRbxkuSJaB36X41g5h3fwjr0KAHra+/w36PKbehkJTBS9SfG+M5BxhokUvEatibXuiT8wkODW5gbwoEd22DnWXWF3calsbboPSGAXXXhS5dFNIo2LDl7bvycOZEKUDTRX0es/AP4XgbHbPkH3mDlKKwJN70toSD1E13lG9m1XI7nADvQ72xGKTZSO8MnlEAIN0HjbZg6hdSuNINh1pbAZv8LBm2DFfiyWNLoln/YeBuYzKzoZMyGOnfRg6uFZrFfYDbzwKpVQzaCBE5ZyEwgpTfkPcYuB6oiyvzlptEwHZqimVgX6FgP235Bp92M4vIkqYcxYKA0/sjrEYhzPifk0O1h6zrkBhnnwYJlh10TBUCHJGWfzx7NNwIzLAaDmC2wpamE7EU4s0xQ23w==
                  ipetrov@ipaclient.sergsha.local
  SSH public key fingerprint: SHA256:v/dMqBPM2XVj/TlAw4hbIbJdJsphrJLPNPE87j38mVE
                              ipetrov@ipaclient.sergsha.local (ssh-rsa)
  Account disabled: False
  Password: True
  Member of groups: ipausers
  Kerberos keys available: True
[root@ipaserver ~]#</pre>

<p>Теперь с клиентского сервера ipaclient под пользователем ipetrov с помощью ssh-ключа попытаемся зайти на сервер ipaserver:</p>

<pre>[ipetrov@ipaclient ~]$ ssh ipetrov@ipaserver.sergsha.local -i ./.ssh/ipetrov
Last login: Mon Oct 31 15:22:06 2022 from 192.168.50.11
[ipetrov@ipaserver ~]$</pre>

<p>Убедимся, что мы подключились к серверу ipaserver и под пользователем ipetrov:</p>

<pre>[ipetrov@ipaserver ~]$ hostname
ipaserver.sergsha.local
[ipetrov@ipaserver ~]$ whoami
ipetrov
[ipetrov@ipaserver ~]$</pre>

<h4>Запуск стенда "FreeIPA"</h4>

<p>Запустить стенд с помощью следующей команды:</p>

<pre>$ git clone https://github.com/SergSha/ldap.git && cd ./ldap/ && mkdir ~/.ssh 2> /dev/null; ssh-keygen -q -t rsa -b 4096 -f ~/.ssh/ipetrov -N '' && cp ~/.ssh/ipetrov.pub ./ansible/roles/ldap/files/ -f && vagrant up</pre>

<p>После завершения можно войти под пользователем ipetrov с использованием ssh ключа либо на сервер ipaserver:</p>

<pre>$ ssh ipetrov@192.168.50.10 -i ~/.ssh/ipetrov</pre>

<p>либо на клиентский сервер ipaclient:</p>

<pre>$ ssh ipetrov@192.168.50.11 -i ./.ssh/ipetrov</pre>


