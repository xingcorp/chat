## Step config on GCP

1. Create Load balancer server, default pool with private ip address of primary sql (i), add ssh key to metadata of Compute Engine
2. Create Pub/sub (ii)
3. Create Trigger, call to url at ```src/modules/sql-scaling/sql-scaling.controller.ts``` with `SQL_SCALING_REPLICA_TOKEN` (ii)
4. Create Alert Policy

## Setup for Load Balancer

1. Go to load balancer instance, install `node`
2. Go to `/etc/haproxy`
3. Copy `load-balancer.script.js` file
4. Create empty file `delete-instance.txt` with full permission `chmod -R 777`
5. Add cron tab by command `sudo crontab -e`: `* * * * * sudo node /etc/haproxy/load-balancer.script.js`

## Guide
i. https://www.youtube.com/watch?v=a_lW1Hz-IPU

ii. https://blog.searce.com/autoscaling-google-cloudsql-read-replicas-using-python-faf27282c007

## ENV for this feature

`SERVER_ENV` just ```production``` & ```staging``` will have this feature

`CLOUD_SQL_NETWORK` vpc of primary sql db (default)

`CLOUD_SQL_REGION` region of primary sql db

`CLOUD_SQL_DB_VERSION` version of primary sql db (POSTGRES_11)

`CLOUD_SQL_PRIMARY_NAME` name of primary sql db

`CLOUD_SQL_PRIMARY_IP` private ip of primary sql db

`CLOUD_SQL_REPLICA_INSTANCE_CPU` cpu of replica

`CLOUD_SQL_REPLICA_INSTANCE_RAM` ram of replica

`SQL_SCALING_REPLICA_TOKEN` token for trigger api

`PUB_SUB_NOTIFY_CREATE_REPLICA_INSTANCE` create at step (2)

`PUB_SUB_NOTIFY_REMOVE_REPLICA_INSTANCE` create at step (2)

`GCE_SSH_PUBLIC_KEY` ssh add at step (1)

`GCE_SSH_PRIVATE_KEY` ssh add at step (1), just body of it, not have --Begin-- & --End--

`GCE_SSH_USER_NAME` ssh add at step (1)

`GCE_LOAD_BALANCER_INSTANCE_HOST` public ip of load balancer server

`GCE_LOAD_BALANCER_INSTANCE_PRIVATE_IP` private ip of load balancer server