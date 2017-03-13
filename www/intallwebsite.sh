#!/bin/bash
cp -pr htdocs/* /var/www/
cp -pr cgi-bin/* /usr/lib/cgi-bin/
cp -p etc/* /etc/apache2/sites-available
a2ensite lights.level2.lu.conf
