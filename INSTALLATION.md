# INSTALLATION

These instructions walk through a basic installation of the trackability-api application on Linux and will need:

- a modern version of Perl
- git
- MariaDB
- cpanminus
- Apache2

## install project files

All examples below assume the `trackability` user and group with a home directory of `/home/trackability`, cloned into the `git` directory.  Update the commands below if this user and directories don't apply for your install.

```
$ mkdir git
$ cd git
$ git clone https://github.com/renderorange/trackability-api.git
$ cd trackability-api
```

## install perl deps

The following dependencies can be installed using [cpanminus](https://metacpan.org/pod/App::cpanminus) which is available through the apt package manager on Debian and Ubuntu.

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
Throwable::Error
Try::Tiny
Types::Common::Numeric
Types::Common::String
```

```
$ cpanm Config::Tiny constant Cwd Crypt::PBKDF2 Dancer2 Data::Structure::Util DBI Digest::SHA Email::Valid FindBin Getopt::Long HTTP::Status JSON::Parse List::MoreUtils Moo MooX::ClassAttribute namespace::clean Plack Plack::Builder Plack::Loader::Shotgun Plack::Middleware::TrailingSlashKiller Pod::Usage Scalar::Util Session::Storage::Secure Starman strictures Throwable::Error Try::Tiny Types::Common::Numeric Types::Common::String
```

Dependencies can also be installed with [Carton](https://metacpan.org/pod/Carton) using the `cpanfile` located in the project root directory.

```
$ carton install
```

## setup the database and user

```
(generate a new password and use within the create_database_and_user.sql file)
# mysql < /home/trackability/git/trackability-api/db/create_database_and_user.sql
# mysql trackability < /home/trackability/git/trackability-api/db/schema.sql
```

## setup the trackability-apirc file

```
$ cp -a .trackability-apirc.example .trackability-apirc
$ vi .trackability-apirc
(update the database password to the newly generated one from setup)
(generate and store a new token secret_key and update in the file)
$ chmod 600 .trackability-apirc
```

## run the development server

To run this project using the included development server:

```
~/git/trackability-api (master) $ ./app/development
HTTP::Server::PSGI: Accepting connections at http://0:5000/
```

The development server listens by default over port 5000 on localhost and IPv4 interfaces.

## install as a running service

To setup this project running behind Apache2 as a frontend:

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

A sample httpd.conf proxy and proxypass entry is included in the app dir.  This isn't a complete apache vhost entry example, however.  Please setup the vhost accordingly for your apache configuration.

### start the service through systemctl and reload apache2

```
# systemctl start trackability-api
# systemctl reload apache2
```

## create a new user

```
~/git/trackability-api/bin $ perl add-user --name 'Blaine Motsinger' --email 'hello@blainem.com'
user 1 created
```

## add a new API key for the new user

```
~/git/trackability-api/bin $ perl add-key --id 1
key: 2161747092~~write-it-down-and-keep-it-secret-keep-it-safe
```
