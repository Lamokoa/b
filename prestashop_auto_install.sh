#!/bin/bash
# Script Instalasi PrestaShop Otomatis pada Ubuntu Server (AWS EC2)
# Oleh: Haikal Muttaqin & Vera Vinanjar Kusuma

# Konfigurasi Database
DB_NAME="prestashop"
DB_USER="psuser"
DB_PASSWORD="ps_password"
DB_HOST="localhost"

# Konfigurasi Admin PrestaShop
ADMIN_EMAIL="admin@prestashop.local"
ADMIN_PASSWORD="Admin123456"
SHOP_NAME="My PrestaShop"

# Dapatkan IP Public EC2
PUBLIC_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)

echo "=== Update dan Upgrade Sistem ==="
sudo apt update && sudo apt upgrade -y

echo "=== Instalasi Apache, MySQL, dan PHP ==="
sudo apt install apache2 mysql-server php libapache2-mod-php php-mysql php-zip php-intl php-curl php-gd php-mbstring php-xml php-cli php-json php-bcmath unzip curl -y

echo "=== Menghapus File Default Apache ==="
sudo rm -f /var/www/html/index.html

echo "=== Download dan Ekstrak PrestaShop ==="
cd /var/www/html
sudo wget https://github.com/PrestaShop/PrestaShop/releases/download/8.2.3/prestashop_8.2.3.zip
sudo unzip prestashop_8.2.3.zip
sudo rm prestashop_8.2.3.zip

# Ekstrak prestashop.zip yang ada di dalam
if [ -f "prestashop.zip" ]; then
    sudo unzip prestashop.zip
    sudo rm prestashop.zip
fi

echo "=== Mengatur Permission Direktori ==="
sudo chown -R www-data:www-data /var/www/html
sudo chmod -R 755 /var/www/html

echo "=== Membuat Konfigurasi Virtual Host ==="
sudo tee /etc/apache2/sites-available/prestashop.conf > /dev/null <<EOF
<VirtualHost *:80>
    ServerAdmin admin@prestashop.local
    DocumentRoot /var/www/html
    ServerName ${PUBLIC_IP}
    <Directory /var/www/html>
        AllowOverride All
        Require all granted
    </Directory>
    ErrorLog \${APACHE_LOG_DIR}/prestashop_error.log
    CustomLog \${APACHE_LOG_DIR}/prestashop_access.log combined
</VirtualHost>
EOF

echo "=== Mengaktifkan Konfigurasi dan Modul Rewrite ==="
sudo a2dissite 000-default.conf
sudo a2ensite prestashop.conf
sudo a2enmod rewrite
sudo systemctl restart apache2

echo "=== Konfigurasi MySQL ==="
sudo mysql -e "CREATE DATABASE IF NOT EXISTS ${DB_NAME};"
sudo mysql -e "CREATE USER IF NOT EXISTS '${DB_USER}'@'${DB_HOST}' IDENTIFIED BY '${DB_PASSWORD}';"
sudo mysql -e "GRANT ALL PRIVILEGES ON ${DB_NAME}.* TO '${DB_USER}'@'${DB_HOST}';"
sudo mysql -e "FLUSH PRIVILEGES;"

echo "=== Instalasi PrestaShop via CLI ==="
cd /var/www/html

# Jalankan instalasi otomatis menggunakan CLI PrestaShop
sudo -u www-data php install/index_cli.php \
    --domain="${PUBLIC_IP}" \
    --db_server="${DB_HOST}" \
    --db_name="${DB_NAME}" \
    --db_user="${DB_USER}" \
    --db_password="${DB_PASSWORD}" \
    --prefix="ps_" \
    --firstname="Admin" \
    --lastname="PrestaShop" \
    --password="${ADMIN_PASSWORD}" \
    --email="${ADMIN_EMAIL}" \
    --language="en" \
    --country="us" \
    --all_languages="0" \
    --newsletter="0" \
    --send_email="0"

echo "=== Menghapus Folder Install ==="
sudo rm -rf /var/www/html/install
sudo rm -rf /var/www/html/Install_PrestaShop.html

echo "=== Mengatur Permission Final ==="
sudo chown -R www-data:www-data /var/www/html
sudo chmod -R 755 /var/www/html

echo "=== Instalasi Selesai ==="
echo "============================================"
echo "PrestaShop berhasil diinstal!"
echo "URL Frontend: http://${PUBLIC_IP}"
echo "URL Admin: http://${PUBLIC_IP}/admin"
echo ""
echo "Kredensial Login Admin:"
echo "Email: ${ADMIN_EMAIL}"
echo "Password: ${ADMIN_PASSWORD}"
echo ""
echo "Informasi Database:"
echo "Database: ${DB_NAME}"
echo "User: ${DB_USER}"
echo "Password: ${DB_PASSWORD}"
echo "============================================"
echo ""
echo "PENTING: Ganti password admin setelah login pertama kali!"
echo "Folder /install sudah dihapus secara otomatis."
