#!/bin/bash

print_message() {
    tput setaf $1
    tput bold
    echo $2
    tput sgr0
}

download_repo() {
    if [ ! -d $1 ]; then
        print_message 6 "Cloning repository $2 on directory $1."
        git clone $2 $1
    else
        print_message 3 "Repository $2 already exists."
    fi
}

print_message 2 "Getting all project repositories."


## Add the project repositories after this line.

download_repo "/vagrant/store" "git@github.com:HelloCodeMX/hello-store.git"
download_repo "/vagrant/chopeo-front" "git@github.com:HelloCodeMX/chopeo-front.git"
