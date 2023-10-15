# trackability-api

## DESCRIPTION

trackability-api is an API for storing and retrieving arbitrary JSON data.

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
user 1 created
```

### add a new API key for the new user

```
~/git/trackability-api/bin$ perl add-key --id 1
key: 2161747092~~write-it-down-and-keep-it-secret-keep-it-safe
```

## EXAMPLES

### run the development server

```
~/git/trackability-api (master) $ ./app/development
HTTP::Server::PSGI: Accepting connections at http://0:5000/
```

### Add a collection

```
POST /collections
```

```
$ curl -X POST -H 'Content-Type: application/json' -H "Authorization: Token $TOKEN" -d '{"name":"example collection"}' localhost:5000/collections
{
   "name" : "example collection",
   "id" : 6,
   "users_id" : 1,
   "updated_at" : 1697403162,
   "created_at" : 1697403162
}
```

### Get collections

```
GET /collections
```

```
$ curl -X GET -H 'Content-Type: application/json' -H "Authorization: Token $TOKEN" localhost:5000/collections
[
   {
      "name" : "example collection",
      "users_id" : 1,
      "id" : 6,
      "created_at" : 1697403162,
      "updated_at" : 1697403162
   },
   {
      "name" : "another example collection",
      "users_id" : 1,
      "id" : 7,
      "created_at" : 1697403394,
      "updated_at" : 1697403394
   }
]
```

### Get collection

```
GET /collections/:collections_id
```

```
$ curl -X GET -H 'Content-Type: application/json' -H "Authorization: Token $TOKEN" localhost:5000/collections/6
{
   "name" : "example collection",
   "updated_at" : 1697403162,
   "created_at" : 1697403162,
   "id" : 6,
   "users_id" : 1
}
```

### Update a collection

```
PUT /collections/:collections_id
```

```
$ curl -X PUT -H 'Content-Type: application/json' -H "Authorization: Token $TOKEN" -d '{"name":"updated example collection"}' localhost:5000/collections/6
{
   "updated_at" : 1697403559,
   "created_at" : 1697403162,
   "users_id" : 1,
   "id" : 6,
   "name" : "updated example collection"
}
```

### Add an event

```
POST /collections/:collections_id/events
```

```
$ curl -X POST -H 'Content-Type: application/json' -H "Authorization: Token $TOKEN" -d '{"one":1, "two":2}' localhost:5000/collections/6/events
{
   "id" : 4,
   "updated_at" : 1697403750,
   "created_at" : 1697403750,
   "collections_id" : 6
}
```

### Get events

```
GET /collections/:collections_id/events
```

```
$ curl -X GET -H 'Content-Type: application/json' -H "Authorization: Token $TOKEN" localhost:5000/collections/6/events
[
   {
      "collections_id" : 6,
      "data" : {
         "one" : 1,
         "two" : 2
      },
      "updated_at" : 1697403750,
      "created_at" : 1697403750,
      "id" : 4
   },
   {
      "collections_id" : 6,
      "id" : 5,
      "data" : {
         "two" : 2,
         "one" : 1
      },
      "updated_at" : 1697403807,
      "created_at" : 1697403807
   }
]
```

### Get event

```
GET /collections/:collections_id/events/:events_id
```

```
$ curl -X GET -H 'Content-Type: application/json' -H "Authorization: Token $TOKEN" localhost:5000/collections/6/events/4
{
   "data" : {
      "one" : 1,
      "two" : 2
   },
   "updated_at" : 1697403750,
   "created_at" : 1697403750,
   "id" : 4,
   "collections_id" : 6
}
```

### Get user

```
GET /users/:users_id
```

```
$ curl -X GET -H 'Content-Type: application/json' -H "Authorization: Token $TOKEN" localhost:5000/users/1
{
   "id" : 1,
   "updated_at" : 1697309103,
   "created_at" : 1697309103,
   "name" : "Blaine Motsinger",
   "email" : "hello@blainem.com"
}
```

### Update user

```
PUT /users/:users_id
```

```
$ curl -X PUT -H 'Content-Type: application/json' -H "Authorization: Token $TOKEN" -d '{"name":"Test Testerton","email":"test@testerton.com"}' localhost:5000/users/1
{
   "id" : 1,
   "created_at" : 1697405257,
   "updated_at" : 1697405304,
   "name" : "Test Testerton",
   "email" : "test@testerton.com"
}
```

## LICENSE AND COPYRIGHT

trackability-api is Copyright (c) 2021 Blaine Motsinger under the MIT license.
