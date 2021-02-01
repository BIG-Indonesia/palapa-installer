# palapa-installer

https://cloud.big.go.id/index.php/s/mjn2JAxEMebNxix

Silahkan download Installer Terbaru palapa V.3.4

Minimum Requirement :

O/S : Linux Centos 7 Minimal

sebelum melakukan instalasi palapa, terlebih dahulu insall kebutuhan paket
```
yum install epel-release python-pip unzip git tomcat nodejs postgresql96 postgresql96-server postgresql96-contrib postgresql96-libs httpd mod_wsgi
```

Jalankan service postgresql
```
/usr/pgsql-9.6/bin/postgresql96-setup initdb
systemctl enable postgresql-9.6.service
systemctl start postgresql-9.6.service
```

setelah download extract dan copy ke folder tmp didalam centos,

masuk ke folder installer hasil extract, jalankan command:
chmod +rx *.sh

masuk ke folder paket , cd paket , jalankan command:
chmod +rx *.sh

kemudia kembali ke folder installer:
cd ..


dilanjutkan dengan mengeksekusi file berikut :
./installer.sh

Ikuti langkah-langkah sesuai installer

-- Tim Dev Palapa --
