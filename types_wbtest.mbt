///|
/// Keep the legacy type representations stable while validating the public types.
test "legacy public type representations" {
  inspect(
    CoderResult::InputEmpty,
    content=(
      #|InputEmpty
    ),
  )
  inspect(
    CoderResult::OutputFull,
    content=(
      #|OutputFull
    ),
  )
  inspect(
    DecodeResult::{
      result: CoderResult::InputEmpty,
      read: 2,
      written: 1,
      had_replacements: false,
    },
    content=(
      #|{result: InputEmpty, read: 2, written: 1, had_replacements: false}
    ),
  )
  inspect(
    Decoder::new(),
    content=(
      #|{pending_first_byte: 0, had_replacements: false}
    ),
  )
}
