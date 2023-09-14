#!/bin/bash

# See `https://github.com/graphql/swapi-graphql`.

scriptdir="$( dirname -- "${BASH_SOURCE[0]}"; )";
$scriptdir/../../../scripts/introspect-schema-json https://swapi-graphql.netlify.app/.netlify/functions/index > $scriptdir/swapi-gql.json
