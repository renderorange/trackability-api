# trackability-api

## DESCRIPTION

trackability-api is an API for storing and retrieving arbitrary JSON data.

## INSTALLATION

See the [INSTALLATION.md](INSTALLATION.md) file within this repo for instructions.

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

### Get events created between dates

#### Between two dates

```
GET /collections/:collections_id/events?created_at=:timestamp&created_at=:timestamp
```

```
$ curl -X GET -H 'Content-Type: application/json' -H "Authorization: Token $TOKEN" 'localhost:5000/collections/6/events?created_at=1697469969&created_at=1697469977'
[
   {
      "updated_at" : 1697469969,
      "data" : {
         "one" : 1,
         "two" : 2
      },
      "id" : 1,
      "created_at" : 1697469969,
      "collections_id" : 6
   },
   {
      "created_at" : 1697469977,
      "collections_id" : 6,
      "updated_at" : 1697469977,
      "data" : {
         "one" : 1,
         "two" : 2
      },
      "id" : 2
   }
]
```

#### Before a date

```
GET /collections/:collections_id/events?created_at=&created_at=:timestamp
```

```
$ curl -X GET -H 'Content-Type: application/json' -H "Authorization: Token $TOKEN" 'localhost:5000/collections/6/events?created_at=&created_at=1697469976'
[
   {
      "id" : 1,
      "data" : {
         "one" : 1,
         "two" : 2
      },
      "updated_at" : 1697469969,
      "collections_id" : 6,
      "created_at" : 1697469969
   }
]
```

#### After a date

```
GET /collections/:collections_id/events?created_at=:timestamp&created_at=
```

```
$ curl -X GET -H 'Content-Type: application/json' -H "Authorization: Token $TOKEN" 'localhost:5000/collections/6/events?created_at=1697469970&created_at='
[
   {
      "collections_id" : 6,
      "created_at" : 1697469977,
      "id" : 2,
      "data" : {
         "two" : 2,
         "one" : 1
      },
      "updated_at" : 1697469977
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
