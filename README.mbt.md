# encoding_sjis

encoding_rs-compliant Shift_JIS decoder for MoonBit.

## Features

* Shift_JIS to UTF-8 decoding
* Streaming decode API with chunk boundary support
* encoding_rs-compliant behavior
* Character set support: ASCII, half-width katakana, hiragana, katakana, kanji (JIS X 0208)
* Error handling with replacement character (U+FFFD)
* Replacement tracking

## Installation

```sh
moon add f4ah6o/encoding_sjis@0.1.1
```

## Usage

### Simple Decode

```mbt check
///|
test "simple decode" {
  let bytes = Bytes::from_array([0x82, 0xA0, 0x82, 0xA2, 0x82, 0xA4]) // "あいう"
  let (result, had_replacements) = @encoding_sjis.decode(src=bytes)
  inspect(result, content="あいう")
  inspect(had_replacements, content="false")
}
```

### Streaming Decode

```mbt check
///|
test "streaming decode" {
  let decoder = @encoding_sjis.new_decoder()
  let chunk1 = Bytes::from_array([0x82, 0xA0]) // "あ"
  let chunk2 = Bytes::from_array([0x82, 0xA2]) // "い"

  let result1 = decoder.decode_to_string(src=chunk1, false)
  let result2 = decoder.decode_to_string(src=chunk2, true)

  inspect(result1, content="あ")
  inspect(result2, content="い")
}
```

### Chunk Boundary Handling

The streaming decoder correctly handles multi-byte characters split across chunk boundaries:

```mbt check
///|
test "chunk boundary" {
  let decoder = @encoding_sjis.new_decoder()
  let chunk1 = Bytes::from_array([0x82]) // First byte of "あ"
  let chunk2 = Bytes::from_array([0xA0]) // Second byte of "あ"

  let result1 = decoder.decode_to_string(src=chunk1, false)
  let result2 = decoder.decode_to_string(src=chunk2, true)

  inspect(result1, content="") // Incomplete sequence is buffered
  inspect(result2, content="あ") // Completed after second chunk
}
```

### Error Handling

Invalid byte sequences are replaced with U+FFFD:

```mbt check
///|
test "error handling" {
  let bytes = Bytes::from_array([0x41, 0x80, 0x42]) // "A" + invalid + "B"
  let (result, had_replacements) = @encoding_sjis.decode(src=bytes)

  inspect(result, content="A�B") // U+FFFD for invalid byte
  inspect(had_replacements, content="true")
}
```

### Mixed Content

```mbt check
///|
test "mixed content" {
  let bytes = Bytes::from_array([
    0x48, 0x65, 0x6C, 0x6C, 0x6F, 0x20, // "Hello "
     0x82, 0xA0, 0x82, 0xA2, // "あい"
     0xB1, 0xB2, 0xB3, // "ｱｲｳ" (half-width katakana)
  ])
  let (result, _) = @encoding_sjis.decode(src=bytes)
  inspect(result, content="Hello あいｱｲｳ")
}
```

### Convenience API

```mbt check
///|
test "shift_jis_to_utf8" {
  let bytes = Bytes::from_array([0x82, 0xA0, 0x82, 0xA2])
  let result = @encoding_sjis.shift_jis_to_utf8(data=bytes)
  inspect(result, content="あい")
}
```

## API

### Functions

#### `decode(src: Bytes) -> (String, Bool)`

Decodes a Shift_JIS byte sequence to a UTF-8 string (non-streaming).

* Returns: (decoded string, whether replacement characters were used)

#### `new_decoder() -> Decoder`

Creates a new decoder for streaming decode operations.

#### `shift_jis_to_utf8(data: Bytes) -> String`

Convenience API that decodes Shift_JIS bytes to UTF-8 string.
Does not return replacement information (compatible with jww_parser API).

### Decoder Methods

#### `Decoder::decode_to_string(src~ : Bytes, Bool) -> String`

Decodes a chunk of Shift_JIS bytes to UTF-8 string.

* `src`: Input byte chunk
* `last`: Set `true` for the final chunk (flushes any pending incomplete sequence)
* Returns: Decoded string

#### `Decoder::reset() -> Unit`

Resets the decoder state, clearing any pending bytes and replacement flags.

#### `Decoder::had_replacements() -> Bool`

Returns whether replacement characters (U+FFFD) have been used during decoding.

### Types

#### `Decoder`

Stateful decoder for streaming operations.

* `pending_first_byte`: Stores the first byte of an incomplete 2-byte sequence
* `had_replacements`: Tracks if replacement characters were used

#### `DecodeResult`

Result of a decode operation (for future buffer-based API).

* `result`: `CoderResult` - operation status
* `read`: Number of bytes read
* `written`: Number of UTF-8 code units written
* `had_replacements`: Whether replacement characters were used

#### `CoderResult`

Result status for streaming operations.

* `InputEmpty`: Input exhausted (normal completion or waiting for more data)
* `OutputFull`: Output buffer full (for future buffer-based API)

## Supported Character Sets

* ASCII (0x00-0x7F)
* Half-width Katakana (0xA1-0xDF) → U+FF61-U+FF9F
* Hiragana (0x82A0-0x82F1)
* Full-width Katakana (0x8340-0x8396, 0x83AA-0x83EF, etc.)
* Kanji and symbols (JIS X 0208 compliant)

## License

Apache-2.0
