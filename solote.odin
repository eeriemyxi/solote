package solote

import "core:c"
import "core:fmt"
import "core:mem"
import "core:slice"
import "core:os/os2"

ID3v2_Header :: struct {
	fident:   string,
	version:  struct {
		major:    u8,
		revision: u8,
	},
	flags:    bit_field u8 {
		unsynchronisation: bool | 1,
		extended_header:   bool | 1,
		experimental:      bool | 1,
	},
	tag_size: i32,
}

Frame_Header :: struct {
	id:             string,
	size:           i32,
	status_flags:   bit_field u8 {
		alter_tag:  bool | 1,
		alter_file: bool | 1,
		read_only:  bool | 1,
	},
	encoding_flags: bit_field u8 {
		compression:       bool | 1,
		encryption:        bool | 1,
		grouping_identity: bool | 1,
	},
	data:           []u8,
}

print_bits :: proc(n: $T) {
	for i := size_of(n) * c.CHAR_BIT - 1; i >= 0; i -= 1 {
		fmt.print(n >> u64(i) & 1)
		if i % 8 == 0 do fmt.print(" ")
	}
	fmt.println()
}

unsync :: proc(raw: []u8) -> (size: i32 = 0) {
	for s in raw do size = (size << 7) | (i32(s) & 127)
	return
}

read_bytes :: proc(data: []u8, pos: ^int, offset: int) -> (result: []u8, success: bool) {
	if len(data) < pos^ do return nil, false
	result = data[pos^:][:offset]
	pos^ += offset
	return result, true
}

main :: proc() {
	if len(os2.args) != 2 {
		fmt.eprintln("[ERROR] Must provide the file to scan.")
		os2.exit(1)
	}

	filename := os2.args[1]
	file, err := os2.read_entire_file(filename, context.allocator)

	header := ID3v2_Header{}
	pos := 0

	header.fident = string(read_bytes(file, &pos, 3) or_else panic("file identifier not found"))

	raw_version := read_bytes(file, &pos, 2) or_else panic("version not found")
	mem.copy(&header.version, &raw_version[0], size_of(header.version))

	raw_flags := (read_bytes(file, &pos, 1) or_else panic("flags not found"))[0]
	mem.copy(&header.flags, &raw_flags, size_of(header.flags))

	raw_tag_size := read_bytes(file, &pos, 4) or_else panic("tag size not found")
	header.tag_size = unsync(raw_tag_size)

	fmt.printfln(
		"fident=%s version=%v flags=%08b raw_tag_size=%08b-%08b-%08b-%08b tag_size=%d (%32b)",
		header.fident,
		raw_version,
		raw_flags,
		raw_tag_size[0],
		raw_tag_size[1],
		raw_tag_size[2],
		raw_tag_size[3],
		header.tag_size,
		header.tag_size,
	)

	fmt.println(header)

	for pos < int(header.tag_size) {
		frame_header := Frame_Header{}

		frame_header.id = string(read_bytes(file, &pos, 4) or_else panic("frame id not found"))
		if frame_header.id == "\x00\x00\x00\x00" {
			fmt.println("[INFO] padding reached at pos=%d", pos)
			break
		}

		frame_raw_size := read_bytes(file, &pos, 4) or_else panic("frame size not found")
		for b in frame_raw_size do frame_header.size = frame_header.size << 8 | i32(b)

		raw_frame_status_flags :=
			(read_bytes(file, &pos, 1) or_else panic("frame status flags not found"))[0]
		raw_frame_encoding_flags :=
			(read_bytes(file, &pos, 1) or_else panic("frame encoding flags not found"))[0]

		mem.copy(
			&frame_header.status_flags,
			&raw_frame_status_flags,
			size_of(frame_header.status_flags),
		)
		mem.copy(
			&frame_header.encoding_flags,
			&raw_frame_encoding_flags,
			size_of(frame_header.encoding_flags),
		)

		frame_header.data =
			read_bytes(file, &pos, int(frame_header.size)) or_else panic("frame data not found")

		fmt.println(frame_header)
		fmt.printfln(
			"frame_id=%s raw_size=%08b-%08b-%08b-%08b size=%d (%32b) status_flags=%08b encoding_flags=%08b",
			frame_header.id,
			frame_raw_size[0],
			frame_raw_size[1],
			frame_raw_size[2],
			frame_raw_size[3],
			frame_header.size,
			frame_header.size,
			raw_frame_status_flags,
			raw_frame_encoding_flags,
		)
	}
}
