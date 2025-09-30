Apache Guacamole 2in1
====

Dockerfile for Guacamole 1.6.0 with internal or external MariaDB server and  authentication providers: ldap, duo, totp, cas, openid, saml, ssl, json, header, quickconnect

2in1 because guacamole-server (guacd) and guacamole-client are in the same docker container

Apache Guacamole⁠ is a clientless remote desktop gateway. It supports standard protocols like VNC and RDP.
Clientless because no plugins or client software are required.
Thanks to HTML5, once Guacamole is installed on a server, all you need to access your desktops is a web browser.

---
Author
===

Based on the work of Zuhkov zuhkov@gmail.com⁠, aptalca and Jason Bean, updated by cleao to 1.6.0 version of guacamole

---
Running
===

Create your guacamole config directory (which will contain both the properties file and the database).

To run using internal MariaDB for user authentication, launch with the following:
```
docker run -d -v /your-config-location:/config -p 8080:8080 cleao/guacamole:1.0.0
```

---
Initializing the MySQL database
===

If using an external Mysql/MariaDB you must provide the database

To create and apply schema to an MariaDB external database:
Create a database for Guacamole within MySQL ex.: databasename

Run the script on the newly-created database:

docker exec -i MySQLDockerName sh -c 'mariadb -uroot -p"RootPassword" -e"CREATE DATABASE databasename"'
docker run --rm guacamole/guacamole /opt/guacamole/bin/initdb.sh --mysql | docker exec -i MySQLDockerName sh -c 'mariadb -uroot -p"RootPassword" databasename'

Use container Variable: EXTENSION_PRIORITY that is a comma-separated list of external database server (mysql, sqlserver or postgresql) 
and authentication providers (ldap, duo, totp, cas, openid, saml, ssl, json, header, quickconnect) that should be acessed in specific order. Use internal (MariaDB) if any external database chosen
Ex:
```
docker run -d -v /your-config-location:/config -p 8080:8080 -e EXTENSION_PRIORITY:mysql cleao/guacamole:1.0.0
```

Once the Guacamole image is running, Guacamole will be accessible at: http://your-host-ip:8080 and login with user and password `guacadmin`

---
Credits
===

Apache Guacamole copyright The Apache Software Foundation, Licenced under the Apache License, Version 9.0.
This docker image is built upon the baseimage made by phusion and forked from hall/guacamole, and further forked from Zuhkov/docker-containers and then aptalca/docker-containers and then jason-bean/docker-guacamole
