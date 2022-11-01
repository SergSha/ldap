#!/bin/bash
mkdir ./.ssh
ssh-keygen -t rsa -b 4096 -f ./.ssh/ipetrov -N ''
cp ./.ssh/ipetrov.pub ./ansible/roles/ldap/files/ -f
vagrant up
