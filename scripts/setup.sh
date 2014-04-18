#!/bin/bash

print_message () {
    tput setaf 3
    tput bold
    echo $1
    tput sgr0
}

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

# Setup requirements
print_message 'Setting up requirements...'
apt-get -y install libpq-dev

# Setup hostname
print_message "Setup hostname..."
echo "hellocode" > /etc/hostname
echo "127.0.0.1 hellocode" >> /etc/hosts
hostname hellocode

# Setup environment
print_message "Setup environment..."
`cat >/home/vagrant/.environment.sh <<\EOF
# Environment variables
export PS1="[\[\033[1;34m\]\u\[\033[0m\]@\h:\[\033[1;37m\]\w\[\033[0m\]]$ "

# Aliases to make our life easier.
alias restart_server='rake db:drop; rake db:create; rake db:migrate; rails server'
alias recreate_db='rake db:drop; rake db:create: rake db:migrate'
alias get-repositories='bash /vagrant/scripts/get-repositories.sh'
alias goto-store='cd /vagrant/store'

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

# Install Ruby 2.1.0
print_message 'Installing Ruby 2.1.0...'
execute_with_rbenv "rbenv install 2.1.0 ; rbenv global 2.1.0"

# Install Rails 4.1.0
print_message 'Installing Rails 4.1.0...'
execute_with_rbenv "gem install rails --version 4.1.0 --no-document"

# Setup postgresql
print_message "Setting up postgresql database..."
sudo -u postgres createuser -d -R -w -S vagrant
sudo -u postgres createdb -O vagrant stores

print_message "####################################################################################################"
print_message "# Welcome to the Hello-Stores project development environment!                                      "
print_message "#                                                                                                   "
print_message "# You are not yet done! You need to do the following to finish the setup:                           "
print_message "# 1) Get all the project repositories:                                                              "
print_message "#    Run: get-repositories                                                                          "
print_message "# 2) Get all the Rails project gems:                                                                "
print_message "#    Run: goto-store; bundle install                                                                "
print_message "# 3) Set up the application API keys. Put them in ~/.secret_keys.sh                                 "
print_message "#                                                                                                   "
print_message "# Info:                                                                                             "
print_message "# PostreSQL user 'vagrant' created without password. 'stores' database created.                     "
print_message "#                                                                                                   "
print_message "####################################################################################################"
