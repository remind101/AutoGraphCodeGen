#!/bin/bash

# See `https://github.com/graphql/swapi-graphql`.

scriptdir="$( dirname -- "${BASH_SOURCE[0]}"; )";
$scriptdir/../../../scripts/introspect-schema-json https://spacex-production.up.railway.app/ > $scriptdir/spacex-gql.json
