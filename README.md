
Nim wrapper for libdeflate. Only `--mm:arc` and `--mm:orc` are supported.
No external dependencies are needed because libdeflate is embedded.

The main difference from Zippy is that libdeflate supports
gzips with multiple members (ie. multiple gzips concatenated together).
