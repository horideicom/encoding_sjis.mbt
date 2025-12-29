///|
fn main {
  // 非ストリーミングデコードの例
  let sjis_bytes = Bytes::from_array([
    0x48, 0x65, 0x6C, 0x6C, 0x6F, 0x20, // "Hello "
    0x93, 0xFA, 0x96, 0x7B, 0x8C, 0xEA, 0x20, // "日本語 "
    0x82, 0xA0, 0x82, 0xA2, 0x82, 0xA4  // "あいう"
  ])

  let (text, had_errors) = @lib.decode(src=sjis_bytes)
  println("非ストリーミング: " + text)
  println("置換文字使用: " + had_errors.to_string())

  // ストリーミングデコードの例
  let decoder = @lib.new_decoder()
  let mut result = ""

  // チャンク1: "Hello 日本"
  let chunk1 = Bytes::from_array([
    0x48, 0x65, 0x6C, 0x6C, 0x6F, 0x20,
    0x93, 0xFA, 0x96, 0x7B
  ])
  result = result + decoder.decode_to_string(src=chunk1, false)

  // チャンク2: "語"（2バイト目のみ）+ "あ"の1バイト目
  let chunk2 = Bytes::from_array([0x8C, 0xEA, 0x82])
  result = result + decoder.decode_to_string(src=chunk2, false)

  // チャンク3: "あいう"の残り
  let chunk3 = Bytes::from_array([0xA0, 0x82, 0xA2, 0x82, 0xA4])
  result = result + decoder.decode_to_string(src=chunk3, true)

  println("ストリーミング: " + result)
  println("置換文字使用: " + decoder.had_replacements().to_string())

  // jww_parser互換API
  let compat_result = @lib.shift_jis_to_utf8(data=sjis_bytes)
  println("互換API: " + compat_result)
}
