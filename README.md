Apache Guacamole is a clientless remote desktop gateway. It supports standard protocols like VNC, RDP, SSH, and Telnet.
This docker primarily has a MariaDB (MySQL) database built-in for authentication and configuration. It also has support for external database server (mysql, sqlserver or postgresql) and authentication providers: ldap, duo, totp, cas, openid, saml, ssl, json, header, quickconnect.
Thanks to HTML5, once Guacamole is installed on a server, all you need to access your desktops is a web browser.

For general usage of Apache Guacamole the full manual is located here: https://guacamole.apache.org/doc/gug/

The project is based on the work of Zuhkov zuhkov@gmail.com⁠, aptalca and Jason Bean, updated by cleao to latest version of guacamole.

All the required configuration for the authentication methods is provided by the template/environment variables. Internal MariaDB is the default authentication and configuration method if no external database server is specifyed in the EXTENSION_PRIORITY environment variable.
You can add additional configuration editing guacamole config file (/config/guacamole/guacamole.properties) but don't change the required parameters (see in manual) for authentication, they are automaticly filled by the docker template options/environment variables
If using an external database server (Mysql/MariaDB, Postgresql or MSSQLserver) you must provide it with guacamole schema and an user, more info: https://guacamole.apache.org/doc/gug/jdbc-auth.html
In the option EXTENSION_PRIORITY you can add comma-separated list of external database server (mysql, sqlserver or postgresql) and authentication providers (ldap, duo, totp, cas, openid, saml, ssl, json, header, quickconnect) that should be acessed in specific order (don't specify "*" here) - INTERNAL (MariaDB) IS USED IF ANY DATABASE SERVER IS SPECIFYED!
All other options are self explained or you can use the manual located here: https://guacamole.apache.org/doc/gug

Docker run example:
  docker run -d --name='Guacamole' --net='bridge' -e 'EXTENSION_PRIORITY'='' -e 'PUID'='99' -e 'PGID'='100' -p '8080:8080/tcp' -v 'watheverpathyouwant':'/config':'rw' 'cleao/guacamole'

Session recordings when properly configured in GUI will be stored in /config/recordings to be accessible outside docker.
Once the Guacamole image is running, will be accessible at: http://your-host-ip:8080 and login with user and password: guacadmin

Apache Guacamole copyright The Apache Software Foundation, Licenced under the Apache License, Version 9

..................

Environment variables:
---------------------
  EXTENSION_PRIORITY: Comma-separated list of external database server (mysql, sqlserver or postgresql) and authentication providers (ldap, duo, totp, cas, openid, saml, ssl, json, header, quickconnect) that should be acessed in specific order. Use internal (MariaDB) if any external database chosen,
  DATABASE_HOSTNAME: External database server name or IP adress:port,
  DATABASE_NAME: External database name,
  DATABASE_USERNAME: External database user name,
  DATABASE_PASSWORD: External database password,
  LDAP_HOSTNAME: External LDAP server name or IP adress, and port,
  LDAP_USER_BASE_DN: External LDAP user base dn,
  DUO_API_HOSTNAME: External duo api hostname,
  DUO_CLIENT_ID: External duo client id,
  DUO_CLIENT_SECRET: External duo client secret,
  DUO_REDIRECT_URI: External duo client uri,
  CAS_AUTHORIZATION_ENDPOINT: CAS authorization endpoint,
  CAS_REDIRECT_URI: CAS redirect uri,
  OPENID_AUTHORIZATION_ENDPOINT: OPENID authorization endpoint,
  OPENID_JWKS_ENDPOINT: OPENID jwks endpoint,
  OPENID_ISSUER: OPENID issuer,
  OPENID_CLIENT_ID: OPENID client id,
  OPENID_REDIRECT_URI; OPENID redirect uri,
  SSL_AUTH_URI: SSL auth uri,
  SSL_AUTH_PRIMARY_URI: SSL auth primary uri,
  JSON_SECRET_KEY: JSON secret key,
  PUID'='99',
  PGID'='100'
 
Container Path: /config: AppData Config Path
 
Internal port: 8080