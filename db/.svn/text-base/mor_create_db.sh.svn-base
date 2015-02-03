#! /bin/sh

/usr/bin/mysql -h localhost -u root --password= < /usr/src/mor/db/init.sql
/usr/bin/mysql -h localhost -u mor --password=mor < /usr/src/mor/db/mor_db.sql

/usr/bin/mysql -h localhost -u mor --password=mor < /usr/src/mor/db/destinations.sql
/usr/bin/mysql -h localhost -u mor --password=mor < /usr/src/mor/db/destinationgroups.sql

/usr/bin/mysql -h localhost -u mor --password=mor < /usr/src/mor/db/update.sql
/usr/bin/mysql -h localhost -u mor --password=mor < /usr/src/mor/db/update06.sql

/usr/bin/mysql -h localhost -u mor --password=mor < /usr/src/mor/db/auto_dialer.sql

/usr/bin/mysql -h localhost -u mor --password=mor < /usr/src/mor/db/demo_tariffs.sql

