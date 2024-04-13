---
title: KVQ
...

```lang-kvq
/user/index/surname("Johnson",<userID:int>)
/user(:userID,...)
->
/user(9323,"Timothy","Johnson",37)=nil
/user(24335,"Andrew","Johnson",23)=nil
/user(33423,"Ryan","Johnson",54)=nil
```

KVQ is a query language for [Foundation
DB](https://www.foundationdb.org/). KVQ aims to make FDB's
semantics feel natural and intuitive. Common patterns like
index indirection and chunked range reads are first class
citizens.

> KVQ is a work in-progress. The features mentioned in this
> document are not all implemented. Unimplemented features
> will be marked as such with a callout.

## Basics

A KVQ query looks like a key-value. It has a key (directory
& tuple) and value. KVQ can only access keys encoded using
the directory & tuples
[layers](https://apple.github.io/foundationdb/layer-concept.html).

```lang-kvq
/my/directory("my","tuple")=4000
```

KVQ queries may define a single key-value to be written, as
shown above, or may define a set of key-values to be read,
as shown below.

```lang-kvq
/my/directory("my","tuple")=<>
->
/my/directory("my","tuple")=0x0fa0
```

The query above has a variable `<>` as it's value. Variables
act as placeholders for any of the supported [data
elements](#data-elements). This query will return a single
key-value from the database, if such a key exists.

KVQ queries can also perform range reads by including
a variable in the key's tuple. The query below will return
all key-values which conform to the schema defined by the
query. 

```lang-kvq
/my/directory(<>,"tuple")=nil
->
/my/directory("your","tuple")=nil
/my/directory(42,"tuple")=nil
```

All key-values with a certain key prefix can be range read
by ending the key's tuple with `...`.

```lang-kvq
/my/directory("my","tuple",...)=<>
->
/my/directory("my","tuple")=0x0fa0
/my/directory("my","tuple",47.3)=0x8f3a
/my/directory("my","tuple",false)=nil
```

A query's value may be omitted to imply a variable, meaning
the following query is semantically identical to the one
above.

```lang-kvq
/my/directory("my","tuple",...)
->
/my/directory("my","tuple")=0x0fa0
/my/directory("my","tuple",47.3)=0x8f3a
/my/directory("my","tuple",false)=nil
```

Including a variable in the directory tells KVQ to perform
the read on all directory paths matching the schema.

```lang-kvq
/<>/directory("my","tuple")
->
/my/directory("my","tuple")=0x0fa0
/your/directory("my","tuple")=nil
```

## Data Elements

In a KVQ query, the directory, tuple, and value contain
instances of data elements. KVQ utilizes the same types of
elements as the [tuple
layer](https://github.com/apple/foundationdb/blob/main/design/tuple.md).
Example instances of these types can be seen below.

| Type     | Example                                |
|:---------|:---------------------------------------|
| `nil`    | `nil`                                  |
| `int`    | `-14`                                  |
| `uint`   | `7`                                    |
| `bool`   | `true`                                 |
| `float`  | `33.4`                                 |
| `bigint` | `#35299340192843523485929848293291842` |
| `string` | `"string"`                             |
| `bytes`  | `0xa2bff2438312aac032`                 |
| `uuid`   | `5a5ebefd-2193-47e2-8def-f464fc698e31` |
| `tuple`  | `("hello",27.4,nil)`                   |

> `bigint` support is not yet implemented.

The directory may only contain strings. Directory strings 
don't need to be quoted if they only contain alphanumerics, 
`.`, or `_`. The tuple & value may contain any of the data
elements.

For the precise syntax definitions of each data type, see 
the [syntax document](syntax.ebnf).

## Data Encoding

The directory and tuple layers are responsible for 
encoding the data elements in the key section. As for the 
value section, FDB doesn't provide a standard encoding.

The table below outlines how data elements are encoded 
when present in the value section.

| Type     | Encoding                        |
|:---------|:--------------------------------|
| `nil`    | empty value                     |
| `int`    | 64-bit, 1's compliment          |
| `uint`   | 64-bit                          |
| `bool`   | single byte, `0x00` means false |
| `float`  | IEEE 754                        |
| `bigint` | not implemented yet             |
| `string` | ASCII                           |
| `bytes`  | as provided                     |
| `uuid`   | RFC 4122                        |
| `tuple`  | tuple layer                     |

## Variables

Queries without any variables result in a single key-value
being written. You can think of these queries as explicitly
defining a single key-value.

> Queries lacking a value section imply a variable in said
> section and therefore do not result in a write operation.

Queries with variables or `...` result in zero or more
key-values being read. You can think of these queries as
defining a set of possible key-values stored in the DB.

You can further limit the set of key-values read by
including a type constraint in the variable.

```lang-kvq
/my/directory("tuple",<int|string>)=<tuple>
```

In the query above, the 2nd element of the key's tuple must
be either an integer or string. Likewise, the value must be
a tuple.

## Index Indirection

TODO: Finish section.

```lang-kvq
/user/index/surname("Johnson",<userID:int>)
/user/entry(:userID,...)
```

## Transaction Boundaries

TODO: Finish section.

## Language Integration

When integrating SQL into other languages, there are usually
two choices each with their own drawbacks:

1. Write literal _SQL strings_ into your code. This is
   simple but type safety isn't usually checked till
   runtime.

2. Use an _ORM_. This is more complex and sometimes doesn't
   perfectly model SQL semantics, but does provide type
   safety.

KVQ leans towards option #2 by providing a Go API which is
structurally equivalent to the query language, allowing KVQ
semantics to be modeled in the host language's type system.

This Go API may also be viewed as an FDB layer which unifies
the directory & tuple layers with the FDB base API.

```lang-go
package example

import (
  "github.com/apple/foundationdb/bindings/go/src/fdb"
  "github.com/apple/foundationdb/bindings/go/src/fdb/directory"

  "github.com/janderland/fdbq/engine"
  "github.com/janderland/fdbq/engine/facade"
  kv "github.com/janderland/fdbq/keyval"
)

func _() {
  fdb.MustAPIVersion(620)
  eg := engine.New(facade.NewTransactor(
    fdb.MustOpenDefault(), directory.Root()))

  // /user/entry(22573,"Goodwin","Samuels")=nil
  query := kv.KeyValue{
    Key: kv.Key{
      Directory: kv.Directory{
        kv.String("user"),
        kv.String("entry"),
      },
      Tuple: kv.Tuple{
        kv.Int(22573),
        kv.String("Goodwin"),
        kv.String("Samuels"),
      },
    },
    Value: kv.Nil{},
  }

  // Perform the write.
  err := eg.Set(query);
  if err != nil {
    panic(err)
  }
}
```

