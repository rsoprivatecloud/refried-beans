refried-beans
=============

Dirty bash script to rebuild our lab.

USAGE:

./rfbeans.sh

This will remove all the Openstack related packages including the database and images/instances. It will then restore the lab to a prestine Opnestack environment. The controller node and all compute nodes will need to be rebooted after the script finishes running.
