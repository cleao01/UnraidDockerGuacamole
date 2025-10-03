Apache Guacamole is a clientless remote desktop gateway. It supports standard protocols like VNC, RDP, SSH, and Telnet.
This docker primarily has a MariaDB (MySQL) database built-in for authentication and configuration. It also has support for external database server (mysql, sqlserver or postgresql) and authentication providers: ldap, duo, totp, cas, openid, saml, ssl, json, header, quickconnect.
Thanks to HTML5, once Guacamole is installed on a server, all you need to access your desktops is a web browser.

For general usage of Apache Guacamole the full manual is located here: https://guacamole.apache.org/doc/gug/

The project is based on the work of Zuhkov zuhkov@gmail.com⁠, aptalca and Jason Bean, updated by cleao to latest version of guacamole.

All the required configuration for the authentication methods is provided by the template/environment variables. Internal MariaDB is the default authentication and configuration method if no external database server is specifyed in the EXTENSION_PRIORITY environment variable.
You can add additional configuration editing guacamole config file (/config/guacamole/guacamole.properties).
If using an external database server you must provide it with guacamole schema and an user, more info: https://guacamole.apache.org/doc/gug/jdbc-auth.html
In the option EXTENSION_PRIORITY you can add comma-separated list of external database server (mysql, sqlserver or postgresql) and authentication providers (ldap, duo, totp, cas, openid, saml, ssl, json, header, quickconnect) that should be acessed in specific order (don't specify "*" here). USE INTERNAL (MariaDB) IF ANY DATABASE SERVER IS SPECIFYED!
All other options are self explained or you can use the manual located here: https://guacamole.apache.org/doc/gug

Once the Guacamole image is running, will be accessible at: http://your-host-ip:8080 and login with user and password guacadmin

Apache Guacamole copyright The Apache Software Foundation, Licenced under the Apache License, Version 9.0.
This docker image is built upon the baseimage made by phusion and forked from hall/guacamole, and further forked from Zuhkov/docker-containers and then aptalca/docker-containers and then jason-bean/docker-guacamole