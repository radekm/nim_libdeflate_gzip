import std/os
import std/strutils

import unittest

import libdeflate_gzip

proc currentSourceDir(): string {.compileTime.} =
  result = currentSourcePath().replace("\\", "/")
  result = result[0 ..< result.rfind("/")]

const
  dataDir = currentSourceDir() & "/data"
  bufferSize = 1000

test "ungzip both members":
  let compressed = readFile(dataDir & "/ab.gz")
  let d = newDecompressor()
  var read, written: int

  var member1 = newString(bufferSize)
  let result1 = d.decompress(
    compressed.cstring, compressed.len,
    member1.cstring, member1.len,
    read, written,
  )
  check result1 == Success
  check cast[BiggestInt](read) == getFileSize(dataDir & "/a.gz")
  check cast[BiggestInt](written) == getFileSize(dataDir & "/a.txt")
  member1.setLen(cast[Natural](written))
  check member1 == readFile(dataDir & "/a.txt")

  var member2 = newString(bufferSize)
  let result2 = d.decompress(
    unsafeAddr compressed[read], compressed.len,
    member2.cstring, member2.len,
    read, written,
  )
  check result2 == Success
  check cast[BiggestInt](read) == getFileSize(dataDir & "/b.gz")
  check cast[BiggestInt](written) == getFileSize(dataDir & "/b.txt")
  member2.setLen(cast[Natural](written))
  check member2 == readFile(dataDir & "/b.txt")

test "input buffer doesn't hold whole member":
  var compressed = readFile(dataDir & "/b.gz")
  compressed.setLen(compressed.len * 2 div 3)

  var decompressed = newString(bufferSize)
  let d = newDecompressor()
  var read, written: int
  let result = d.decompress(
    compressed.cstring, compressed.len,
    decompressed.cstring, decompressed.len,
    read, written,
  )

  check result == BadData

test "output buffer is not big enough":
  let compressed = readFile(dataDir & "/b.gz")

  var decompressed = newString(getFileSize(dataDir & "/b.txt") - 5)
  let d = newDecompressor()
  var read, written: int
  let result = d.decompress(
    compressed.cstring, compressed.len,
    decompressed.cstring, decompressed.len,
    read, written,
  )

  check result == InsufficientSpace

# TODO Test invalid gzip.
