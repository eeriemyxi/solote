package solote

ID3v2_Header :: struct #packed {
	fident:   [3]u8,
	version:  struct {
		major:    u8,
		revision: u8,
	},
	flags:    bit_field u8 {
		unsynchronisation: bool | 1,
		extended_header:   bool | 1,
		experimental:      bool | 1,
	},
	tag_size: u32,
}

ID3v2_Frame_Header :: struct #packed {
	id:             [4]u8,
	size:           u32,
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
}

ID3v2_Frame_Data :: struct {
	type:   ID3v2_Frame_Type,
	header: ID3v2_Frame_Header,
	data:   union {
		[]u8,
		ID3v2_APIC_Frame_Data,
	},
}

ID3v2_Frame_Type :: enum {
	TIT2, // track title (primary display name)
	TPE1, // lead artist / performer
	TPE2, // album artist (critical for compilations)
	TALB, // album name
	TRCK, // track number (often "n" or "n/total")
	TPOS, // disc number (multi-disc releases)
	TDRC, // recording/release date (v2.4 canonical)
	TYER, // year (v2.3 legacy, still very common)
	TCON, // genre (numeric or text)
	APIC, // embedded artwork (cover, booklet, etc.)
	COMM, // comments (language + description aware)
	TXXX, // user-defined text (MusicBrainz, custom tags)
	UFID, // unique identifiers (e.g. MusicBrainz ID)
	POPM, // rating + play count
	USLT, // unsynchronized lyrics
	Unknown,
}

ID3v2_Text_Encoding_Type :: enum u8 {
	ISO_8859_1,
	UTF_16_BOM,
	UTF_16_BE,
	UTF_8,
}

ID3v2_APIC_Picture_Type :: enum u8 {
	Other                      = 0x00,
	File_Icon_32x32_PNG        = 0x01,
	Other_File_Icon            = 0x02,
	Cover_Front                = 0x03,
	Cover_Back                 = 0x04,
	Leaflet_Page               = 0x05,
	Media_Label_Side           = 0x06,
	Lead_Artist                = 0x07,
	Artist                     = 0x08,
	Conductor                  = 0x09,
	Band_Orchestra             = 0x0A,
	Composer                   = 0x0B,
	Lyricist                   = 0x0C,
	Recording_Location         = 0x0D,
	During_Recording           = 0x0E,
	During_Performance         = 0x0F,
	Movie_Video_Screen_Capture = 0x10,
	Bright_Coloured_Fish       = 0x11,
	Illustration               = 0x12,
	Band_Artist_Logotype       = 0x13,
	Publisher_Studio_Logotype  = 0x14,
}

ID3v2_APIC_Frame_Data :: struct {
	text_encoding: ID3v2_Text_Encoding_Type,
	mime_type:     string,
	picture_type:  ID3v2_APIC_Picture_Type,
	description:   string,
	data:          []u8 `fmt:"-"`,
}
