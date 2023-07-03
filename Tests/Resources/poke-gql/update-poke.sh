#!/bin/bash

# See `https://pokeapi.co/docs/graphql`.
# Or `https://studio.apollographql.com/public/poke-gql/variant/current/home`.

scriptdir="$( dirname -- "${BASH_SOURCE[0]}"; )";
$scriptdir/../../../scripts/introspect-schema-json https://beta.pokeapi.co/graphql/v1beta > $scriptdir/poke-gql.json
