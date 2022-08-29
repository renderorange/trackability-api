# trackability-api

## DESCRIPTION

trackability-api is an API for storing and retrieving arbitrary JSON data.

I originally wrote this codebase with the purpose of deploying an API for various IoT devices around my house.

Its use isn't limited to IoT devices, but can be used for anything from storing server monitoring metrics, to daily mood/sleep data, to spending habits.  Anything you want to store, in the form of a JSON datastructure, can be stored and later retrieved for analysis.

There are several changes I'd like to make to this project, but several other projects that have taken priority in the meantime.  Given time, I may pick this back up again to continue development.  For now, please feel free to fork, deploy, modify to your heart and imagination's content.

## INSTALLATION

### install perl deps

```
Config::Tiny
constant
Cwd
Crypt::PBKDF2
Dancer2
Data::Structure::Util
DBI
Digest::SHA
Email::Valid
FindBin
Getopt::Long
HTTP::Status
JSON::Parse
List::MoreUtils
Moo
MooX::ClassAttribute
namespace::clean
Plack
Plack::Builder
Plack::Loader::Shotgun
Plack::Middleware::TrailingSlashKiller
Pod::Usage
Scalar::Util
Session::Storage::Secure
Starman
strictures
Term::ReadKey
Throwable::Error
Try::Tiny
Types::Common::Numeric
Types::Common::String
```

### setup the database and user

```
(generate a new password and use within the create_database_and_user.sql file)
# mysql < /home/trackability/git/trackability-api/db/create_database_and_user.sql
# mysql trackability < /home/trackability/git/trackability-api/db/schema.sql
```

### setup the trackability-apirc file

```
$ cp -a .trackability-apirc.example .trackability-apirc
$ vi .trackability-apirc
(update the database password to the newly generated one from setup)
(generate and store a new token secret_key and update in the file)
$ chmod 600 .trackability-apirc
```

### update and install the systemd file

```
# cp -a /home/trackability/git/trackability-api/app/trackability-api.service /etc/systemd/system/
# chown trackability:trackability trackability-api.service /etc/systemd/system/
# systemctl enable trackability-api
```

### create the log directory

```
# mkdir /var/log/trackability
# chown root.trackability /var/log/trackability
```

### add a vhost entry

(sample httpd.conf proxy and proxypass entry is included in the app dir)

### create a new user

```
~/git/trackability-api/bin$ perl add-user --name 'Blaine Motsinger' --email 'hello@blainem.com'
enter the password for hello@blainem.com:
```

### add a new API key for the new user

```
~/git/trackability-api/bin$ perl add-key --id 1
key: 2161747092~~write-it-down-and-keep-it-secret-keep-it-safe
```

## EXAMPLES

TODO

## LICENSE AND COPYRIGHT

trackability-api is Copyright (c) 2021 Blaine Motsinger under the MIT license.
