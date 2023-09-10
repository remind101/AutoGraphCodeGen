# AutoGraphCodeGen
Swift GraphQL Code Generator

### Introspection

Usage: `./scripts/introspect-schema-json $SCHEMA_URL`.
See `./scripts/README.md` for more information.

### Testing

If you test from Xcode it will automatically code gen from the various test schemas in `./Tests/Resources`. Then simply rerun testing and it will attempt to compile the code gen'd code with the tests. If the code compiles on this second run, the "tests" have passed.

### Building

`swift build -c release --arch arm64 --arch x86_64` will build a release for supported architectures.
For more information see `https://www.smileykeith.com/2020/12/24/swiftpm-cross-compile/`.
