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

<p>1. Заполним следующим содержимым:</p>

<pre># -*- mode: ruby -*-
# vi: set ft=ruby :

MACHINES = {
  :ipaserver => {
    :box_name => "centos/7",
    :ip => '192.168.50.10',
    :mem => '2048'
  },
  :ipaclient => {
    :box_name => "centos/7",
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

<p>2. Заходим на ВМ server и зайдём под пользователем root:</p>

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

<p>Добавим строки в файл /etc/hosts:</p>

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

<p>Установим необходимые пакеты для IPA сервера:</p>

<pre>[root@ipaserver ~]# yum update nss -y</pre>

<pre>[root@ipaserver ~]# yum install ipa-server ipa-server-dns -y</pre>

<pre>[root@ipaserver ~]# yum install bind-dyndb-ldap -y</pre>

<p>Выполним конфигурирование сервера:</p>

<pre>[root@ipaserver ~]# ipa-server-install --no-ntp

The log file for this installation can be found in /var/log/ipaserver-install.log
==============================================================================
This program will set up the IPA Server.

This includes:
  * Configure a stand-alone CA (dogtag) for certificate management
  * Create and configure an instance of Directory Server
  * Create and configure a Kerberos Key Distribution Center (KDC)
  * Configure Apache (httpd)
  * Configure the KDC to enable PKINIT

Excluded by options:
  * Configure the Network Time Daemon (ntpd)

To accept the default shown in brackets, press the Enter key.

Do you want to configure integrated DNS (BIND)? [no]: yes

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
Enter an IP address for a DNS forwarder, or press Enter to skip: 
No DNS forwarders configured
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
Forwarders:       No forwarders
Forward policy:   only
Reverse zone(s):  50.168.192.in-addr.arpa.

Continue to configure the system with these values? [no]: yes

...
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

	2. You can now obtain a kerberos ticket using the command: 'kinit admin'
	   This ticket will allow you to use the IPA tools (e.g., ipa user-add)
	   and the web user interface.
	3. Kerberos requires time synchronization between clients
	   and servers for correct operation. You should consider enabling ntpd.

Be sure to back up the CA certificates stored in /root/cacert.p12
These files are required to create replicas. The password for these
files is the Directory Manager password
[root@ipaserver ~]#</pre>


<pre>ipa-server-install -U --realm SERGSHA.LOCAL --domain sergsha.local --hostname=ipaserver.sergsha.local --ip-address=192.168.50.10 --setup-dns --auto-forwarders --no-reverse --mkhomedir --no-ntp -a Otus1234 -p Otus1234</pre>

<pre>...
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




<pre>[root@ipaserver ~]# ipa-server-install --realm=SERGSHA.LOCAL --domain=sergsha.local --ds-password=Otus1234 --admin-password=Otus1234 --mkhomedir --hostname=ipaserver.sergsha.local --ip-address=192.168.50.10 --no-ntp --unattended --setup-dns --auto-forwarders --auto-reverse
Checking DNS domain sergsha.local, please wait ...

The log file for this installation can be found in /var/log/ipaserver-install.log
==============================================================================
This program will set up the IPA Server.

This includes:
  * Configure a stand-alone CA (dogtag) for certificate management
  * Create and configure an instance of Directory Server
  * Create and configure a Kerberos Key Distribution Center (KDC)
  * Configure Apache (httpd)
  * Configure DNS (bind)
  * Configure the KDC to enable PKINIT

Excluded by options:
  * Configure the Network Time Daemon (ntpd)

Warning: skipping DNS resolution of host ipaserver.sergsha.local
Checking DNS domain sergsha.local., please wait ...
Checking DNS forwarders, please wait ...
DNS server 10.0.2.3: answer to query '. SOA' is missing DNSSEC signatures (no RRSIG data)
Please fix forwarder configuration to enable DNSSEC support.
(For BIND 9 add directive "dnssec-enable yes;" to "options {}")
WARNING: DNSSEC validation will be disabled
Using reverse zone(s) 50.168.192.in-addr.arpa.

The IPA Master Server will be configured with:
Hostname:       ipaserver.sergsha.local
IP address(es): 192.168.50.10
Domain name:    sergsha.local
Realm name:     SERGSHA.LOCAL

BIND DNS server will be configured to serve IPA domain with:
Forwarders:       10.0.2.3
Forward policy:   only
Reverse zone(s):  50.168.192.in-addr.arpa.

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

	2. You can now obtain a kerberos ticket using the command: 'kinit admin'
	   This ticket will allow you to use the IPA tools (e.g., ipa user-add)
	   and the web user interface.
	3. Kerberos requires time synchronization between clients
	   and servers for correct operation. You should consider enabling ntpd.

Be sure to back up the CA certificates stored in /root/cacert.p12
These files are required to create replicas. The password for these
files is the Directory Manager password
[root@ipaserver ~]#</pre>























<p>Запустим firewalld:</p>

<pre>[root@ipaserver ~]# systemctl enable firewalld --now
Created symlink from /etc/systemd/system/dbus-org.fedoraproject.FirewallD1.service to /usr/lib/systemd/system/firewalld.service.
Created symlink from /etc/systemd/system/multi-user.target.wants/firewalld.service to /usr/lib/systemd/system/firewalld.service.
[root@ipaserver ~]#</pre>

<p>В firewalld откроем порты, необходимые для работы FreeIPA:</p>

<pre>[root@ipaserver ~]# firewall-cmd --permanent --add-port=53/{tcp,udp} --add-port={80,443}/tcp --add-port={88,464}/{tcp,udp} --add-port=123/udp --add-port={389,636}/tcp
success
[root@ipaserver ~]#</pre>

<p>где<br />
- 53 — запросы DNS, если мы планируем использовать наш сервер в качестве сервера DNS;<br />
80 и 443 — http и https соответственно для доступа к веб-интерфейсу управления;<br />
88 и 464 — kerberos и kpasswd соответственно;<br />
123 — синхронизация времени;<br />
389 и 636 — ldap и ldaps соответственно.</p>

<p>Перечитаем обновленную конфигурацию firewalld:</p>

<pre>[root@ipaserver ~]# firewall-cmd --reload
success
[root@ipaserver ~]#</pre>




