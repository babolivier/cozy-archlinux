#!/bin/sh -e
# postinst script for cozy
# Maintainer: Brendan Abolivier <brendan@cozycloud.cc>

# Fancy message is fancy
msg_blue() {
    printf "${blue}==>${bold} $1${all_off}\n"
}

all_off="$(tput sgr0)"
bold="${all_off}$(tput bold)"
blue="${bold}$(tput setaf 4)"

[ ! -d /usr/share/cozy ] && mkdir /usr/share/cozy
msg_blue "Downloading config file for Cozy Indexer"
wget -q https://raw.githubusercontent.com/cozy/cozy-debian/master/supervisor-cozy-indexer -O /usr/share/cozy/supervisor-cozy-indexer
msg_blue "Downloading config file for Cozy Controller"
wget -q https://raw.githubusercontent.com/cozy/cozy-debian/master/supervisor-cozy-controller -O /usr/share/cozy/supervisor-cozy-controller

COZY_DOMAIN=
msg_blue "Choose you Cozy's FQDN (fully-qualified domain name).
A self-signed certificate will be issued for this domain only, and the web server will configured with this domain name."
while [ -z $COZY_DOMAIN ]; do
    read -p "Domain name of your Cozy [cozy.example.tld]: " res 
    COZY_DOMAIN=$res                                                                                                                             
done

msg_blue "Chosen domain name for Cozy: $COZY_DOMAIN"

msg_blue 'Installing NPM dependencies...'
npm config set python /usr/bin/python2
[ ! -d /usr/local/lib/node_modules/cozy-controller ] && npm install -g cozy-controller
[ ! -d /usr/local/lib/node_modules/cozy-monitor ] && npm install -g cozy-monitor

msg_blue 'Creating UNIX users...'
id cozy >/dev/null 2>&1 || useradd -M cozy
id cozy-data-system >/dev/null 2>&1 || useradd -M cozy-data-system
id cozy-home >/dev/null 2>&1 || useradd -M cozy-home

[ ! -d /etc/cozy ] && mkdir /etc/cozy
chown -hR cozy /etc/cozy
if [ ! -f /etc/cozy/couchdb.login ]; then
    msg_blue 'Configuring CouchDB'
    systemctl enable couchdb
    systemctl start couchdb
    msg_blue 'Generating CouchDB tokens...'
    pwgen -1 > /etc/cozy/couchdb.login && \
    pwgen -1 >> /etc/cozy/couchdb.login
    while ! curl -s 127.0.0.1:5984 >/dev/null; do msg_blue "Waiting for CouchDB to start..."; sleep 5; done
    curl -s -X PUT 127.0.0.1:5984/_config/admins/$(head -n1 /etc/cozy/couchdb.login) -d "\"$(tail -n1 /etc/cozy/couchdb.login)\""
fi
chown cozy-data-system /etc/cozy/couchdb.login
chmod 640 /etc/cozy/couchdb.login

msg_blue 'Starting supervisor'
systemctl enable supervisord
systemctl start supervisord

msg_blue 'Configuring Cozy Indexer...'
COZY_INDEXER_DIRECTORY=/var/lib/cozy-indexer
if [ ! -d $COZY_INDEXER_DIRECTORY ]; then
    msg_blue "Creating $COZY_INDEXER_DIRECTORY"
    mkdir -p $COZY_INDEXER_DIRECTORY
fi
if [ "$(stat -c '%U:%G' $COZY_INDEXER_DIRECTORY)" != "cozy:cozy" ]; then
    msg_blue "Fixing $COZY_INDEXER_DIRECTORY owner"
    chown cozy:cozy $COZY_INDEXER_DIRECTORY
fi

CONFIGFILE=/etc/supervisor.d/cozy-indexer.ini
if [ -f $CONFIGFILE ]; then
    BEFORE=$(sha1sum $CONFIGFILE)
    EXISTING=true
else
    BEFORE=
    EXISTING=false
fi

CONFIGFILE=/usr/share/cozy/supervisor-cozy-indexer
AFTER=$(sha1sum $CONFIGFILE)
if [ "$BEFORE" != "$AFTER" ]; then
    if $EXISTING; then
        echo "Your configuration file for Cozy Indexer is different from the one included in this package:"
        diff /etc/supervisor.d/cozy-indexer.ini /usr/share/cozy/supervisor-cozy-indexer
        while true; do
            read -p "Do you want to install the new version? [Y/n] " yn
            case $yn in
                [Yy]* ) mv /etc/supervisor.d/cozy-indexer.ini /etc/supervisor.d/cozy-indexer.ini.old;
                        cp /usr/share/cozy/supervisor-cozy-indexer /etc/supervisor.d/cozy-indexer.ini;
                        echo "The old configuration file has been renamed as /etc/supervisor.d/cozy-indexer.ini.old"
                        break;;
                [Nn]* ) echo "The new configuration file is stored on /usr/share/cozy/supervisor-cozy-indexer"; break;;
                * ) echo "Please answer Yes or No."
            esac
        done
    else
        cp /usr/share/cozy/supervisor-cozy-indexer /etc/supervisor.d/cozy-indexer.ini
    fi
    supervisorctl reload
fi
while ! curl -s 127.0.0.1:9102/ >/dev/null; do msg_blue "Waiting for Cozy Indexer to start..."; sleep 5; done

msg_blue 'Configuring Cozy Controller...'
CONFIGFILE=/etc/supervisor.d/cozy-controller.ini
if [ -f $CONFIGFILE ]; then
    BEFORE=$(sha1sum $CONFIGFILE)
    EXISTING=true
else
    BEFORE=
    EXISTING=false
fi

CONFIGFILE=/usr/share/cozy/supervisor-cozy-controller
AFTER=$(sha1sum $CONFIGFILE)
if [ "$BEFORE" != "$AFTER" ]; then
    if $EXISTING; then
        echo "Your configuration file for Cozy Controller is different from the one included in this package:"
        diff /etc/supervisor.d/cozy-controller.ini /usr/share/cozy/supervisor-cozy-controller
        while true; do
            read -p "Do you want to install the new version? [Y/n] " yn
            case $yn in
                [Yy]* ) mv /etc/supervisor.d/cozy-controller.ini /etc/supervisor.d/cozy-controller.ini.old;
                        cp /usr/share/cozy/supervisor-cozy-controller /etc/supervisor.d/cozy-controller.ini;
                        echo "The old configuration file has been renamed as /etc/supervisor.d/cozy-controller.ini.old"
                        break;;
                [Nn]* ) echo "The new configuration file is stored on /usr/share/cozy/supervisor-cozy-controller"; break;;
                * ) msg_blue "Please answer Yes or No."
            esac
        done
    else
        cp /usr/share/cozy/supervisor-cozy-controller /etc/supervisor.d/cozy-controller.ini
    fi
    supervisorctl reload
fi
while ! curl -s 127.0.0.1:9102 >/dev/null; do msg_blue "Waiting for Cozy Controller to start..."; sleep 5; done

msg_blue 'Installing Cozy Platform apps...'
if [ ! -d /usr/local/cozy/apps/data-system ]; then
    cozy-monitor install-cozy-stack
fi
cozy-monitor start data-system
if [ ! -d /usr/local/cozy/apps/home ]; then
    cozy-monitor install home
fi
cozy-monitor start home
if [ ! -d /usr/local/cozy/apps/proxy ]; then
    cozy-monitor install proxy
fi
cozy-monitor start proxy

wget -q https://raw.githubusercontent.com/cozy/cozy-debian/master/cozy-get-instance-param.py -O /usr/share/cozy/cozy-get-instance-param.py

CURRENT_DOMAIN=`python2 /usr/share/cozy/cozy-get-instance-param.py domain`
if [ "$CURRENT_DOMAIN" = "$COZY_DOMAIN" ]; then
    msg_blue "Cozy already configured with domain: $COZY_DOMAIN"
else
    msg_blue "Configure Cozy with domain: $COZY_DOMAIN"
    coffee /usr/local/cozy/apps/home/commands.coffee setdomain $COZY_DOMAIN
fi

CURRENT_BACKGROUND=`python2 /usr/share/cozy/cozy-get-instance-param.py background`
if [ "$CURRENT_BACKGROUND" != "None" ]; then
    msg_blue "Cozy already configured with a background: $CURRENT_BACKGROUND"
else
    msg_blue "Configure Cozy with default background"
    curl -X POST http://localhost:9103/api/instance -H "Content-Type: application/json" -d '{"background":"background-07"}'
    echo ''
fi

msg_blue "Install default apps"
for app in calendar contacts photos emails files sync; do
    if [ ! -f /usr/local/cozy/apps/.first-install-$app ]; then
        if [ -d /usr/local/cozy/apps/$app ]; then
            touch /usr/local/cozy/apps/.first-install-$app
        else
            cozy-monitor install $app && touch /usr/local/cozy/apps/.first-install-$app
        fi
    fi
done

if [ ! -f /usr/local/cozy/apps/.first-install-import-from-google ]; then
    if [ -d /usr/local/cozy/apps/import-from-google ]; then
        touch /usr/local/cozy/apps/.first-install-import-from-google
    else
        cozy-monitor install import-from-google -r https://github.com/cozy-labs/import-from-google.git && touch /usr/local/cozy/apps/.first-install-import-from-google
    fi
fi

msg_blue 'Generating SSL keys and certificates...'
if [ ! -f /etc/cozy/dh.pem ]; then
    openssl dhparam -out /etc/cozy/dh.pem -outform PEM -2 2048
    chmod 400 /etc/cozy/dh.pem
fi
if [ ! -f /etc/cozy/server.key ]; then
    openssl req -x509 -nodes -newkey rsa:2048 -keyout /etc/cozy/server.key -out /etc/cozy/server.crt -days 3650 -subj "/CN=$COZY_DOMAIN"
    chmod 400 /etc/cozy/server.key
fi
-------------------------------------------------
if [ -d /etc/nginx ]; then
    msg_blue 'Configuring Nginx...'
    if [ -f /etc/nginx/sites-enabled/default ]; then
        rm /etc/nginx/sites-enabled/default
    fi
    msg_blue 'Downloading config file'
    wget -q https://raw.githubusercontent.com/cozy/cozy-debian/master/nginx-config -O /usr/share/cozy/nginx-config
    TMPFILE=`mktemp`
    CONFIGFILE=/etc/nginx/conf.d/cozy.conf
    if [ -f $CONFIGFILE ]; then
        BEFORE=`sha1sum $CONFIGFILE`
    else
        BEFORE=
    fi
    sed "s/%COZY_DOMAIN%/$COZY_DOMAIN/" /usr/share/cozy/nginx-config > $TMPFILE
    ucf --debconf-ok $TMPFILE $CONFIGFILE
    rm $TMPFILE
    AFTER=`sha1sum $CONFIGFILE`
    if [ "$BEFORE" != "$AFTER" ]; then
        service nginx status >/dev/null 2>&1 && service nginx reload
    fi
    nginx -t && msg_blue "Cozy installation done!"
fi
#--------------------------------------------------------------------------------
if [ -d /etc/nginx ]; then
    msg_blue 'Configuring Nginx...'
    # Do stuff    
elif [ -f /etc/httpd/conf/httpd.conf ]; then
    msg_blue 'Configuring Apache2...'
    wget -q https://raw.githubusercontent.com/cozy/cozy-debian/master/apache-config -O /usr/share/cozy/apache-config
    sed -i 's/apache2/httpd/' /usr/share/cozy/apache-config
    sed -i 's/\%COZY\_DOMAIN\%/'$COZY_DOMAIN'/' /usr/share/cozy/apache-config

    include=$(cat /etc/httpd/conf/httpd.conf | grep cozy)
    if [ ${#include} == 0 ]; then
        sed -i 's/#LoadModule\ ssl\_module\ modules\/mod\_ssl\.so/LoadModule\ ssl\_module\ modules\/mod\_ssl\.so/' /etc/httpd/conf/httpd.conf
	sed -i 's/Listen 80/Listen 80\nListen 443/' /etc/httpd/conf/httpd.conf
        echo -e '\n#Cozy configuration\nInclude conf/extra/cozy.conf' >> /etc/httpd/conf/httpd.conf
        cp /usr/share/cozy/apache-config /etc/httpd/conf/extra/cozy.conf
        systemctl reload httpd
    else
        CONFIGFILE=/etc/httpd/conf/extra/cozy.conf
        if [ -f $CONFIGFILE ]; then
            BEFORE=`sha1sum $CONFIGFILE`
        else
            BEFORE=
        fi

        CONFIGFILE=/usr/share/cozy/apache-config
        AFTER=`sha1sum $CONFIGFILE`
        if [ "$BEFORE" != "$AFTER" ]; then
            if $EXISTING; then
                echo "Your configuration file for Apache is different from the one included in this package:"
                diff /etc/httpd/conf/extra/cozy.conf /usr/share/cozy/apache-config
                while true; do
                    read -p "Do you want to install the new version? [Y/n] " yn
                    case $yn in
                        [Yy]* ) mv /etc/httpd/conf/extra/cozy.conf /etc/httpd/conf/extra/cozy.conf.old;
                                cp /usr/share/cozy/apache-config /etc/httpd/conf/extra/cozy.conf;
                                echo "The old configuration file has been renamed as /etc/httpd/conf/extra/cozy.conf.old"
                                break;;
                        [Nn]* ) echo "The new configuration file is stored on /usr/share/cozy/apache-config"; break;;
                        * ) msg_blue "Please answer Yes or No."
                    esac
                done
            else
                cp /usr/share/cozy/apache-config /etc/httpd/conf/extra/cozy.conf;
            fi
            systemctl reload httpd
        fi
    fi
else
	msg_blue 'No web serveur has been detected on your system.'
fi

exit 0
