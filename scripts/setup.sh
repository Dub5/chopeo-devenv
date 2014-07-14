#!/bin/bash

####################################################################################################
# Hello Stores development environment.
#
# Sets up the specifics Ruby version, Rails gems and other requirements and adds some nice aliases
# and scripts to work with this specific project.
#
####################################################################################################

RUBY_VERSION=2.1.2
RAILS_VERSION=4.1.4
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
echo "hellocode" > /etc/hostname
echo "127.0.0.1 hellocode" >> /etc/hosts
hostname hellocode

# Setup environment
echo "Setup environment..."
`cat >/home/vagrant/.environment.sh <<\EOF
# Environment variables
export PS1="[\[\033[1;34m\]\u\[\033[0m\]@\h:\[\033[1;37m\]\w\[\033[0m\]]$ "

# Aliases to make our life easier.
alias get-repositories='bash /vagrant/scripts/get-repositories.sh'
alias goto-store='cd /vagrant/store'

alias store-recreate-db='bundle exec rake db:setup'
alias store-server='bundle exec rails server'
alias store-db='bundle exec rails dbconsole'
alias store-console='bundle exec rails console'

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

echo "Installing Ruby $RUBY_VERSION..."
execute_with_rbenv "rbenv install $RUBY_VERSION ; rbenv global $RUBY_VERSION"

echo "Installing Rails $RAILS_VERSION..."
execute_with_rbenv "gem install rails --version $RAILS_VERSION --no-document"

# Setup postgresql
echo "Setting up postgresql database..."
sudo -u postgres pg_dropcluster --stop $PG_VERSION main
sudo -u postgres pg_createcluster --start $PG_VERSION main
sudo -u postgres createuser -d -R -w -S vagrant

echo "#####################################################################################"
echo "# Welcome to the Hello-Stores project development environment!                       "
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
