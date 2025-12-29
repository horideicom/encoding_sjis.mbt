///|
/// Shift_JISデコーダーのテスト

///|
test "ascii" {
  let input = Bytes::from_array([0x41, 0x42, 0x43, 0x20, 0x31, 0x32, 0x33]) // "ABC 123"
  let (result, had_replacements) = decode(src=input)
  inspect(result, content="ABC 123")
  inspect(had_replacements, content="false")
}

///|
test "half_width_katakana" {
  // 0xA1 → U+FF61, 0xDF → U+FF9F
  let input = Bytes::from_array([0xA1, 0xA2, 0xA3, 0xDF])
  let (result, had_replacements) = decode(src=input)
  inspect(result, content="\uFF61\uFF62\uFF63\uFF9F")
  inspect(had_replacements, content="false")
}

///|
test "hiragana" {
  // "あいうえお" in Shift_JIS
  let input = Bytes::from_array([0x82, 0xA0, 0x82, 0xA2, 0x82, 0xA4, 0x82, 0xA6, 0x82, 0xA8])
  let (result, had_replacements) = decode(src=input)
  inspect(result, content="あいうえお")
  inspect(had_replacements, content="false")
}

///|
test "katakana" {
  // "アイウエオ" in Shift_JIS
  let input = Bytes::from_array([0x83, 0x40, 0x83, 0x42, 0x83, 0x44, 0x83, 0x46, 0x83, 0x48])
  let (result, had_replacements) = decode(src=input)
  inspect(result, content="ァィゥェォ")
  inspect(had_replacements, content="false")
}

///|
test "kanji" {
  // "日本語" in Shift_JIS
  let input = Bytes::from_array([0x93, 0xFA, 0x96, 0x7B, 0x8C, 0xEA])
  let (result, had_replacements) = decode(src=input)
  inspect(result, content="日本語")
  inspect(had_replacements, content="false")
}

///|
test "mixed" {
  // "Hello 日本語 ｱｲｳ" in Shift_JIS
  let input = Bytes::from_array([
    0x48, 0x65, 0x6C, 0x6C, 0x6F, 0x20, // "Hello "
    0x93, 0xFA, 0x96, 0x7B, 0x8C, 0xEA, 0x20, // "日本語 "
    0xB1, 0xB2, 0xB3 // "ｱｲｳ"
  ])
  let (result, had_replacements) = decode(src=input)
  inspect(result, content="Hello 日本語 ｱｲｳ")
  inspect(had_replacements, content="false")
}

///|
test "invalid_sequence_replacement" {
  // 不正なシーケンス (0x80はShift_JISで未定義)
  let input = Bytes::from_array([0x41, 0x80, 0x42]) // "A<invalid>B"
  let (result, had_replacements) = decode(src=input)
  inspect(result, content="A�B")
  inspect(had_replacements, content="true")
}

///|
test "incomplete_two_byte_at_end" {
  // 不完全な2バイト文字（最後のチャンクとみなす）
  let input = Bytes::from_array([0x82, 0xA0, 0x82]) // "あ" + 不完全な"い"
  let (result, had_replacements) = decode(src=input)
  inspect(result, content="あ\uFFFD")
  inspect(had_replacements, content="true")
}

///|
test "shift_jis_to_utf8_compat" {
  // jww_parser互換APIのテスト
  let input = Bytes::from_array([0x93, 0xFA, 0x96, 0x7B]) // "日本"
  let result = shift_jis_to_utf8(data=input)
  inspect(result, content="日本")
}

///|
test "streaming_split_two_byte" {
  // 2バイト文字がチャンク境界で分割されるケース
  let decoder = new_decoder()

  // 最初のチャンク（"あ"の1バイト目のみ）
  let chunk1 = Bytes::from_array([0x82])
  let result1 = decoder.decode_to_string(src=chunk1,false)
  inspect(result1, content="")
  inspect(decoder.pending_first_byte, content="130") // 0x82 = 130

  // 2番目のチャンク（"あ"の2バイト目）
  let chunk2 = Bytes::from_array([0xA0])
  let result2 = decoder.decode_to_string(src=chunk2,false)
  inspect(result2, content="あ")
  inspect(decoder.pending_first_byte, content="0")
}

///|
test "streaming_multiple_chunks" {
  // 複数のチャンクに分割されたテキスト
  let decoder = new_decoder()
  let mut result = ""

  let chunk1 = Bytes::from_array([0x82, 0xA0, 0x82]) // "あ" + "い"の1バイト目
  result = result + decoder.decode_to_string(src=chunk1,false)

  let chunk2 = Bytes::from_array([0xA2, 0x82, 0xA4]) // "い"の2バイト目 + "う"の1バイト目
  result = result + decoder.decode_to_string(src=chunk2,false)

  let chunk3 = Bytes::from_array([0x83, 0x40]) // "う"の2バイト目 + "ア"
  result = result + decoder.decode_to_string(src=chunk3,true)

  inspect(result, content="あいうァ")
  inspect(decoder.had_replacements(), content="false")
}

///|
test "decoder_reset" {
  // デコーダーのリセット機能
  let decoder = new_decoder()

  // 不完全なシーケンスを残す
  let chunk1 = Bytes::from_array([0x82])
  let _ = decoder.decode_to_string(src=chunk1, false)
  inspect(decoder.pending_first_byte, content="130")

  // リセット
  decoder.reset()
  inspect(decoder.pending_first_byte, content="0")
  inspect(decoder.had_replacements(), content="false")
}

///|
test "fullwidth_characters" {
  // 全角文字のテスト（！＂＃＄％＆＇）
  let input = Bytes::from_array([0x81, 0x49, 0x81, 0x68, 0x81, 0x69, 0x81, 0x6A, 0x81, 0x6B, 0x81, 0x6C, 0x81, 0x6D])
  let (result, had_replacements) = decode(src=input)
  inspect(result, content="！”（）〔〕［")
  inspect(had_replacements, content="false")
}
