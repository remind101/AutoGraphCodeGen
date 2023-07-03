#  README

Usage: `introspect-schema-json $SCHEMA_URL`

`introspection_query.json` is the full GraphQL introspection query for the 2021 schema.
The script however omits `isRepeatable` and `specifiedByUrl` from this query because many servers still do not support them.

Note that `args`, `inputFields`, and `__InputValue` in the 2021 spec do not support `(includeDeprecated: true)`/`isDeprecated` so these deprecation sigils are not included in our introspection query. Though they will be supported in the next spec when it is official.

Inspired by source-of-truth query in graphql.js ![here](https://github.com/graphql/graphql-js/blob/v16.8.0/src/utilities/getIntrospectionQuery.ts) as well as this ![gist](https://gist.github.com/martinheld/9fe32b7e2c8fd932599d36e921a2a825).
