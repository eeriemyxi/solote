package solote

import "core:encoding/endian"
import "core:fmt"
import "core:log"
import "core:reflect"
import "core:slice"

frame_id_to_type :: proc(id_s: string) -> ID3v2_Frame_Type {
	type, ok := reflect.enum_from_name(ID3v2_Frame_Type, id_s)
	if !ok do return .Unknown
	return type
}

parse_header :: proc(raw_header: []u8) -> (header: ID3v2_Header, ok: bool) {
	// https://id3.org/id3v2.3.0#:~:text=must%20be%20%2400.-,3.1.%20ID3v2%20header,-The%20ID3v2%20tag
	header, ok = slice.to_type(raw_header, ID3v2_Header)
	header.tag_size = unsync(header.tag_size)
	return
}

parse_frame_data_apic :: proc(data: []u8) -> (apic: ID3v2_APIC_Frame_Data) {
	// https://id3.org/id3v2.3.0#:~:text=4.15.%20Attached%20picture
	pos := 0
	apic.text_encoding = ID3v2_Text_Encoding_Type(
		(read_bytes(data, &pos, 1) or_else panic("todo"))[0],
	)
	apic.mime_type = string((read_bytes_until(data, &pos, {0}, true) or_else panic("todo")))
	apic.picture_type = ID3v2_APIC_Picture_Type(
		(read_bytes(data, &pos, 1) or_else panic("todo"))[0],
	)
	bom := read_bytes(data, &pos, 2) or_else panic("todo")
	apic.bom = transmute(type_of(apic.bom))(u16(bom[0]) << 8 | u16(bom[1]))
	apic.raw_description = read_bytes_until(data, &pos, {0, 0}, true) or_else panic("todo")
	desc_u16 := slice.reinterpret([]u16, apic.raw_description)
	if apic.bom == .BE && endian.PLATFORM_BYTE_ORDER == .Little {
		for &b in desc_u16 do b = (b >> 8) | (b << 8)
	}
	apic.description = fmt.aprint(string16(desc_u16))
	apic.data = data[pos:]
	return
}

parse_frame :: proc(data: []u8, pos: ^int) -> (frame_data: ID3v2_Frame_Data) {
	// https://id3.org/id3v2.3.0#:~:text=3.3.%20ID3v2%20frame%20overview
	raw_frame_header := read_bytes(data, pos, 10) or_else panic("Error")
	frame_header, ok := slice.to_type(raw_frame_header, ID3v2_Frame_Header)

	for b in raw_frame_header[4:8] do frame_header.size = frame_header.size << 8 | u32(b)

	raw_data := read_bytes(data, pos, int(frame_header.size)) or_else panic("Error")

	id_s := string(frame_header.id[:])
	type := frame_id_to_type(id_s)

	frame_data = ID3v2_Frame_Data {
		header = frame_header,
		type   = type,
		data   = raw_data,
	}
	if type == .APIC {
		frame_data.data = parse_frame_data_apic(raw_data)
	}
	log.debugf("frame_data=%v", frame_data)

	return
}

parse_frames_for_header :: proc(frames: ^[dynamic]ID3v2_Frame_Data, tag_size: u32, data: []u8) {
	pos := 0
	for pos < int(tag_size) {
		if string(data[pos:][:4]) == "\x00\x00\x00\x00" {
			log.debugf("padding reached at pos=%v", pos)
			return
		}

		frame_data: ID3v2_Frame_Data
		frame_data = parse_frame(data, &pos)
		append(frames, frame_data)
	}
}

sync :: proc(raw: u32) -> (result: [4]u8) {
	assert(raw <= 0x0FFFFFFF)

	shift: u32 = 21
	for index in 0 ..< 4 {
		result[index] = u8(raw >> shift & 127)
		shift -= 7
	}

	return
}
