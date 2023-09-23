# AutoGraphCodeGen
[![CircleCI](https://circleci.com/gh/remind101/AutoGraphCodeGen.svg?style=shield)](https://app.circleci.com/pipelines/github/remind101/AutoGraphCodeGen)

The Swiftest way to GraphQL Codegen

### Introspection

Usage: `./scripts/introspect-schema-json $SCHEMA_URL`.
See `./scripts/README.md` for more information.

### Testing

If you test from Xcode it will automatically code gen from the various test schemas in `./Tests/Resources`. Then simply rerun testing and it will attempt to compile the code gen'd code with the tests. If the code compiles on this second run, the "tests" have passed.

### Building

`swift build -c release --arch arm64 --arch x86_64` will build a release for supported architectures.
For more information see `https://www.smileykeith.com/2020/12/24/swiftpm-cross-compile/`.

The output binary will be located under `./.build/apple/Products/Release/AutoGraphCodeGen` if building from MacOS.

### Configuration

See example configuration in the Tests under file `test_autograph_codegen_config.json` and additionally look at `./Sources/libAutoGraphCodeGen/Configuration.swift` for configuration data structures and corresponding documentation.
