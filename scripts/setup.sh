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

# Install Ruby 2.1.0
print_message 'Installing Ruby 2.1.0...'
execute_with_rbenv "rbenv install 2.1.0 ; rbenv global 2.1.0"

# Install Rails 4.1.0
print_message 'Installing Rails 4.1.0...'
execute_with_rbenv "gem install rails --version 4.1.0"

# Setup a blue prompt.
print_message "Setup prompt..."
echo 'export PS1="[\[\033[1;34m\]\u\[\033[0m\]@\h:\[\033[1;37m\]\w\[\033[0m\]]$ "' >> /home/vagrant/.bash_profile

# Setup hostname
print_message "Setup hostname..."
echo "hellocode" > /etc/hostname
echo "127.0.0.1 hellocode" >> /etc/hosts

print_message 'Done.'
