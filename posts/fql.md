---
title: FQL Manual
...

```lang-fql
/user/index/surname("Johnson",<userID:int>)
/user(:userID,...)
% results ->
/user(9323,"Timothy","Johnson",37)=nil
/user(24335,"Andrew","Johnson",42)=nil
/user(33423,"Ryan","Johnson",0x0ffa83,42.2)=nil
```

FQL is a query language for [Foundation
DB](https://www.foundationdb.org/). FQL aims to make FDB's
semantics feel natural and intuitive. Common patterns can be
modeled using FQL. Index indirection and multi-transaction
range reads are first class citizens.

> FQL is a work in-progress. The features mentioned in this
> document are not all implemented. Unimplemented features
> will be marked as such with a callout like this one.

## Overview

FQL queries generally look like key-values. They have a key
(directory & tuple) followed by `=` and a value. FQL can
only access keys encoded using the directory & tuple
[layers](https://apple.github.io/foundationdb/layer-concept.html).

```lang-fql
/my/directory("my","tuple")=4000
```

FQL queries may define a single key-value to be written, as
shown above, or may define a set of key-values to be read,
as shown below.

```lang-fql
/my/directory("my","tuple")=<>
% results ->
/my/directory("my","tuple")=0x0fa0
```

The query above has a variable `<>` as it's value. Variables
act as placeholders for any of the supported [data
elements](#data-elements). This query will return a single
key-value from the database, if such a key exists.

FQL queries can also perform range reads by including
a variable in the key's tuple. The query below will return
all key-values which conform to the schema defined by the
query. 

```lang-fql
/my/directory(<>,"tuple")=nil
% results ->
/my/directory("your","tuple")=nil
/my/directory(42,"tuple")=nil
```

All key-values with a certain key prefix can be range read
by ending the key's tuple with `...`.

```lang-fql
/my/directory("my","tuple",...)=<>
% results ->
/my/directory("my","tuple")=0x0fa0
/my/directory("my","tuple",47.3)=0x8f3a
/my/directory("my","tuple",false,0xff9a853c12)=nil
```

A query's value may be omitted to imply a variable, meaning
the following query is semantically identical to the one
above.

```lang-fql
/my/directory("my","tuple",...)
% results ->
/my/directory("my","tuple")=0x0fa0
/my/directory("my","tuple",47.3)=0x8f3a
/my/directory("my","tuple",false,0xff9a853c12)=nil
```

Including a variable in the directory tells FQL to perform
the read on all directory paths matching the schema.

```lang-fql
/<>/directory("my","tuple")
% results ->
/my/directory("my","tuple")=0x0fa0
/your/directory("my","tuple")=nil
```

The next two sections of this document elaborate on the
language's grammar and semantics. If you wish to immediately
see more examples of the language in practice, skip to
[design recipes](#design-recipes).

## Grammar

This section details the grammatical structure of an FQL
query. FQL is a context-free language with a formal
[definition](https://github.com/janderland/fdbq/blob/main/syntax.ebnf).

### Key-Values

Most FQL queries are structured like key-values and are
written as a [directory](#Directory), [tuple](#Tuple), `=`,
and value appended together.

```lang-fql
/app/data("server A",0)=0xabcf03
```

The value following the `=` may be any of the [data
elements](#data-elements) or a [variable](#variables).

```lang-fql
/region/north_america(22.3,-8)=("rain","fog")
/region/north_america(22.3,-8)=<tuple|int>
/region/north_america(22.3,-8)=-16
```

The value may also be the `clear` token.

```lang-fql
/some/where("home","town",88.3)=clear
```

### Directories

A directory is specified as a sequence of strings, each
prefixed by a forward slash:

```lang-fql
/my/dir/path_way
```

The strings of the directory do not need quotes if they only
contain alphanumericals, underscores, dashes, or periods. To
use other symbols, the strings must be quoted:

```
/my/"dir@--o/"/path_way
```

The quote character may be backslash escaped:

```
/my/"\"dir\""/path_way
```

### Tuples

A tuple is specified as a sequence of [data
elements](#data-elements) and [variables](#variables),
separated by commas, wrapped in a pair of parenthesis.
Sub-tuples are allowed.

```lang-fql
("one",2,0x03,("subtuple"),5825d3f8-de5b-40c6-ac32-47ea8b98f7b4)
```

The last element of a tuple may be the `...` token.

```lang-fql
(0xff,"thing",...)
```

Any combination of spaces, tabs, and newlines are allowed
after the opening brace and commas. Trailing commas are
allowed.

```lang-fql
(
  1,
  2,
  3,
)
```

### Data Elements

In a FQL query, the directory, tuples, and value contain
instances of data elements. FQL utilizes the same types of
elements as the [tuple
layer](https://github.com/apple/foundationdb/blob/main/design/tuple.md).
Example instances of these types can be seen below.

TODO: Give deeper descriptions of the types.

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

### Variables

Any [data element](#data-elements) may be replaced with
a variable. Variables are specified as a list of data types,
separated by `|`, wrapped in angled braces.

```lang-fql
<uint|string|uuid|bytes>
```

A variable may be empty, including no data types.

```lang-fql
<>
```

### Comments

Comments start with `%` and continue until the end of the
line.

```
% This query will read all the first
% names. A single name may be returned
% multiple times.

/index/name(<name:string>,...)
```

You can add comments within a tuple or after the value to
describe the data elements.

```
/account/private(
  <uint>,   % user ID
  <uint>,   % group ID
  <string>, % account name
)=<int>     % balance in USD
```

## Semantics

Queries have the ability to write a key-value, read one or
more key-values, and list directories.

Queries without any variables result in a single key-value
being written. You can think of these queries as explicitly
defining a single key-value.

Queries with variables or `...` result in zero or more
key-values being read. You can think of these queries as
defining a set of possible key-values stored in the DB.

You can further limit the set of key-values read by
including a type constraint in the variable.

> Queries lacking a value section imply a variable in said
> section and therefore do not result in a write operation.

### Data Encoding

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

### Index Indirection

TODO: Finish section.

```lang-fql
/user/index/surname("Johnson",<userID:int>)
/user/entry(:userID,...)
```

### Transaction Boundaries

TODO: Finish section.

## Design Recipes

TODO: Finish section.

## As a Layer

When integrating SQL into other languages, there are usually
two choices each with their own drawbacks:

1. Write literal _SQL strings_ into your code. This is
   simple but type safety isn't usually checked till
   runtime.

2. Use an _ORM_. This is more complex and sometimes doesn't
   perfectly model SQL semantics, but does provide type
   safety.

FQL leans towards option #2 by providing a Go API which is
structurally equivalent to the query language, allowing FQL
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

