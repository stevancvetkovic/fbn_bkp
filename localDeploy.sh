#!/bin/bash

if [ $# -ne 1 ]; then
    echo "You must specify the name of the customer for which you want to perform the deployment."
    exit 1
fi

# Deployment procedure is customer specific related to configurations, so it takes customer name as input parameter
customerName=$1

# Load all customer-specific info needed for deployment
#source "/vagrant/infrastructure/aws/tenants/$customerName/config.sh"
MYSQL_HOST="localhost"
MYSQL_USER="root"
MYSQL_PASSWORD="Hdte731_32cdjkk"
MYSQL_JDBC="jdbc:mysql://${MYSQL_HOST}:3306/fbn_core";

echo "Migrate database for $customerName environment"
sql_path="/vagrant/database/FBN.CORE/createCoreDatabase.sql"
mysql -h ${MYSQL_HOST} -u ${MYSQL_USER} -p${MYSQL_PASSWORD} < $sql_path
chmod +x /vagrant/database/flyway-5.2.3/flyway
bash /vagrant/database/migrate-fbn-core.sh $MYSQL_JDBC $MYSQL_PASSWORD

echo "Inserting configuration parameters on '$customerName' environment ($MYSQL_HOST)"
sql_path=/vagrant/infrastructure/aws/tenants/$customerName/configuration.sql
mysql -u root -p"$MYSQL_PASSWORD" < $sql_path

echo "Deploy Import tool configuration"
customerConfiguration=/vagrant/infrastructure/aws/tenants/development/config.json # should be changed from development to $customerName, but there is no config.json currently for customers except for development
cp $customerConfiguration /vagrant/build/import-tool/config.json

echo 'Launch Import tool as a system service'
cat > /etc/systemd/system/importtool.service <<EOF
[Unit]
Description=Import tool
After=network.target

[Service]
WorkingDirectory=/vagrant/build/import-tool
ExecStart=/usr/bin/dotnet /vagrant/build/import-tool/ExcelProcessor.dll
Restart=on-failure
Type=simple

[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload
systemctl enable importtool
systemctl restart importtool

echo 'Launch FBN application as a system service'
mkdir -p /opt/fbn
echo "/bin/java -Djava.security.egd=file:/dev/./urandom -jar /vagrant/build/libs/fbn-webapp*.jar --spring.config.location=file:/vagrant/build/resources/main/application.properties" > /opt/fbn/start.sh
echo """kill -15 \`ps -eaf | grep java | grep fbn | awk '{print \$2}'\`""" > /opt/fbn/stop.sh
chmod +x /opt/fbn/*.sh
cat > /etc/systemd/system/fbnapp.service <<EOF
[Unit]
Description=FBN application
After=network.target

[Service]
ExecStart=/bin/bash /opt/fbn/start.sh
ExecStop=/bin/bash /opt/fbn/stop.sh
Restart=on-failure
Type=simple

[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload
systemctl enable fbnapp
systemctl restart fbnapp

# Update Nginx config and ensure service is running
/bin/cp -f /vagrant/infrastructure/aws/nginx-secure/proxy_params /etc/nginx/conf.d/
#/bin/cp -f /vagrant/infrastructure/aws/tenants/$customerName/nginx.conf /etc/nginx/conf.d/default.conf - for real customers
/bin/cp -f /vagrant/infrastructure/aws/tenants/local-dev/nginx.conf /etc/nginx/conf.d/default.conf # only for local development
systemctl start nginx
systemctl reload nginx
