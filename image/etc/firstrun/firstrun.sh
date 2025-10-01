#!/bin/bash

EXT_STORE="/opt/guacamole"
GUAC_EXT="/config/guacamole/extensions"
TOMCAT_LOG="/config/log/tomcat"
CHANGES=false
JCONNECTOR="9.4.0"     #  https://dev.mysql.com/downloads/connector/j/
PCONNECTOR="42.7.8"    #  https://jdbc.postgresql.org/download
SCONNECTOR="13.2.0"    #  https://learn.microsoft.com/en-us/sql/connect/jdbc/download-microsoft-jdbc-driver-for-sql-server?view=sql-server-ver17

# Create user
PUID=${PUID:-99}
PGID=${PGID:-100}
groupmod -o -g "$PGID" abc
usermod -o -u "$PUID" abc
echo "----------------------"
echo "User UID: $(id -u abc)"
echo "User GID: $(id -g abc)"
echo "----------------------"
chown -R abc:abc /config
chown -R abc:abc /opt/tomcat /var/run/tomcat /var/lib/tomcat

# Retrieve environment variables
EXTENSIONPRIORITY="${EXTENSION_PRIORITY,,}"   # Convert to lower case
DATABASEHOSTNAME=${DATABASE_HOSTNAME%:*}
DATABASEPORT=${DATABASE_HOSTNAME##*:}
DATABASENAME=${DATABASE_NAME}
DATABASEUSERNAME=${DATABASE_USERNAME}
DATABASEPASSWORD=${DATABASE_PASSWORD}

LDAPHOSTNAME=${LDAP_HOSTNAME%:*}
LDAPPORT=${LDAP_HOSTNAME##*:}
LDAPUSERBASEDN=${LDAP_USER_BASE_DN}

DUOAPIHOSTNAME=${DUO_API_HOSTNAME}
DUOCLIENTID=${DUO_CLIENT_ID}
DUOCLIENTSECRET=${DUO_CLIENT_SECRET}
DUOREDIRECTURI=${DUO_REDIRECT_URI}

CASAUTHORIZATIONENDPOINT=${CAS_AUTHORIZATION_ENDPOINT}
CASREDIRECTURI=${CAS_REDIRECT_URI}

OPENIDAUTHORIZATIONENDPOINT=${OPENID_AUTHORIZATION_ENDPOINT}
OPENIDJWKSENDPOINT=${OPENID_JWKS_ENDPOINT}
OPENIDISSUER=${OPENID_ISSUER}
OPENIDCLIENTID=${OPENID_CLIENT_ID}
OPENIDREDIRECTURI=${OPENID_REDIRECT_URI}

SSLAUTHURI=${SSL_AUTH_PRIMARY_URI}
SSLAUTHPRIMARYURI=${SSL_AUTH_PRIMARY_URI}

JSONSECRETKEY=${JSON_SECRET_KEY}

RECORDINGSEARCHPATH=${RECORDING_SEARCH_PATH}

# 1st. run
if [ ! -f /config/guacamole/guacamole.properties ]; then
  echo "1st. run"
  mkdir -p "$GUAC_EXT" /config/guacamole/lib "$TOMCAT_LOG"
  cp /etc/firstrun/templates/* "$GUACAMOLE_HOME"
  chown -R abc:abc /config/guacamole "$TOMCAT_LOG"
  CHANGES=true
fi

# Preparing directory for recording storage - https://guacamole.apache.org/doc/gug/recording-playback.html#preparing-a-directory-for-recording-storage
if [ ! -n "${RECORDINGSEARCHPATH}" ]; then
  # Default path if environment variable is empty:
  RECORDINGSEARCHPATH="/config/recordings"
fi
echo "Session recordings will be stored in ""$RECORDINGSEARCHPATH"
if [ ! -d "$RECORDINGSEARCHPATH" ]; then
  mkdir -p "$RECORDINGSEARCHPATH"  
  chown abc:abc "$RECORDINGSEARCHPATH"
  chmod 2750 "$RECORDINGSEARCHPATH"
fi
sed -i '/recording-search-path:/c\recording-search-path: '$RECORDINGSEARCHPATH'' /config/guacamole/guacamole.properties

# Save guacamole.properties required configuration from environment variables
sed -i '/skip-if-unavailable:/c\skip-if-unavailable: '"$EXTENSIONPRIORITY"'' /config/guacamole/guacamole.properties
#  Don't specify any external database server, then use internal database
if ! ([[ "$EXTENSIONPRIORITY" =~ "mysql" ]] || [[ "$EXTENSIONPRIORITY" =~ "sqlserver" ]] || [[ "$EXTENSIONPRIORITY" =~ "postgresql" ]]); then
  # Check if database server type as changed from external or is 1st. run
  if [ ! -f /config/databases/guacamole/guacamole_user.ibd ]; then
    echo "Creating database folders"
    mkdir -p /config/databases
    chown abc:abc /config/databases
    PW=$(pwgen -1snc 32)
  else
    PW=$(cat /config/guacamole/guacamole.properties | grep -m 1 "mysql-password:\s" | sed 's/mysql-password:\s//')  
  fi
  sed -i '/extension-priority:/c\extension-priority: mysql,'"$EXTENSIONPRIORITY"'' /config/guacamole/guacamole.properties
  sed -i '/mysql-hostname:/c\mysql-hostname: 127.0.0.1' /config/guacamole/guacamole.properties
  sed -i '/mysql-port:/c\mysql-port: 3306' /config/guacamole/guacamole.properties
  sed -i '/mysql-database/c\mysql-database: guacamole' /config/guacamole/guacamole.properties
  sed -i '/mysql-username:/c\mysql-username: guacamole' /config/guacamole/guacamole.properties
  sed -i '/mysql-password:/c\mysql-password: '$PW'' /config/guacamole/guacamole.properties
else  #  External database
  # Check if database server type as changed from internal (MariaDB/Mysql)
  if [ -f /config/databases/guacamole/guacamole_user.ibd ]; then
    echo "Delete existing database: last run was internal MariaDB/Mysql related"
    rm -r /config/databases
  fi
  sed -i '/extension-priority:/c\extension-priority: '"$EXTENSIONPRIORITY"'' /config/guacamole/guacamole.properties  
  if [[ $EXTENSIONPRIORITY =~ "mysql" ]]; then
    # External MySQL/MariaDB database server
    sed -i '/mysql-hostname:/c\mysql-hostname: '$DATABASEHOSTNAME'' /config/guacamole/guacamole.properties
    sed -i '/mysql-port:/c\mysql-port: '$DATABASEPORT'' /config/guacamole/guacamole.properties
    sed -i '/mysql-database:/c\mysql-database: '$DATABASENAME'' /config/guacamole/guacamole.properties
    sed -i '/mysql-username:/c\mysql-username: '$DATABASEUSERNAME'' /config/guacamole/guacamole.properties
    sed -i '/mysql-password:/c\mysql-password: '$DATABASEPASSWORD'' /config/guacamole/guacamole.properties    
  else
    sed -i '/mysql-hostname:/c\#mysql-hostname:  DONT CHANGE!  automatically set by environment variable' /config/guacamole/guacamole.properties
    sed -i '/mysql-port:/c\#mysql-port:  DONT CHANGE!  automatically set by environment variable' /config/guacamole/guacamole.properties
    sed -i '/mysql-database:/c\#mysql-database:  DONT CHANGE!  automatically set by environment variable' /config/guacamole/guacamole.properties
    sed -i '/mysql-username:/c\#mysql-username:  DONT CHANGE!  automatically set by environment variable' /config/guacamole/guacamole.properties
    sed -i '/mysql-password:/c\#mysql-password:  DONT CHANGE!  automatically set by environment variable' /config/guacamole/guacamole.properties
  fi	
  if [[ "$EXTENSIONPRIORITY" =~ "sqlserver" ]]; then
    # External MSSQLServer database server
    sed -i '/sqlserver-hostname:/c\sqlserver-hostname: '$DATABASEHOSTNAME'' /config/guacamole/guacamole.properties
    sed -i '/sqlserver-port:/c\sqlserver-port: '$DATABASEPORT'' /config/guacamole/guacamole.properties
    sed -i '/sqlserver-database:/c\sqlserver-database: '$DATABASENAME'' /config/guacamole/guacamole.properties
    sed -i '/sqlserver-username:/c\sqlserver-username: '$DATABASEUSERNAME'' /config/guacamole/guacamole.properties
    sed -i '/sqlserver-password:/c\sqlserver-password: '$DATABASEPASSWORD'' /config/guacamole/guacamole.properties  
  else
    sed -i '/sqlserver-hostname:/c\#sqlserver-hostname:  DONT CHANGE!  automatically set by environment variable' /config/guacamole/guacamole.properties
    sed -i '/sqlserver-port:/c\#sqlserver-port:  DONT CHANGE!  automatically set by environment variable' /config/guacamole/guacamole.properties
    sed -i '/sqlserver-database:/c\#sqlserver-database:  DONT CHANGE!  automatically set by environment variable' /config/guacamole/guacamole.properties
    sed -i '/sqlserver-username:/c\#sqlserver-username:  DONT CHANGE!  automatically set by environment variable' /config/guacamole/guacamole.properties
    sed -i '/sqlserver-password:/c\#sqlserver-password:  DONT CHANGE!  automatically set by environment variable' /config/guacamole/guacamole.properties
  fi
  if [[ "$EXTENSIONPRIORITY" =~ "postgresql" ]]; then
    # External Postgresql database server
    sed -i '/postgresql-hostname:/c\postgresql-hostname: '$DATABASEHOSTNAME'' /config/guacamole/guacamole.properties
    sed -i '/postgresql-port:/c\postgresql-port: '$DATABASEPORT'' /config/guacamole/guacamole.properties
    sed -i '/postgresql-database:/c\postgresql-database: '$DATABASENAME'' /config/guacamole/guacamole.properties
    sed -i '/postgresql-username:/c\postgresql-username: '$DATABASEUSERNAME'' /config/guacamole/guacamole.properties
    sed -i '/postgresql-password:/c\postgresql-password: '$DATABASEPASSWORD'' /config/guacamole/guacamole.properties
  else
    sed -i '/postgresql-hostname:/c\#postgresql-hostname:  DONT CHANGE!  automatically set by environment variable' /config/guacamole/guacamole.properties
    sed -i '/postgresql-port:/c\#postgresql-port:  DONT CHANGE!  automatically set by environment variable' /config/guacamole/guacamole.properties
    sed -i '/postgresql-database:/c\#postgresql-database:  DONT CHANGE!  automatically set by environment variable' /config/guacamole/guacamole.properties
    sed -i '/postgresql-username:/c\#postgresql-username:  DONT CHANGE!  automatically set by environment variable' /config/guacamole/guacamole.properties
    sed -i '/postgresql-password:/c\#postgresql-password:  DONT CHANGE!  automatically set by environment variable' /config/guacamole/guacamole.properties
  fi
fi
if [[ "$EXTENSIONPRIORITY" =~ "ldap" ]]; then
  # External LDAP authentication
  sed -i '/ldap-hostname:/c\ldap-hostname: '$LDAPHOSTNAME'' /config/guacamole/guacamole.properties
  sed -i '/ldap-port:/c\ldap-port: '$LDAPPORT'' /config/guacamole/guacamole.properties
  sed -i '/ldap-user-base-dn:/c\ldap-user-base-dn: '$LDAPUSERBASEDN'' /config/guacamole/guacamole.properties
else
  sed -i '/ldap-hostname:/c\#ldap-hostname:  DONT CHANGE!  automatically set by environment variable' /config/guacamole/guacamole.properties
  sed -i '/ldap-port:/c\#ldap-port:  DONT CHANGE!  automatically set by environment variable' /config/guacamole/guacamole.properties
  sed -i '/ldap-user-base-dn:/c\#ldap-user-base-dn:  DONT CHANGE!  automatically set by environment variable' /config/guacamole/guacamole.properties
fi
if [[ "$EXTENSIONPRIORITY" =~ "duo" ]]; then
  # External DUO authentication
  sed -i '/duo-api-hostname:/c\duo-api-hostname: '$DUOAPIHOSTNAME'' /config/guacamole/guacamole.properties
  sed -i '/duo-client-id:/c\duo-client-id: '$DUOCLIENTID'' /config/guacamole/guacamole.properties
  sed -i '/duo-client-secret:/c\duo-client-secret: '$DUOCLIENTSECRET'' /config/guacamole/guacamole.properties
  sed -i '/duo-redirect-uri:/c\duo-redirect-uri: '$DUOREDIRECTURI'' /config/guacamole/guacamole.properties
else
  sed -i '/duo-api-hostname:/c\#duo-api-hostname:  DONT CHANGE!  automatically set by environment variable' /config/guacamole/guacamole.properties
  sed -i '/duo-client-id:/c\#duo-client-id:  DONT CHANGE!  automatically set by environment variable' /config/guacamole/guacamole.properties
  sed -i '/duo-client-secret:/c\#duo-client-secret:  DONT CHANGE!  automatically set by environment variable' /config/guacamole/guacamole.properties
  sed -i '/duo-redirect-uri:/c\#duo-redirect-uri:  DONT CHANGE!  automatically set by environment variable' /config/guacamole/guacamole.properties
fi
if [[ "$EXTENSIONPRIORITY" =~ "cas" ]]; then
  # External CAS authentication
  sed -i '/cas-authorization-endpoint:/c\cas-authorization-endpoint: '$CASAUTHORIZATIONENDPOINT'' /config/guacamole/guacamole.properties
  sed -i '/cas-redirect-uri:/c\cas-redirect-uri: '$CASREDIRECTURI'' /config/guacamole/guacamole.properties
else
  sed -i '/cas-authorization-endpoint:/c\#cas-authorization-endpoint:  DONT CHANGE!  automatically set by environment variable' /config/guacamole/guacamole.properties
  sed -i '/cas-redirect-uri:/c\#cas-redirect-uri:  DONT CHANGE!  automatically set by environment variable' /config/guacamole/guacamole.properties
fi
if [[ "$EXTENSIONPRIORITY" =~ "openid" ]]; then
  # External OPENID authentication
  sed -i '/openid-authorization-endpoint:/c\openid-authorization-endpoint: '$OPENIDAUTHORIZATIONENDPOINT'' /config/guacamole/guacamole.properties
  sed -i '/openid-jwks-endpoint:/c\openid-jwks-endpoint: '$OPENIDJWKSENDPOINT'' /config/guacamole/guacamole.properties
  sed -i '/openid-issuer:/c\openid-issuer: '$OPENIDISSUER'' /config/guacamole/guacamole.properties
  sed -i '/openid-client-id:/c\openid-client-id: '$OPENIDCLIENTID'' /config/guacamole/guacamole.properties
  sed -i '/openid-redirect-uri:/c\openid-redirect-uri: '$OPENIDREDIRECTURI'' /config/guacamole/guacamole.properties
else
  sed -i '/openid-authorization-endpoint:/c\#openid-authorization-endpoint:  DONT CHANGE!  automatically set by environment variable' /config/guacamole/guacamole.properties
  sed -i '/openid-jwks-endpoint:/c\#openid-jwks-endpoint:  DONT CHANGE!  automatically set by environment variable' /config/guacamole/guacamole.properties
  sed -i '/openid-issuer:/c\#openid-issuer:  DONT CHANGE!  automatically set by environment variable' /config/guacamole/guacamole.properties
  sed -i '/openid-client-id:/c\#openid-client-id:  DONT CHANGE!  automatically set by environment variable' /config/guacamole/guacamole.properties
  sed -i '/openid-redirect-uri:/c\#openid-redirect-uri:  DONT CHANGE!  automatically set by environment variable' /config/guacamole/guacamole.properties
fi
if [[ "$EXTENSIONPRIORITY" =~ "saml" ]]; then
  # External SAML authentication
  echo "SAML authentication must be manually configured in the file guacamole.properties:"
  echo "documentation: Apache Guacamole manual: https://guacamole.apache.org/doc/gug/saml-auth.html"
fi
if [[ "$EXTENSIONPRIORITY" =~ "ssl" ]]; then
  # External SSL authentication
  echo "SSL authentication have aditional Apache HTTP Server/Nginx configuration:"
  echo "documentation: Apache Guacamole manual: https://guacamole.apache.org/doc/gug/ssl-auth.html"  
  sed -i '/ssl-auth-uri:/c\ssl-auth-uri: '$SSLAUTHURI'' /config/guacamole/guacamole.properties
  sed -i '/ssl-auth-primary-uri:/c\ssl-auth-primary-uri: '$SSLAUTHPRIMARYURI'' /config/guacamole/guacamole.properties
else
  sed -i '/ssl-auth-uri:/c\#ssl-auth-uri:  DONT CHANGE!  automatically set by environment variable' /config/guacamole/guacamole.properties
  sed -i '/ssl-auth-primary-uri:/c\#ssl-auth-primary-uri:  DONT CHANGE!  automatically set by environment variable' /config/guacamole/guacamole.properties
fi
if [[ "$EXTENSIONPRIORITY" =~ "json" ]]; then
  # External JSON authentication
  echo "JSON authentication have aditional configuration (generate encrypted JSON):"
  echo "documentation: Apache Guacamole manual: https://guacamole.apache.org/doc/gug/json-auth.html"  
  sed -i '/json-secret-key:/c\json-secret-key: '$JSONSECRETKEY'' /config/guacamole/guacamole.properties
else
  sed -i '/json-secret-key:/c\#json-secret-key:  DONT CHANGE!  automatically set by environment variable' /config/guacamole/guacamole.properties
fi

# Install/uninstall needed extensions and connectors
# MYSQL/MARIADB
if ([[ "$EXTENSIONPRIORITY" =~ "mysql" ]]) || ( ! ([[ "$EXTENSIONPRIORITY" =~ "mysql" ]] || [[ "$EXTENSIONPRIORITY" =~ "sqlserver" ]] || [[ "$EXTENSIONPRIORITY" =~ "postgresql" ]] )); then
  # Check if MySQL extension file exists. Copy or upgrade if necessary.
  if [ -f "$GUAC_EXT"/*jdbc-mysql*.jar ]; then
    oldMysqlFiles=( "$GUAC_EXT"/*jdbc-mysql*.jar )
    newMysqlFiles=( "$EXT_STORE"/extensions/guacamole-auth-jdbc/mysql/*jdbc-mysql*.jar )
    if diff ${oldMysqlFiles[0]} ${newMysqlFiles[0]} >/dev/null ; then
      echo "Using existing MySQL extension and connector"
    else
      echo "Upgrading MySQL extension and connector"
      rm "$GUAC_EXT"/*jdbc-mysql*.jar
      cd /config/guacamole/lib
      rm mysql-connector*.jar
      cp "$EXT_STORE"/extensions/guacamole-auth-jdbc/mysql/*jdbc-mysql*.jar "$GUAC_EXT"
	  wget -q https://dev.mysql.com/get/Downloads/Connector-J/mysql-connector-j-${JCONNECTOR}.tar.gz
	  tar -xzf mysql-connector-j-${JCONNECTOR}.tar.gz
	  mv mysql-connector-j-${JCONNECTOR}/mysql-connector*.jar /config/guacamole/lib
	  rm -r mysql-connector-j-${JCONNECTOR}
	  rm mysql-connector-j-${JCONNECTOR}.tar.gz
      CHANGES=true
    fi
  else
    echo "Copying MySQL extension and connector"
    cp "$EXT_STORE"/extensions/guacamole-auth-jdbc/mysql/*jdbc-mysql*.jar "$GUAC_EXT"
    wget -q https://dev.mysql.com/get/Downloads/Connector-J/mysql-connector-j-${JCONNECTOR}.tar.gz
    tar -xzf mysql-connector-j-${JCONNECTOR}.tar.gz
    mv mysql-connector-j-${JCONNECTOR}/mysql-connector*.jar /config/guacamole/lib
    rm -r mysql-connector-j-${JCONNECTOR}
    rm mysql-connector-j-${JCONNECTOR}.tar.gz
    CHANGES=true
  fi
else
  # Delete MYSQL related files
  if [ -f "$GUAC_EXT"/*jdbc-mysql*.jar ]; then
    echo "Removing MySQL extension and connector"
    rm "$GUAC_EXT"/*jdbc-mysql*.jar
    cd /config/guacamole/lib
    rm mysql-connector*.jar
  fi
fi

# POSTGRESQL
if [[ "$EXTENSIONPRIORITY" =~ "postgresql" ]] ; then
  # Check if postgres SQL extension file exists. Copy or upgrade if necessary.
  if [ -f "$GUAC_EXT"/guacamole-auth-jdbc-postgresql.jar ]; then
    oldMysqlFiles=( "$GUAC_EXT"/guacamole-auth-jdbc-postgresql.jar )
    newMysqlFiles=( "$EXT_STORE"/extensions/guacamole-auth-jdbc/postgresql/guacamole-auth-jdbc-postgresql.jar )
    if diff ${oldMysqlFiles[0]} ${newMysqlFiles[0]} >/dev/null ; then
      echo "Using existing postgresql extension  and connector"
      CHANGES=true
    else
      echo "Upgrading postgresql extension and connector"
      rm "$GUAC_EXT"/guacamole-auth-jdbc-postgresql.jar
      cd /config/guacamole/lib
      rm postgresql-*.jar
      cp "$EXT_STORE"/extensions/guacamole-auth-jdbc/postgresql/guacamole-auth-jdbc-postgresql.jar "$GUAC_EXT"
	  wget -q https://jdbc.postgresql.org/download/postgresql-${PCONNECTOR}.jar
      mv postgresql-${PCONNECTOR}.jar /config/guacamole/lib
      CHANGES=true
    fi
  else
    echo "Copying postgresql extension and connector"
    cp "$EXT_STORE"/extensions/guacamole-auth-jdbc/postgresql/guacamole-auth-jdbc-postgresql.jar "$GUAC_EXT"
    wget -q https://jdbc.postgresql.org/download/postgresql-${PCONNECTOR}.jar
    mv postgresql-${PCONNECTOR}.jar /config/guacamole/lib
    CHANGES=true
  fi
else
  # Delete Postgresql related files
  if [ -f "$GUAC_EXT"/guacamole-auth-jdbc-postgresql.jar ]; then
    echo "Removing postgresql extension andconnector"
    rm "$GUAC_EXT"/guacamole-auth-jdbc-postgresql.jar
    cd /config/guacamole/lib
    rm postgresql-*.jar
  fi
fi

# MSSQL
if [[ "$EXTENSIONPRIORITY" =~ "sqlserver" ]]; then
  if [ -f "$GUAC_EXT"/*sqlserver*.jar ]; then
    oldSqlServerFiles=( "$GUAC_EXT"/*sqlserver*.jar )
    newSqlServerFiles=( "$EXT_STORE"/extensions/guacamole-auth-jdbc/sqlserver/*sqlserver*.jar )
    if diff ${oldSqlServerFiles[0]} ${newSqlServerFiles[0]} >/dev/null ; then
      echo "Using existing MSSQL Server extension and connector"
      CHANGES=true
    else
      echo "Upgrading MSSQL Server extension and connector"
      rm "$GUAC_EXT"/*sqlserver*.jar
      cd /config/guacamole/lib
      rm sqlserver-*.jar
      cp "$EXT_STORE"/extensions/guacamole-auth-jdbc/sqlserver/*sqlserver*.jar "$GUAC_EXT"
      wget -q https://github.com/microsoft/mssql-jdbc/releases/download/v${SCONNECTOR}/mssql-jdbc-${SCONNECTOR}.jre11.jar
      mv mssql-jdbc-*.jar /config/guacamole/lib
      CHANGES=true
    fi
  else
    echo "Copying MSSQL Server extension and connector"
    cp "$EXT_STORE"/extensions/guacamole-auth-jdbc/sqlserver/*sqlserver*.jar "$GUAC_EXT"
    wget -q https://github.com/microsoft/mssql-jdbc/releases/download/v${SCONNECTOR}/mssql-jdbc-${SCONNECTOR}.jre11.jar
    mv mssql-jdbc-*.jar /config/guacamole/lib	
    CHANGES=true
  fi
else
  if [ -f "$GUAC_EXT"/*sqlserver*.jar ]; then
    echo "Removing MSSQL Server extension and connector"
    rm "$GUAC_EXT"/*sqlserver*.jar
    cd /config/guacamole/lib
    rm mssql-jdbc-*.jar	
  fi
fi

#LDAP
if [[ "$EXTENSIONPRIORITY" =~ "ldap" ]]; then
  if [ -f "$GUAC_EXT"/*ldap*.jar ]; then
    oldLDAPFiles=( "$GUAC_EXT"/*ldap*.jar )
    newLDAPFiles=( "$EXT_STORE"/extensions/guacamole-auth-ldap/*ldap*.jar )
    if diff ${oldLDAPFiles[0]} ${newLDAPFiles[0]} >/dev/null ; then
    	echo "Using existing LDAP extension."
    else
    	echo "Upgrading LDAP extension."
    	rm "$GUAC_EXT"/*ldap*.jar
    	cp "$EXT_STORE"/extensions/guacamole-auth-ldap/*ldap*.jar "$GUAC_EXT"
      CHANGES=true
    fi
  else
    echo "Copying LDAP extension."
    cp "$EXT_STORE"/extensions/guacamole-auth-ldap/*ldap*.jar "$GUAC_EXT"
    CHANGES=true
  fi
else
  if [ -f "$GUAC_EXT"/*ldap*.jar ]; then
    echo "Removing LDAP extension."
    rm "$GUAC_EXT"/*ldap*.jar
  fi
fi

#DUO
if [[ "$EXTENSIONPRIORITY" =~ "duo" ]]; then
  if [ -f "$GUAC_EXT"/*duo*.jar ]; then
    oldDuoFiles=( "$GUAC_EXT"/*duo*.jar )
    newDuoFiles=( "$EXT_STORE"/extensions/guacamole-auth-duo/*duo*.jar )
    if diff ${oldDuoFiles[0]} ${newDuoFiles[0]} >/dev/null ; then
      echo "Using existing Duo extension."
    else
      echo "Upgrading Duo extension."
      rm "$GUAC_EXT"/*duo*.jar
      cp "$EXT_STORE"/extensions/guacamole-auth-duo/*duo*.jar "$GUAC_EXT"
      CHANGES=true
    fi
  else
    echo "Copying Duo extension."
    cp "$EXT_STORE"/extensions/guacamole-auth-duo/*duo*.jar "$GUAC_EXT"
    CHANGES=true
  fi
else
  if [ -f "$GUAC_EXT"/*duo*.jar ]; then
    echo "Removing Duo extension."
    rm "$GUAC_EXT"/*duo*.jar
  fi
fi

#TOTP
if [[ "$EXTENSIONPRIORITY" =~ "totp" ]]; then
  if [ -f "$GUAC_EXT"/*totp*.jar ]; then
    oldTotpFiles=( "$GUAC_EXT"/*totp*.jar )
    newTotpFiles=( "$EXT_STORE"/extensions/guacamole-auth-totp/*totp*.jar )
    if diff ${oldTotpFiles[0]} ${newTotpFiles[0]} >/dev/null ; then
      echo "Using existing TOTP extension."
    else
      echo "Upgrading TOTP extension."
      rm "$GUAC_EXT"/*totp*.jar
      cp "$EXT_STORE"/extensions/guacamole-auth-totp/*totp*.jar "$GUAC_EXT"
      CHANGES=true
    fi
  else
    echo "Copying TOTP extension."
    cp "$EXT_STORE"/extensions/guacamole-auth-totp/*totp*.jar "$GUAC_EXT"
    CHANGES=true
  fi
else
  if [ -f "$GUAC_EXT"/*totp*.jar ]; then
    echo "Removing TOTP extension."
    rm "$GUAC_EXT"/*totp*.jar
  fi
fi

#CAS
if [[ "$EXTENSIONPRIORITY" =~ "cas" ]]; then
  if [ -f "$GUAC_EXT"/*cas*.jar ]; then
    oldCasFiles=( "$GUAC_EXT"/*cas*.jar )
    newCasFiles=( "$EXT_STORE"/extensions/guacamole-auth-sso/cas/*cas*.jar )
    if diff ${oldCasFiles[0]} ${newCasFiles[0]} >/dev/null ; then
      echo "Using existing CAS extension."
    else
      echo "Upgrading CAS extension."
      rm "$GUAC_EXT"/*cas*.jar
      cp "$EXT_STORE"/extensions/guacamole-auth-sso/cas/*cas*.jar "$GUAC_EXT"
      CHANGES=true
    fi
  else
    echo "Copying CAS extension."
    cp "$EXT_STORE"/extensions/guacamole-auth-sso/cas/*cas*.jar "$GUAC_EXT"
    CHANGES=true
  fi
else
  if [ -f "$GUAC_EXT"/*cas*.jar ]; then
    echo "Removing CAS extension."
    rm "$GUAC_EXT"/*cas*.jar
  fi
fi

#OPENID
if [[ "$EXTENSIONPRIORITY" =~ "openid" ]]; then
  if [ -f "$GUAC_EXT"/*openid*.jar ]; then
    oldOpenidFiles=( "$GUAC_EXT"/*openid*.jar )
    newOpenidFiles=( "$EXT_STORE"/extensions/guacamole-auth-sso/openid/*openid*.jar )
    if diff ${oldOpenidFiles[0]} ${newOpenidFiles[0]} >/dev/null ; then
      echo "Using existing OpenID extension."
    else
      echo "Upgrading OpenID extension."
      rm "$GUAC_EXT"/*openid*.jar
      find ${EXT_STORE}/extensions/guacamole-auth-sso/openid/ -name "*.jar" | awk -F/ '{print $NF}' | xargs -I '{}' cp "${EXT_STORE}/extensions/guacamole-auth-sso/openid/{}" "${GUAC_EXT}/1-{}"
      CHANGES=true
    fi
  else
    echo "Copying OpenID extension."
    find ${EXT_STORE}/extensions/guacamole-auth-sso/openid/ -name "*.jar" | awk -F/ '{print $NF}' | xargs -I '{}' cp "${EXT_STORE}/extensions/guacamole-auth-sso/openid/{}" "${GUAC_EXT}/1-{}"
    CHANGES=true
  fi
else
  if [ -f "$GUAC_EXT"/*openid*.jar ]; then
    echo "Removing OpenID extension."
    rm "$GUAC_EXT"/*openid*.jar
  fi
fi

#SAML
if [[ "$EXTENSIONPRIORITY" =~ "saml" ]]; then
  if [ -f "$GUAC_EXT"/*saml*.jar ]; then
    oldQCFiles=( "$GUAC_EXT"/*saml*.jar )
    newQCFiles=( "$EXT_STORE"/extensions/guacamole-auth-sso/saml/*saml*.jar )
    if diff ${oldQCFiles[0]} ${newQCFiles[0]} >/dev/null ; then
      echo "Using existing SAML extension."
    else
      echo "Upgrading SAML extension."
      rm "$GUAC_EXT"/*saml*.jar
      cp "$EXT_STORE"/extensions/guacamole-auth-sso/saml/*saml*.jar "$GUAC_EXT"
      CHANGES=true
    fi
  else
    echo "Copying SAML extension."
    cp "$EXT_STORE"/extensions/guacamole-auth-sso/saml/*saml*.jar "$GUAC_EXT"
    CHANGES=true
  fi
else
  if [ -f "$GUAC_EXT"/*saml*.jar ]; then
    echo "Removing SAML extension."
    rm "$GUAC_EXT"/*saml*.jar
  fi
fi

#SSL
if [[ "$EXTENSIONPRIORITY" =~ "ssl" ]]; then
  if [ -f "$GUAC_EXT"/*ssl*.jar ]; then
    oldQCFiles=( "$GUAC_EXT"/*ssl*.jar )
    newQCFiles=( "$EXT_STORE"/extensions/guacamole-auth-sso/ssl/*ssl*.jar )
    if diff ${oldQCFiles[0]} ${newQCFiles[0]} >/dev/null ; then
      echo "Using existing SSL extension."
    else
      echo "Upgrading SSL extension."
      rm "$GUAC_EXT"/*ssl*.jar
      cp "$EXT_STORE"/extensions/guacamole-auth-sso/ssl/*ssl*.jar "$GUAC_EXT"
      CHANGES=true
    fi
  else
    echo "Copying SSL extension."
    cp "$EXT_STORE"/extensions/guacamole-auth-sso/ssl/*ssl*.jar "$GUAC_EXT"
    CHANGES=true
  fi
else
  if [ -f "$GUAC_EXT"/*ssl*.jar ]; then
    echo "Removing SSL extension."
    rm "$GUAC_EXT"/*ssl*.jar
  fi
fi

#JSON
if [[ "$EXTENSIONPRIORITY" =~ "json" ]]; then
  if [ -f "$GUAC_EXT"/*json*.jar ]; then
    oldQCFiles=( "$GUAC_EXT"/*json*.jar )
    newQCFiles=( "$EXT_STORE"/extensions/guacamole-auth-json/*json*.jar )
    if diff ${oldQCFiles[0]} ${newQCFiles[0]} >/dev/null ; then
      echo "Using existing json extension."
    else
      echo "Upgrading json extension."
      rm "$GUAC_EXT"/*json*.jar
      cp "$EXT_STORE"/extensions/guacamole-auth-json/*json*.jar "$GUAC_EXT"
      CHANGES=true
    fi
  else
    echo "Copying json extension."
    cp "$EXT_STORE"/extensions/guacamole-auth-json/*json*.jar "$GUAC_EXT"
    CHANGES=true
  fi
else
  if [ -f "$GUAC_EXT"/*json*.jar ]; then
    echo "Removing json extension."
    rm "$GUAC_EXT"/*json*.jar
  fi
fi

#HEADER
if [[ "$EXTENSIONPRIORITY" =~ "header" ]]; then
  if [ -f "$GUAC_EXT"/*header*.jar ]; then
    oldQCFiles=( "$GUAC_EXT"/*header*.jar )
    newQCFiles=( "$EXT_STORE"/extensions/guacamole-auth-header/*header*.jar )
    if diff ${oldQCFiles[0]} ${newQCFiles[0]} >/dev/null ; then
      echo "Using existing Header extension."
    else
      echo "Upgrading Header extension."
      rm "$GUAC_EXT"/*header*.jar
      cp "$EXT_STORE"/extensions/guacamole-auth-header/*header*.jar "$GUAC_EXT"
      CHANGES=true
    fi
  else
    echo "Copying Header extension."
    cp "$EXT_STORE"/extensions/guacamole-auth-header/*header*.jar "$GUAC_EXT"
    CHANGES=true
  fi
else
  if [ -f "$GUAC_EXT"/*header*.jar ]; then
    echo "Removing Header extension."
    rm "$GUAC_EXT"/*header*.jar
  fi
fi

#QUICKCONNECT
if [[ "$EXTENSIONPRIORITY" =~ "quickconnect" ]]; then
  if [ -f "$GUAC_EXT"/*quickconnect*.jar ]; then
    oldQCFiles=( "$GUAC_EXT"/*quickconnect*.jar )
    newQCFiles=( "$EXT_STORE"/extensions/guacamole-auth-quickconnect/*quickconnect*.jar )
    if diff ${oldQCFiles[0]} ${newQCFiles[0]} >/dev/null ; then
      echo "Using existing Quick Connect extension."
    else
      echo "Upgrading Quick Connect extension."
      rm "$GUAC_EXT"/*quickconnect*.jar
      cp "$EXT_STORE"/extensions/guacamole-auth-quickconnect/*quickconnect*.jar "$GUAC_EXT"
      CHANGES=true
    fi
  else
    echo "Copying Quick Connect extension."
    cp "$EXT_STORE"/extensions/guacamole-auth-quickconnect/*quickconnect*.jar "$GUAC_EXT"
    CHANGES=true
  fi
else
  if [ -f "$GUAC_EXT"/*quickconnect*.jar ]; then
    echo "Removing Quick Connect extension."
    rm "$GUAC_EXT"/*quickconnect*.jar
  fi
fi

# Session recording player extension will be always present
if [ -f "$GUAC_EXT"/*recording*.jar ]; then
  oldMysqlFiles=( "$GUAC_EXT"/*recording*.jar )
  newMysqlFiles=( "$EXT_STORE"/extensions/guacamole-history-recording-storage/*recording*.jar )
  if diff ${oldMysqlFiles[0]} ${newMysqlFiles[0]} >/dev/null ; then
    echo "Using existing session recording player extension"
  else
    echo "Upgrading session recording player extension"
    rm "$GUAC_EXT"/*recording*.jar
    cp "$EXT_STORE"/extensions/guacamole-history-recording-storage/*recording*.jar "$GUAC_EXT"
    CHANGES=true
  fi
else
  echo "Copying session recording player extension"
  cp "$EXT_STORE"/extensions/guacamole-history-recording-storage/*recording*.jar "$GUAC_EXT"	
  CHANGES=true
fi

if [ "$CHANGES" = true ]; then
  echo "Updating user permissions"
  chown abc:abc -R /config/guacamole
  chmod 755 -R /config/guacamole
else
  echo "No permissions changes needed"
fi

if ( ! ([[ "$EXTENSIONPRIORITY" =~ "mysql" ]] || [[ "$EXTENSIONPRIORITY" =~ "sqlserver" ]] || [[ "$EXTENSIONPRIORITY" =~ "postgresql" ]] )) && [ -f /etc/firstrun/mariadb.sh ]; then
  # Use internal database (MariaDB)
  /etc/firstrun/mariadb.sh
  exec /sbin/tini -s -- /usr/bin/supervisord -n -c /etc/supervisor/conf.d/supervisord-mariadb.conf
else
  # Use external database server, internal (MariaDB) is stopped to free resources
  exec /sbin/tini -s -- /usr/bin/supervisord -n -c /etc/supervisor/conf.d/supervisord.conf
fi
