package solote

import "core:log"
import "core:os/os2"

main :: proc() {
	context.logger = log.create_console_logger()

	if len(os2.args) != 2 {
		log.error("Must provide the file to scan.")
		os2.exit(1)
	}

	filename := os2.args[1]
	file, err := os2.read_entire_file(filename, context.allocator)

	pos := 0
	raw_header := read_bytes(file, &pos, 10) or_else panic("Error")
	header, ok := parse_header(raw_header)
	if !ok {
		log.debugf(
			"header ok=%v, with raw_header=%v and string(raw_header)=",
			ok,
			raw_header,
			string(raw_header),
		)
		log.info("File likely doesn't have ID3 data.")
		os2.exit(1)
	}

	log.debugf("header=%v", header)

	frames: [dynamic]ID3v2_Frame_Data
	parse_frames_for_header(&frames, header.tag_size, file[pos:])
	log.debugf("frames=%v", frames)
}
