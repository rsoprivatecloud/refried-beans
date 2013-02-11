#!/bin/bash
 
# REFRIED BEANS
# 'soft' rekick a rcps environment
 

function do_dsh {

dsh -m localhost -g compute $*

}
 
echo "PURGING THE BEANS"
 
apt-get -y purge `dpkg -l | awk '/mysql/ {print $2}'` > /dev/null 2>&1
apt-get -y purge `dpkg -l | awk '/keystone/ {print $2}'` > /dev/null 2>&1
apt-get -y purge `dpkg -l | awk '/glance/ {print $2}'` > /dev/null 2>&1
 
rm -rf /root/.my.cnf
rm -rf /etc/mysql/grants.sql
rm -rf /var/lib/mysql
rm -rf /var/chef
rm -f /var/cache/local/preseeding/mysql-server.seed
rm -rf /etc/glance /var/lib/glance
rm -rf /etc/keystone
 
do_dsh apt-get -y purge `dpkg -l | awk '/nova/ {print $2}'` > /dev/null 2>&1
do_dsh rm -rfv /etc/nova /var/lib/nova/ /var/log/nova/ > /dev/null 2>&1
do_dsh apt-get -y autoremove > /dev/null 2>&1
 
do_dsh dpkg -P -a > /dev/null 2>&1
echo purge | debconf-communicate mysql-server-5.0 > /dev/null 2>&1
echo purge | debconf-communicate mysql-server-5.5 > /dev/null 2>&1
 
 
echo "REFRYING THE BEANS"
 
if [[ ! -d /opt/rpcs/chef-cookbooks ]] ; then
    git clone --depth 1 --recursive http://github.com/rcbops/chef-cookbooks.git /opt/rpcs/chef-cookbooks
fi
 
knife cookbook upload -ao /opt/rpcs/chef-cookbooks/cookbooks >/dev/null
knife role from file /opt/rpcs/chef-cookbooks/roles/*.rb >/dev/null


knife node list | egrep 'infra|novacpu|controller|compute' > /tmp/node_list.out 

for i in $(cat /tmp/node_list.out); do knife node delete -y $i; knife client delete -y $i; done >/dev/null

do_dsh rm -rf /etc/chef/client.pem

do_dsh chef-client >/dev/null

knife cookbook delete apt 1.8.4 -y >/dev/null

for i in $(egrep 'infra|controller' /tmp/node_list.out); do knife node run_list add $i 'role[single-controller]'; done >/dev/null

for i in $(egrep 'compute|novacpu' /tmp/node_list.out); do knife node run_list add $i 'role[single-compute]'; done >/dev/null


if ! chef-client | egrep  "Chef Run complete" 
then
  echo "Chef may not have run properly on $(hostname). Please run manually and fix."
fi

do_dsh 'if !  chef-client | egrep  "Chef Run complete"; then echo "Chef may not have run properly on $(hostname). Please run manually and fix."; fi'

mysqladmin flush-hosts

nova keypair-add --pub-key /root/.ssh/id_rsa.pub controller-id_rsa >/dev/null

mysql nova  -e 'UPDATE fixed_ips SET reserved=1 LIMIT 10' >/dev/null

echo "ENJOY YOUR BEANS AND BE SURE TO REBOOT ALL NODES"

