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
execute_with_rbenv "gem install rails --version 4.1.0"

print_message "Do NOT forget to get the source code using the 'get-repositories' command."

print_message 'Done.'
