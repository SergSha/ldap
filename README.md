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

<p>Отключим SELinux:</p>

<pre>[root@ipaserver ~]# setenforce 0
[root@ipaserver ~]# sed -i 's/^SELINUX=.*/SELINUX=disabled/g' /etc/selinux/config
[root@ipaserver ~]# getenforce
Permissive
[root@ipaserver ~]#</pre>


<p>Установим необходимые пакеты для FreeIPA:</p>

<pre>[root@ipaserver ~]# yum install nss, ipa-server{,-dns} bind-dyndb-ldap -y</pre>

<p>Наш сервер будет использоваться ещё и как DNS:</p>

<pre>[root@ipaserver ~]# yum install ipa-server-dns -y</pre>

<p>Выполним конфигурирование сервера:</p>

<pre>[root@ipaserver ~]# ipa-server-install

The log file for this installation can be found in /var/log/ipaserver-install.log
==============================================================================
This program will set up the IPA Server.

This includes:
  * Configure a stand-alone CA (dogtag) for certificate management
  * Configure the Network Time Daemon (ntpd)
  * Create and configure an instance of Directory Server
  * Create and configure a Kerberos Key Distribution Center (KDC)
  * Configure Apache (httpd)
  * Configure the KDC to enable PKINIT

To accept the default shown in brackets, press the Enter key.

WARNING: conflicting time&date synchronization service 'chronyd' will be disabled
in favor of ntpd

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

Directory Manager password: 'Otus1234'
Password (confirm):         'Otus1234'

The IPA server requires an administrative user, named 'admin'.
This user is a regular system account used for IPA server administration.

IPA admin password:         'Otus1234'
Password (confirm):         'Otus1234'

Checking DNS domain sergsha.local., please wait ...
Do you want to configure DNS forwarders? [yes]:
Following DNS servers are configured in /etc/resolv.conf: 10.0.2.3
Do you want to configure these servers as DNS forwarders? [yes]:
All DNS servers from /etc/resolv.conf were added. You can enter additional addresses now:
Enter an IP address for a DNS forwarder, or press Enter to skip:
Checking DNS forwarders, please wait ...
Do you want to search for missing reverse zones? [yes]:
Do you want to create reverse zone for IP 10.0.2.15 [yes]: no
Do you want to create reverse zone for IP 192.168.50.10 [yes]:
Please specify the reverse zone name [50.168.192.in-addr.arpa.]:
Using reverse zone(s) 50.168.192.in-addr.arpa.

The IPA Master Server will be configured with:
Hostname:       ipaserver.sergsha.local
IP address(es): 10.0.2.15, 192.168.50.10
Domain name:    sergsha.local
Realm name:     SERGSHA.LOCAL

BIND DNS server will be configured to serve IPA domain with:
Forwarders:       10.0.2.3
Forward policy:   only
Reverse zone(s):  50.168.192.in-addr.arpa.

Continue to configure the system with these values? [no]: yes
...</pre>

<pre>ipapython.admintool: ERROR    Installation aborted
ipapython.admintool: ERROR    The ipa-server-install command failed. See /var/log/ipaserver-install.log for more information
[root@ipaserver ~]#</pre>

<pre>ipa-server-install -U --realm SERGSHA.LOCAL --domain sergsha.local --hostname=ipaserver.sergsha.local --ip-address=192.168.50.10 --setup-dns --auto-forwarders --no-reverse --mkhomedir -a Otus1234 -p Otus1234</pre>









