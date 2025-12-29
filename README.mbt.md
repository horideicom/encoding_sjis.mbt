# encoding_sjis_mbt

encoding_rs準拠のShift_JISデコーダー for MoonBit。

## 機能

* Shift_JISバイト列をUTF-8文字列にデコード
* ストリーミングデコードAPI（チャンク処理対応）
* encoding_rs準拠の挙動

## インストール

```moonbit
[dependencies]
encoding_sjis_mbt = "{ version = \"0.1.0\" }"
```

## 使用例

### シンプルデコード

```moonbit
test "simple decode" {
  let bytes = [0x82, 0xA0, 0x82, 0xA2, 0x82, 0xA4] // "あいう"
  let (result, had_replacements) = decode(src=bytes)
  @test.eq(result, "あいう")
  @test.eq(had_replacements, false)
}
```

### ストリーミングデコード

```moonbit
test "streaming decode" {
  let decoder = new_decoder()
  let chunk1 = [0x82, 0xA0] // "あ"
  let chunk2 = [0x82, 0xA2] // "い"

  let result1 = decoder.decode_to_string(src=chunk1, last=false)
  let result2 = decoder.decode_to_string(src=chunk2, last=true)

  @test.eq(result1, "あ")
  @test.eq(result2, "い")
}
```

### 簡易API

```moonbit
test "shift_jis_to_utf8" {
  let bytes = [0x82, 0xA0, 0x82, 0xA2]
  let result = shift_jis_to_utf8(data=bytes)
  @test.eq(result, "あい")
}
```

## API

### `decode(src: Bytes) -> (String, Bool)`

Shift_JISバイト列をUTF-8文字列にデコードします（非ストリーミング）。

* 戻り値: (デコードされた文字列, 置換文字が使用されたかどうか)

### `new_decoder() -> Decoder`

ストリーミングデコード用の新しいデコーダーを作成します。

### `shift_jis_to_utf8(data: Bytes) -> String`

Shift_JISバイト列をUTF-8文字列に変換する簡易API。

## ライセンス

Apache-2.0
