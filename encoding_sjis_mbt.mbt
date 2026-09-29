///|
/// encoding_rs準拠のShift_JISデコーダー
/// ストリーミングと非ストリーミングの両方のAPIを提供

///|
/// Shift_JISバイト列をUTF-8文字列にデコード（非ストリーミング）
///
/// 戻り値: (デコードされた文字列, 置換文字が使用されたかどうか)
pub fn decode(src~ : Bytes) -> (String, Bool) {
  let decoder = new_decoder()
  let result = decoder.decode_to_string(src~, true)
  (result, decoder.had_replacements())
}

///|
/// ストリーミングデコード用の新しいデコーダーを作成
pub fn new_decoder() -> Decoder {
  Decoder::new()
}

///|
/// Shift_JISバイト列をUTF-8文字列に変換
/// jww_parser互換の簡易API（置換文字の使用状況を返さない）
pub fn shift_jis_to_utf8(data~ : Bytes) -> String {
  let (result, _) = decode(src=data)
  result
}
