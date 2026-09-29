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
} derive(Eq)

///|
/// Preserve the existing text representation without the deprecated `derive(Show)` syntax.
pub impl Show for CoderResult with fn to_string(self) {
  match self {
    CoderResult::InputEmpty => "InputEmpty"
    CoderResult::OutputFull => "OutputFull"
  }
}

///|
pub extend CoderResult with Eq::{not_equal, equal}

///|
pub extend CoderResult with Show::{to_string, output}

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
}

///|
/// Preserve the existing record-style text representation without deprecated derive syntax.
pub impl Show for DecodeResult with fn to_string(self) {
  "{result: \{self.result}, read: \{self.read}, written: \{self.written}, had_replacements: \{self.had_replacements}}"
}

///|
pub extend DecodeResult with Show::{to_string, output}

///|
/// Shift_JISデコーダー
/// ストリーミング処理のための状態を保持
pub struct Decoder {
  /// 2バイト文字の1バイト目を保持（0なら保持なし）
  mut pending_first_byte : Int
  /// 置換文字を使用したかどうか
  mut had_replacements : Bool
}

///|
/// Preserve the existing record-style text representation without deprecated derive syntax.
pub impl Show for Decoder with fn to_string(self) {
  "{pending_first_byte: \{self.pending_first_byte}, had_replacements: \{self.had_replacements}}"
}

///|
pub extend Decoder with Show::{to_string, output}
