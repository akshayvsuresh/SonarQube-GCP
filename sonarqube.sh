##Sonarqube Installation
sysctl -w vm.max_map_count=262144
sysctl -w fs.file-max=65536
ulimit -n 65536
ulimit -u 4096
cp ./limits.conf /etc/security/limits.conf
==================== limits.conf ========================
sonarqube   -   nofile   65536
sonarqube   -   nproc    4096
=========================================================
apt-get update -y
apt-get upgrade -y
apt-get install wget unzip -y
apt-get install openjdk-11-jdk -y
apt-get install openjdk-11-jre -y
update-alternatives --config java
java -version
#Step #2: Install and Setup PostgreSQL 10 Database For SonarQube
#Add and download the PostgreSQL Repo
sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt/ `lsb_release -cs`-pgdg main" >> /etc/apt/sources.list.d/pgdg.list'
wget -q https://www.postgresql.org/media/keys/ACCC4CF8.asc -O - | sudo apt-key add -
#Install the PostgreSQL database Server by using following command,
apt-get -y install postgresql postgresql-contrib
#Start PostgreSQL Database server
systemctl start postgresql
#Enable it to start automatically at boot time.
systemctl enable postgresql
#Change the password for the default PostgreSQL user.
usermod --password postgres postgres
#Switch to the postgres user.
su - postgres
#Create a new user by typing:
createuser sonar
#Switch to the PostgreSQL shell.
psql
#Set a password for the newly created user for SonarQube database.
ALTER USER sonar WITH ENCRYPTED password 'sonar';
#Create a new database for PostgreSQL database by running:
CREATE DATABASE sonarqube OWNER sonar;
#grant all privileges to sonar user on sonarqube Database.
grant all privileges on DATABASE sonarqube to sonar;
#Exit from the psql shell:
\q
#Switch back to the root user by running the exit command.
exit
#Step #3: How to Install SonarQube on Ubuntu 20.04 LTS
#Download sonaqube installer files archieve To download latest version of visit SonarQube download page.
cd /tmp
wget https://binaries.sonarsource.com/Distribution/sonarqube/sonarqube-9.0.0.45539.zip
unzip sonarqube-9.0.0.45539.zip -d /opt
mv /opt/sonarqube-9.0.0.45539/ /opt/sonarqube
#Step #4: Configure SonarQube
#We can’t run Sonarqube as a root user , if you run using root user it stops automatically.Solution on this to create saparate group and user to run sonarqube.
##1. Create Group and User: #Create a group as sonar
groupadd sonar
#Now add the user with directory access
useradd -c "user to run SonarQube" -d /opt/sonarqube -g sonar sonar 
chown sonar:sonar /opt/sonarqube -R
## Modify the following lines in /opt/sonarqube/conf/sonar.properties
sed -i s/#sonar.jdbc.username=/sonar.jdbc.username=sonar/g /opt/sonarqube/conf/sonar.properties
sed -i s/#sonar.jdbc.password=/sonar.jdbc.password=sonar/g /opt/sonarqube/conf/sonar.properties
sed -i 's/#sonar.jdbc.url=jdbc\:oracle\:thin\:\@localhost\:1521\/XE/sonar.jdbc.url=jdbc\:postgresql\:\/\/localhost\:5432\/sonarqube/g' /opt/sonarqube/conf/sonar.properties
sed -i s/#RUN_AS_USER=/RUN_AS_USER=sonar/g /opt/sonarqube/bin/linux-x86-64/sonar.sh
##2. Start Sonarqube
su sonar
cd /opt/sonarqube/bin/linux-x86-64/
./sonar.sh start
./sonar.sh status
##Step #5: Configure Systemd service
#First stop the SonarQube service as we started manually using above steps Navigate to the SonarQube installed path
cd /opt/sonarqube/bin/linux-x86-64/
./sonar.sh stop
exit 
cp ./sonar.service /etc/systemd/system/sonar.service
============================== sonar.service =========================
[Unit]
Description=SonarQube service
After=syslog.target network.target

[Service]
Type=forking

ExecStart=/opt/sonarqube/bin/linux-x86-64/sonar.sh start
ExecStop=/opt/sonarqube/bin/linux-x86-64/sonar.sh stop

User=sonar
Group=sonar
Restart=always

LimitNOFILE=65536
LimitNPROC=4096

[Install]
WantedBy=multi-user.target
======================================================================

systemctl start sonar
systemctl enable sonar
systemctl status sonar
:q
sleep 60;
##Step #6: Access SonarQube
curl http://localhost:9000
======================================================================
#To access the sonarqube from cloud shell

#Open cloud shell in GCP console -> Run below command 
#-> gcloud compute ssh $BASTION_NAME --zone=$ZONE -- -N -L 9000:localhost:9000
#-> For example: gcloud compute ssh gardenbp1-pa-dev-bastion-server-001 --zone=us-central1-a -- -N -L 9000:localhost:9000
#Click on web preview -> change port -> give 9000 -> Click on change and preview -> It'll open a new tab and you will see the SonarQube UI
