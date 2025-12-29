///|
/// encoding_rs準拠のShift_JISデコーダー型定義

///|
/// ストリーミングデコード操作の結果
/// encoding_rsのCoderResultに相当
pub enum CoderResult {
  /// 入力が使い果たされた（正常終了または継続待ち）
  InputEmpty
  /// 出力バッファが満杯
  OutputFull
} derive(Eq, Show)

///|
/// デコード操作の結果
pub struct DecodeResult {
  /// 処理結果
  result : CoderResult
  /// 読み取ったバイト数
  read : Int
  /// 書き込んだUTF-8コードユニット数
  written : Int
  /// 置換文字を使用したかどうか
  had_replacements : Bool
} derive(Show)

///|
/// Shift_JISデコーダー
/// ストリーミング処理のための状態を保持
pub struct Decoder {
  /// 2バイト文字の1バイト目を保持（0なら保持なし）
  mut pending_first_byte : Int
  /// 置換文字を使用したかどうか
  mut had_replacements : Bool
} derive(Show)
