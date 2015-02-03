#! /bin/sh

/usr/bin/mysql -h localhost -u mor --password=mor < /usr/src/mor/db/recreate_destinations/mor_recreate.sql

/usr/bin/mysql -h localhost -u mor --password=mor < /usr/src/mor/db/destinations.sql
/usr/bin/mysql -h localhost -u mor --password=mor < /usr/src/mor/db/destinationgroups.sql

