#!/bin/bash

installer_dir=$(pwd)
echo "============================================================================"
echo "Installer PALAPA v03"
echo "============================================================================"
echo "Direktori installer adalah ${installer_dir}"
echo "============================================================================"
echo "Masukkan IP (contoh: 10.10.10.10) publik mesin ini: "
read ip_publik
echo "Masukkan domain (contoh: palapa.mesin.ini) publik mesin ini: "
read domain_publik
user_psql="palapa"
pass_psql="palapa"
echo "============================================================================"
echo "IP mesin: ${ip_publik}"
echo "Domain mesin: ${domain_publik}"
echo "User / Password Postgresql: ${user_psql} / ${pass_psql}"
echo "============================================================================"
echo "Tekan ENTER untuk lanjut."
read entering

# Installation Script (PALAPA)
echo "============================================================================"
echo "Menambahkan sumber paket"
rpm -iUvh http://dl.fedoraproject.org/pub/epel/7/x86_64/e/epel-release-7-9.noarch.rpm
rpm -iUvh http://yum.postgresql.org/9.5/redhat/rhel-7-x86_64/pgdg-centos95-9.5-2.noarch.rpm

echo "============================================================================"
echo "Memperbaharui sistem"
yum -y update

echo "============================================================================"
echo "Menambahkan paket"
yum -y install python-devel python-virtualenv git-core java-1.8.0-openjdk python-pip postgis2_95 postgis2_95-utils postgis2_95-client libpg-devel postgresql95-devel postgresql95-server xml-commons git subversion mercurial libxslt libxslt-devel libxml2 libxml2-devel gcc gcc-c++ make java-1.8.0-openjdk-devel tomcat tomcat-webapps tomcat-admin-webapps xalan-j2 unzip policycoreutils-python mod_wsgi httpd wget mc nano firewalld libtidy libtidy-devel gdal gdal-python gdal-devel

echo "============================================================================"
echo "Mengupgrade pip"
pip install --upgrade pip

echo "============================================================================"
echo "Menseting firewall"
systemctl enable firewalld
systemctl start firewalld
firewall-cmd --permanent --zone=public --add-port=8080/tcp
firewall-cmd --permanent --zone=public --add-port=80/tcp
firewall-cmd --permanent --zone=public --add-port=5432/tcp
firewall-cmd --permanent --zone=public --add-port=8800/tcp
firewall-cmd –-reload

echo "============================================================================"
echo "Menseting SELINUX ke mode permisive"
sed -ie 's/SELINUX=enforcing/SELINUX=permissive/g' /etc/selinux/config

echo "============================================================================"
echo "Menambahkan daemon ke startup"
systemctl enable httpd
systemctl enable tomcat
systemctl enable postgresql-9.5

echo "============================================================================"
echo "Mengkopi GeoServer"
geoserver_war="${installer_dir}/paket/geoserver.war"
cp ${geoserver_war} /var/lib/tomcat/webapps

# Tolong buka konsole satu lagi, selipan di /etc/tomcat/web.xml
echo "============================================================================"
echo "Menseting CORS Tomcat"
sed -ie "587i <filter>" /etc/tomcat/web.xml
sed -ie "588i <filter-name>CorsFilter</filter-name>" /etc/tomcat/web.xml   
sed -ie "589i <filter-class>org.apache.catalina.filters.CorsFilter</filter-class>" /etc/tomcat/web.xml   
sed -ie "590i <init-param>" /etc/tomcat/web.xml     
sed -ie "591i <param-name>cors.allowed.origins</param-name>" /etc/tomcat/web.xml     
sed -ie "592i <param-value>*</param-value>" /etc/tomcat/web.xml   
sed -ie "593i </init-param>" /etc/tomcat/web.xml 
sed -ie "594i </filter>" /etc/tomcat/web.xml 
sed -ie "595i <filter-mapping>" /etc/tomcat/web.xml   
sed -ie "596i <filter-name>CorsFilter</filter-name>" /etc/tomcat/web.xml   
sed -ie "597i <url-pattern>/*</url-pattern>" /etc/tomcat/web.xml 
sed -ie "598i </filter-mapping>" /etc/tomcat/web.xml
systemctl start tomcat

echo "============================================================================"
echo "Menseting PostgreSQL"
ln -s /usr/pgsql-9.5/bin/pg_config /usr/local/bin/
/usr/pgsql-9.5/bin/postgresql95-setup initdb

echo "============================================================================"
echo "Membuat direktori aplikasi"
mkdir -p /var/palapa/data
mkdir -p /var/palapa/store
mkdir -p /var/palapa/uploads
mkdir -p /var/palapa/downloads
mkdir -p /var/palapa/documents
chmod 777 /var/palapa/data
chmod 777 /var/palapa/store
chmod 777 /var/palapa/uploads
chmod 777 /var/palapa/downloads
chmod 777 /var/palapa/documents

echo "============================================================================"
echo "Menseting PostgreSQL (2)"
sed -ie "s/#listen_addresses = 'localhost'/listen_addresses = '*'/g" /var/lib/pgsql/9.5/data/postgresql.conf
sed -ie "s/#port = 5432/port = 5432/g" /var/lib/pgsql/9.5/data/postgresql.conf
sed -ie "s/max_connections = 100/max_connections = 1000/g" /var/lib/pgsql/9.5/data/postgresql.conf

sed -ie "s/local   all             all                                     peer/local   all             all                                     ident/g" /var/lib/pgsql/9.5/data/pg_hba.conf
sed -ie "s/host    all             all             127.0.0.1\/32            ident/host    all             all             127.0.0.1\/32            md5/g" /var/lib/pgsql/9.5/data/pg_hba.conf
sed -ie "/host    all             all             127.0.0.1\/32            md5/ i host    all             all             0.0.0.0\/0        md5" /var/lib/pgsql/9.5/data/pg_hba.conf

echo "============================================================================"
echo "Menyalakan PostgreSQL"
systemctl start postgresql-9.5

echo "============================================================================"
echo "Membuat database inisial"
cd /tmp
#su postgres -c "createuser -d -l -s palapa"
su postgres -c "psql -f ${installer_dir}/paket/palapa_user.sql" > /dev/null 2
su postgres -c "createdb -O palapa palapa -E utf-8"
su postgres -c "psql -d palapa -f /usr/pgsql-9.5/share/contrib/postgis-2.2/postgis.sql" > /dev/null 2
su postgres -c "psql -d palapa -f /usr/pgsql-9.5/share/contrib/postgis-2.2/spatial_ref_sys.sql" > /dev/null 2
su postgres -c "psql -d palapa -f /usr/pgsql-9.5/share/contrib/postgis-2.2/rtpostgis.sql" > /dev/null 2

su postgres -c "createdb -O palapa template_postgis_wraster -E utf-8"
su postgres -c "psql -d template_postgis_wraster -f /usr/pgsql-9.5/share/contrib/postgis-2.2/postgis.sql" > /dev/null 2
su postgres -c "psql -d template_postgis_wraster -f /usr/pgsql-9.5/share/contrib/postgis-2.2/spatial_ref_sys.sql" > /dev/null 2
su postgres -c "psql -d template_postgis_wraster -f /usr/pgsql-9.5/share/contrib/postgis-2.2/rtpostgis.sql" > /dev/null 2
su postgres -c "psql -d template_postgis_wraster -f /usr/pgsql-9.5/share/contrib/postgis-2.2/topology.sql" > /dev/null 2
su postgres -c "psql -d template_postgis_wraster -f /usr/pgsql-9.5/share/contrib/postgis-2.2/postgis_comments.sql" > /dev/null 2
su postgres -c "psql -d template_postgis_wraster -f /usr/pgsql-9.5/share/contrib/postgis-2.2/raster_comments.sql" > /dev/null 2
su postgres -c "psql -d template_postgis_wraster -f /usr/pgsql-9.5/share/contrib/postgis-2.2/topology_comments.sql" > /dev/null 2

su postgres -c "createdb -O palapa -T template_postgis_wraster palapa_dev"
su postgres -c "createdb -O palapa -T template_postgis_wraster palapa_prod"
su postgres -c "createdb -O palapa -T template_postgis_wraster palapa_pub"
su postgres -c "createdb -O palapa -T template_postgis_wraster ADMIN"
su postgres -c "createdb -O palapa -T template_postgis_wraster ADMIN_DEV"
su postgres -c "createdb -O palapa -T template_postgis_wraster template_palapa"


su postgres -c "pg_restore -d palapa_dev ${installer_dir}/paket/kugi_09_12_16.tar" > /dev/null 2>&1
su postgres -c "pg_restore -d palapa_prod ${installer_dir}/paket/kugi_09_12_16.tar" > /dev/null 2>&1
su postgres -c "pg_restore -d palapa_pub ${installer_dir}/paket/kugi_09_12_16.tar" > /dev/null 2>&1
su postgres -c "pg_restore -d template_palapa ${installer_dir}/paket/kugi_09_12_16.tar" > /dev/null 2>&1
su postgres -c "pg_restore -d ADMIN_DEV ${installer_dir}/paket/kugi_09_12_16.tar" > /dev/null 2>&1
su postgres -c "pg_restore -d palapa ${installer_dir}/paket/palapa_init_v5.backup" > /dev/null 2>&1

echo "============================================================================"
echo "Menseting berkas GeoServer"
chmod 777 /var/lib/tomcat/webapps/geoserver/data/security/layers.properties
chmod 777 /var/lib/tomcat/webapps/geoserver/data/security/services.properties

sed -ie 's/GET=ADMIN/GET=ADMIN,ADMINISTRATOR/g' /var/lib/tomcat/webapps/geoserver/data/security/rest.properties
sed -ie 's/POST,DELETE,PUT=ADMIN/POST,DELETE,PUT=ADMIN,ADMINISTRATOR/g' /var/lib/tomcat/webapps/geoserver/data/security/rest.properties

echo "============================================================================"
echo "Mengekstrak berkas aplikasi"
gspalapa_tarball="${installer_dir}/paket/gspalapa.tar.gz"
gspalapa_frontend_tarball="${installer_dir}/paket/gspalapa-frontend.tar.gz"
gspalapa_api_tarball="${installer_dir}/paket/gspalapa-api.tar.gz"
#pycsw_tarball "${installer_dir}/paket/pycsw.tar.gz"
tar -xzf ${gspalapa_tarball} -C /var/www/html/
tar -xzf ${gspalapa_frontend_tarball} -C /var/www/html/
mkdir -p /opt/gspalapa-api/
mkdir -p /opt/pycsw-2.0/
tar -xzf ${gspalapa_api_tarball} -C /opt/
#tar -xzf ${pycsw_tarball} /opt/pycsw/

echo "============================================================================"
echo "Menseting pygeometa"
cd /opt
git clone https://github.com/geopython/pygeometa.git 
cd pygeometa
pip install -r requirements.txt
python setup.py build
python setup.py install

echo "============================================================================"
echo "Menseting pycsw"
pip install pycsw
cd /opt/pycsw-2.0/
git clone https://github.com/geopython/pycsw.git 
cd /opt/pycsw-2.0/pycsw/
cp default-sample.cfg default.cfg
sed -ie "s/home=\/var\/www\/pycsw/home=\/opt\/pycsw-2.0\/pycsw/g" /opt/pycsw-2.0/pycsw/default.cfg
sed -ie "s/url=http:\/\/localhost\/pycsw\/csw.py/url=http:\/\/${domain_publik}\/csw/g" /opt/pycsw-2.0/pycsw/default.cfg
sed -ie "s/transactions=false/transactions=true/g" /opt/pycsw-2.0/pycsw/default.cfg
sed -ie "s/allowed_ips=127.0.0.1/allowed_ips=127.0.0.1,${ip_publik}/g" /opt/pycsw-2.0/pycsw/default.cfg
sed -ie "s/database=sqlite:\/\/\/\/var\/www\/pycsw\/tests\/suites\/cite\/data\/cite.db/#database=sqlite:\/\/\/\/var\/www\/pycsw\/tests\/suites\/cite\/data\/cite.db/g" /opt/pycsw-2.0/pycsw/default.cfg
sed -ie "s/#database=postgresql:\/\/username:password@localhost\/pycsw/database=postgresql:\/\/palapa:palapa@${ip_publik}\/palapa/g" /opt/pycsw-2.0/pycsw/default.cfg
sed -ie "s/table=records/table=metadata/g" /opt/pycsw-2.0/pycsw/default.cfg
# cd /opt/pycsw-2.0/pycsw/
# pycsw-admin.py -c setup_db -f default.cfg

echo "============================================================================"
echo "Menginstall dependencies GSPalapa API"
cd /opt/gspalapa-api
pip install -r requirement.txt

echo "============================================================================"
echo "Menseting GSPapala API"
sed -ie "s/\/mnt\/uploads\//\/var\/palapa\/uploads\//g" /opt/gspalapa-api/cfg.py
sed -ie "s/\/mnt\/data\//\/var\/palapa\/data\//g" /opt/gspalapa-api/cfg.py
sed -ie "s/\/mnt\/store\//\/var\/palapa\/store\//g" /opt/gspalapa-api/cfg.py
sed -ie "s/\/mnt\/docs\//\/var\/palapa\/documents\//g" /opt/gspalapa-api/cfg.py
sed -ie "s/\/mnt\/downloads\//\/var\/palapa\/downloads\//g" /opt/gspalapa-api/cfg.py
sed -ie "s/palapa.agrisoft-cb.com/${domain_publik}/g" /opt/gspalapa-api/cfg.py

echo "============================================================================"
echo "Mengkopikan konfigurasi HTTPd"
pycsw_conf="${installer_dir}/paket/pycsw.conf"
gspalapa_api="${installer_dir}/paket/gspalapa-api.conf"
cp ${pycsw_conf} /etc/httpd/conf.d/pycsw.conf
cp ${gspalapa_api} /etc/httpd/conf.d/gspalapa-api.conf

echo "============================================================================"
echo "Menseting aplikasi backend GSPalapa"
cd /var/www/html/gspalapa/js/
sed -ie "s/palapa.agrisoft-cb.com/${domain_publik}/g" /var/www/html/gspalapa/js/cfg.js

echo "============================================================================"
echo "Menseting aplikasi frontend GSPalapa"
cd /var/www/html/palapa/js/
sed -ie "s/palapa.agrisoft-cb.com/${domain_publik}/g" /var/www/html/palapa/js/main.js

echo "============================================================================"
echo "Menjalankan HTTPd"
systemctl start httpd

echo "============================================================================"
echo "Tolong restart server terlebih dahulu."
echo "============================================================================"
