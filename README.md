# About

Nim wrapper for libdeflate's gzip functionality.
Since this library relies on destructors only `--mm:arc` and `--mm:orc` are supported.
No external dependencies are needed because libdeflate is embedded.

The main difference from Zippy is that libdeflate supports
gzips with multiple members (ie. multiple gzips concatenated together).

# Usage

Examples are in `tests/test.nim`. If you want to iterate through all members
use iterator `decompressGzipMembers`.

# Updating libdeflate

Libdeflate can be updated by running

```shell
git subtree pull --prefix src/libdeflate_gzip/private/libdeflate https://github.com/ebiggers/libdeflate.git master --squash
```
