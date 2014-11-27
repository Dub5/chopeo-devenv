#!/bin/bash

####################################################################################################
# Chopeo development environment.
#
# Sets up the specifics Ruby version, Rails gems and other requirements and adds some nice aliases
# and scripts to work with this specific project.
#
####################################################################################################

RUBY_VERSION=2.1.5
RAILS_VERSION=4.1.8
PG_VERSION=9.3

####################################################################################################

execute_with_rbenv () {
    `cat >/home/vagrant/temp-script.sh <<\EOF
export HOME=/home/vagrant
if [ -d $HOME/.rbenv ]; then
  export PATH="$HOME/.rbenv/bin:$PATH"
  eval "$(rbenv init -)"
fi

EOF
`
    echo $1 >> /home/vagrant/temp-script.sh
    chmod +x /home/vagrant/temp-script.sh
    su vagrant -c "bash -c /home/vagrant/temp-script.sh"
    rm /home/vagrant/temp-script.sh
}

export DEBIAN_FRONTEND=noninteractive

# Setup hostname
echo "Setup hostname..."
echo "chopeo" > /etc/hostname
echo "127.0.0.1 chopeo" >> /etc/hosts
hostname chopeo

# Setup environment
echo "Setup environment..."
`cat >/home/vagrant/.environment.sh <<\EOF
# Environment variables
export PS1="[\[\033[1;34m\]\u\[\033[0m\]@\h:\[\033[1;37m\]\w\[\033[0m\]]$ "

# Aliases to make our life easier.
alias get-repositories='bash /vagrant/scripts/get-repositories.sh'
alias store='cd /vagrant/chopeo-store'
alias landing='cd /vagrant/chopeo-landing'

alias store-recreate-db='bundle exec rake db:setup'
alias store-server='bundle exec rails server'
alias store-db='bundle exec rails dbconsole'
alias store-console='bundle exec rails console'
alias store-restart='touch /vagrant/chopeo-store/tmp/restart.txt'

# Load secret keys, if any.
if [ -f ~/.secret_keys.sh ]; then
  source ~/.secret_keys.sh
fi

EOF
`

echo 'source ~/.environment.sh' >> /home/vagrant/.bash_profile

touch /home/vagrant/.secret_keys.sh

chown vagrant:vagrant /home/vagrant/.environment.sh
chown vagrant:vagrant /home/vagrant/.secret_keys.sh

# Upgrade rbenv
`cat >/home/vagrant/upgrade_rbenv.sh <<\EOF
cd ~/.rbenv
git pull
cd ~/.rbenv/plugins/ruby-build
git pull
EOF
`
chmod +x /home/vagrant/upgrade_rbenv.sh
su vagrant -c "bash -c /home/vagrant/upgrade_rbenv.sh"
rm /home/vagrant/upgrade_rbenv.sh

echo "Installing Ruby $RUBY_VERSION..."
execute_with_rbenv "rbenv install $RUBY_VERSION ; rbenv global $RUBY_VERSION"

echo "Installing Rails $RAILS_VERSION..."
execute_with_rbenv "gem install rails --version $RAILS_VERSION --no-document"

# Setup postgresql
echo "Setting up postgresql database..."
sudo -u postgres pg_dropcluster --stop $PG_VERSION main
sudo -u postgres pg_createcluster --start $PG_VERSION main
sudo -u postgres createuser -d -R -w -S vagrant
perl -i -p -e 's/local   all             all                                     peer/local all all trust/' /etc/postgresql/9.3/main/pg_hba.conf

`cat >/etc/nginx/sites-available/chopeo-landing <<\EOF
server {
    listen 3000 default_server;
    listen 3443 ssl default_server;

    ssl_certificate     /vagrant/certificate/nginx.crt;
    ssl_certificate_key /vagrant/certificate/nginx.key;

    server_name www.lvh.me lvh.me;

    root    /vagrant/chopeo-landing/;
}
EOF
`

`cat >/etc/nginx/sites-available/chopeo-help <<\EOF
server {
    listen 3000;
    listen 3443 ssl;

    ssl_certificate     /vagrant/certificate/nginx.crt;
    ssl_certificate_key /vagrant/certificate/nginx.key;

    server_name help.lvh.me ayuda.lvh.me;

    root    /vagrant/chopeo-help/;
}
EOF
`

`cat >/etc/nginx/sites-available/chopeo-stores <<\EOF
server {
    server_name *.lvh.me;

    listen 3000;
    listen 3443 ssl;

    ssl_certificate     /vagrant/certificate/nginx.crt;
    ssl_certificate_key /vagrant/certificate/nginx.key;

    client_max_body_size 10M;

    passenger_enabled on;

    rails_env    development;
    root         /vagrant/chopeo-store/public;

    # redirect server error pages to the static page /50x.html
    error_page   500 502 503 504  /50x.html;
    location = /50x.html {
        root   html;
    }
}
EOF
`

perl -i -p -e 's/# passenger_root \/usr\/lib\/ruby\/vendor_ruby\/phusion_passenger\/locations\.ini\;\n/passenger_root \/usr\/lib\/ruby\/vendor_ruby\/phusion_passenger\/locations.ini;\n\tpassenger_ruby \/home\/vagrant\/.rbenv\/shims\/ruby;\n/' /etc/nginx/nginx.conf

ln -s /etc/nginx/sites-available/chopeo-landing /etc/nginx/sites-enabled/chopeo-landing
ln -s /etc/nginx/sites-available/chopeo-stores /etc/nginx/sites-enabled/chopeo-stores
ln -s /etc/nginx/sites-available/chopeo-help /etc/nginx/sites-enabled/chopeo-help
rm /etc/nginx/sites-enabled/default

service nginx restart
service postgresql restart

echo "#####################################################################################"
echo "# Welcome to the Chopeo project development environment!                             "
echo "#                                                                                    "
echo "# You are not yet done! You need to do the following to finish the setup:            "
echo "# 1) Get all the project repositories:                                               "
echo "#    Run: get-repositories                                                           "
echo "# 2) Get all the Rails project gems:                                                 "
echo "#    Run: goto-store; bundle install                                                 "
echo "# 3) Set up the application API keys. Put them in ~/.secret_keys.sh                  "
echo "#                                                                                    "
echo "# Info:                                                                              "
echo "# PostreSQL user 'vagrant' created without password. 'stores' database created.      "
echo "#                                                                                    "
echo "#####################################################################################"
