#!/bin/bash

# See `https://github.com/AniList/ApiV2-GraphQL-Docs`.

scriptdir="$( dirname -- "${BASH_SOURCE[0]}"; )";
$scriptdir/../../../scripts/introspect-schema-json https://graphql.anilist.co > $scriptdir/anilist-gql.json
