package solote

import "core:fmt"
import "core:log"
import "core:mem"
import "core:os/os2"
import "core:reflect"
import "core:slice"

frame_type_to_string :: proc(type: ID3v2_Frame_Type) -> string {
	return reflect.enum_string(type)
}

unsync :: proc(raw: u32) -> (size: u32 = 0) {
	for s in transmute([4]u8)raw do size = (size << 7) | (u32(s) & 127)
	return
}
