import std/algorithm
import std/os
import std/sequtils
import std/strformat
import std/strutils
import std/tables

import benchy
import libdeflate_gzip
import zippy

if paramCount() != 1:
  raise newException(Exception, "Directory with corpus must be given")

let
  corpusDir = paramStr(1)
  corpusFiles = toSeq(walkDir(corpusDir, checkDir = true)).mapIt(it.path).sorted
  libdeflateBufferSize = 2 * 1024 * 1024

echo "libdeflate_gzip [best compression]"
let libdeflateSizes = newTable[string, int]()
for file in corpusFiles:
  let uncompressed = readFile(file)
  let name = file.extractFilename
  timeIt name:
    let compressor = newCompressor(9)  # Compression level 9.
    let compressed = newString(libdeflateBufferSize)
    let compressedLen = compressor.compress(
      uncompressed.cstring, uncompressed.len,
      compressed.cstring, compressed.len
    )
    if compressedLen == 0:
      raise newException(Exception, &"Cannot compress {file}, buffer too small")
    libdeflateSizes[file] = compressedLen

echo "libdeflate_gzip [extreme compression]"
let libdeflateExtremeSizes = newTable[string, int]()
for file in corpusFiles:
  let uncompressed = readFile(file)
  let name = file.extractFilename
  timeIt name:
    let compressor = newCompressor(12)  # Compression level 12.
    let compressed = newString(libdeflateBufferSize)
    let compressedLen = compressor.compress(
      uncompressed.cstring, uncompressed.len,
      compressed.cstring, compressed.len
    )
    if compressedLen == 0:
      raise newException(Exception, &"Cannot compress {file}, buffer too small")
    libdeflateExtremeSizes[file] = compressedLen

echo "zippy [best compression]"
let zippySizes = newTable[string, int]()
for file in corpusFiles:
  let uncompressed = readFile(file)
  let name = file.extractFilename
  timeIt name:
    let result = zippy.compress(uncompressed, BestCompression, dataFormat = dfGzip)
    zippySizes[file] = result.len

echo "\nSizes\n"
echo "file".align(20),
  "uncompressed".align(15),
  "ld [best]".align(15),
  "ld [extreme]".align(15),
  "zippy [best]".align(15)

for file in corpusFiles:
  let originalSize = file.getFileSize
  let name = file.extractFilename
  echo name.align(20),
    ($originalSize).align(15),
    ($libdeflateSizes[file]).align(15),
    ($libdeflateExtremeSizes[file]).align(15),
    ($zippySizes[file]).align(15)
