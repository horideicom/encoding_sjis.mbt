///|
/// Shift_JISデコーダーの実装
/// ストリーミングデコードAPIを提供

///|
/// 新しいデコーダーを作成
pub fn Decoder::new() -> Decoder {
  { pending_first_byte: 0, had_replacements: false }
}

///|
/// デコーダーの状態をリセット
pub fn Decoder::reset(self : Decoder) -> Unit {
  self.pending_first_byte = 0
  self.had_replacements = false
}

///|
/// 置換文字が使用されたかどうかを返す
pub fn Decoder::had_replacements(self : Decoder) -> Bool {
  self.had_replacements
}

///|
/// Shift_JISバイト列をUTF-8文字列にデコード（ストリーミング対応）
///
/// 引数:
///   - src: 入力バイト列
///   - last: 最後のチャンクかどうか（falseの場合、不完全なシーケンスを次回に持ち越し）
///
/// 戻り値: デコードされた文字列
pub fn Decoder::decode_to_string(self : Decoder, src~ : Bytes, last : Bool) -> String {
  let mut result = ""
  let mut i = 0
  let len = src.length()

  // 前回のペンディングバイトがあれば処理
  if self.pending_first_byte != 0 {
    if len == 0 {
      if last {
        // 不完全なシーケンスの終了
        result = result + '\uFFFD'.to_string()
        self.had_replacements = true
        self.pending_first_byte = 0
      }
    } else {
      let b1 = self.pending_first_byte
      let b2 = src[0].to_int()
      let valid_second = (b2 >= 0x40 && b2 <= 0xFC) && (b2 != 0x7F)

      if valid_second {
        let code = (b1 << 8) | b2
        match decode_jis_x_0208(code=code) {
          Some(ch) => result = result + ch.to_string()
          None => {
            result = result + '\uFFFD'.to_string()
            self.had_replacements = true
          }
        }
        i = 1
      } else {
        // 無効な2バイト目
        result = result + '\uFFFD'.to_string()
        self.had_replacements = true
        // b2を再度処理（ASCII等の可能性があるため、iは進めない）
        i = 0
      }
      self.pending_first_byte = 0
    }
  }

  // メインのデコードループ
  while i < len {
    let b1 = src[i].to_int()

    if b1 < 0x80 {
      // ASCII (0x00-0x7F)
      result = result + Int::unsafe_to_char(b1).to_string()
      i += 1
    } else if b1 >= 0xA1 && b1 <= 0xDF {
      // 半角カタカナ (0xA1-0xDF) → U+FF61-U+FF9F
      let ch = decode_half_width_katakana(byte=b1)
      result = result + ch.to_string()
      i += 1
    } else if (b1 >= 0x81 && b1 <= 0x9F) || (b1 >= 0xE0 && b1 <= 0xEF) {
      // 2バイト文字の1バイト目
      if i + 1 < len {
        // 同じチャンク内に2バイト目がある
        let b2 = src[i + 1].to_int()
        let valid_second = (b2 >= 0x40 && b2 <= 0xFC) && (b2 != 0x7F)

        if valid_second {
          let code = (b1 << 8) | b2
          match decode_jis_x_0208(code=code) {
            Some(ch) => result = result + ch.to_string()
            None => {
              result = result + '\uFFFD'.to_string()
              self.had_replacements = true
            }
          }
          i += 2
        } else {
          result = result + '\uFFFD'.to_string()
          self.had_replacements = true
          i += 1
        }
      } else if last {
        // チャンクの末尾で、かつ最後のチャンク
        result = result + '\uFFFD'.to_string()
        self.had_replacements = true
        i += 1
      } else {
        // ペンディング：次のチャンクを待つ
        self.pending_first_byte = b1
        i += 1
      }
    } else {
      // 不明なバイト値 (0x80, 0xF0-0xFF)
      result = result + '\uFFFD'.to_string()
      self.had_replacements = true
      i += 1
    }
  }

  result
}
