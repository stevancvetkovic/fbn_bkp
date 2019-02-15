# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  config.vm.box = "centos/7"

  config.vm.network "forwarded_port", guest: 80, host: 9999
  config.vm.network "forwarded_port", guest: 8080, host: 8080

  config.vm.provider "virtualbox" do |vb|
    vb.memory = "8192"
    vb.cpus = 2
  end

  config.vm.provision "shell", inline: <<-SHELL
    yum install -y https://packages.microsoft.com/config/rhel/7/packages-microsoft-prod.rpm
    yum makecache fast
    yum install -y java-1.8.0-openjdk-devel dotnet-sdk-2.2 epel-release
    yum install -y nginx
    systemctl enable nginx
    systemctl restart nginx
    #yum localinstall -y https://downloads.tableau.com/esdalt/10.5.1/tableau-server-10-5-1.x86_64.rpm
    yum localinstall -y https://dev.mysql.com/get/mysql80-community-release-el7-1.noarch.rpm
    yum-config-manager --disable mysql80-community
    yum-config-manager --enable mysql57-community
    yum install -y mysql-community-server
    systemctl start mysqld.service
    systemctl enable mysqld.service
    MYSQL_ROOT_PASSWORD=`grep 'A temporary password is generated for root@localhost' /var/log/mysqld.log | tail -1 | awk '{print $11}'`
    echo "Your MySQL root user password is: $MYSQL_ROOT_PASSWORD - make sure to change it with ALTER USER 'root'@'localhost' IDENTIFIED BY 'NEWPASSWORD';"
  SHELL
end
