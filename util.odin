package solote

import "core:log"
import "core:slice"

read_bytes :: proc(data: []u8, pos: ^int, offset: int) -> (result: []u8, success: bool) {
	if len(data) < pos^ do return nil, false
	result = data[pos^:][:offset]
	pos^ += offset
	return result, true
}

read_bytes_until :: proc(
	data: []u8,
	pos: ^int,
	until: []u8,
	skip_end: bool = false,
) -> (
	result: []u8,
	success: bool,
) {
	if len(data) < pos^ do return nil, false
	og_pos := pos^
	for i, j := pos^, pos^; j < len(data); j += len(until) {
		pos^ = j
		if slice.equal(data[i:j], until) do return data[og_pos:j - (skip_end ? len(until) : 0)], true
		i = j
	}
	return nil, false
}
