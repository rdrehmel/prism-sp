/*
 * Copyright (c) 2021-2023 Robert Drehmel
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
module gem_rx_w_status_encoder(
	input wire logic [44:0] rx_w_status,
	input wire logic [12:0] frame_length,
	output wire logic [31:0] out
);

// indicates a code error.
wire logic rx_w_code_error = rx_w_status[44];
// indicates the frame is too long.
wire logic rx_w_too_long = rx_w_status[43];
// indicates the frame is too short.
wire logic rx_w_too_short = rx_w_status[42];
// indicates the frame has a bad crc.
wire logic rx_w_crc_error = rx_w_status[41];
// indicates the length field is checked and is incorrect.
wire logic rx_w_length_error = rx_w_status[40];
// indicates the frame is SNAP encoded and has either no
// VLAN tag or a VLAN tag with the CFI bit not set.
wire logic rx_w_snap_match = rx_w_status[39];
// indicates the UDP checksum is checked and is correct.
wire logic rx_w_checksumu = rx_w_status[38];
// indicates the TCP checksum is checked and is correct.
wire logic rx_w_checksumt = rx_w_status[37];
// indicates the IP checksum is checked and is correct.
wire logic rx_w_checksumi = rx_w_status[36];
// received frame is matched on type ID register 4.
wire logic rx_w_type_match4 = rx_w_status[35];
// received frame is matched on type ID register 3.
wire logic rx_w_type_match3 = rx_w_status[34];
// received frame is matched on type ID register 2.
wire logic rx_w_type_match2 = rx_w_status[33];
// received frame is matched on type ID register 1.
wire logic rx_w_type_match1 = rx_w_status[32];
// received frame is matched on specific address reg 4.
wire logic rx_w_add_match4 = rx_w_status[31];
// received frame is matched on specific address reg 3.
wire logic rx_w_add_match3 = rx_w_status[30];
// received frame is matched on specific address reg 2.
wire logic rx_w_add_match2 = rx_w_status[29];
// received frame is matched on specific address reg 1.
wire logic rx_w_add_match1 = rx_w_status[28];
// received frame is matched by ext_match4 input signal.
wire logic rx_w_ext_match4 = rx_w_status[27];
// received frame is matched by ext_match3 input signal.
wire logic rx_w_ext_match3 = rx_w_status[26];
// received frame is matched by ext_match2 input signal.
wire logic rx_w_ext_match2 = rx_w_status[25];
// received frame is matched by ext_match1 input signal.
wire logic rx_w_ext_match1 = rx_w_status[24];
// received frame is matched as a unicast hash frame.
wire logic rx_w_uni_hash_match = rx_w_status[23];
// received frame matched as multicast hash frame.
wire logic rx_w_mult_hash_match = rx_w_status[22];
// received frame is a broadcast frame.
wire logic rx_w_broadcast_frame = rx_w_status[21];
// VLAN priority tag detected with received packet.
wire logic rx_w_prty_tagged = rx_w_status[20];
// VLAN priority of a received packet.
wire logic [3:0] rx_w_tci = rx_w_status[19:16];
// VLAN tag detected with a received packet.
wire logic rx_w_vlan_tagged = rx_w_status[15];
// a received packet is bad.
wire logic rx_w_bad_frame = rx_w_status[14];
// number of bytes in a received packet.
wire logic [13:0] rx_w_frame_length = rx_w_status[13:0];

var logic [1:0] add_match;
always_comb begin
	add_match = '0;
	case (1'b1)
	rx_w_add_match4: add_match = 2'b11;
	rx_w_add_match3: add_match = 2'b10;
	rx_w_add_match2: add_match = 2'b01;
	rx_w_add_match1: add_match = 2'b00;
	endcase
end

var logic [1:0] typeid_match;
always_comb begin
	typeid_match = '0;
	case (1'b1)
	rx_w_type_match4: typeid_match = 2'b11;
	rx_w_type_match3: typeid_match = 2'b10;
	rx_w_type_match2: typeid_match = 2'b01;
	rx_w_type_match1: typeid_match = 2'b00;
	endcase
end

var logic [1:0] chksum_enc;
always_comb begin
	// if ((rx_w_checksumu|rx_w_checksumt|rx_w_checksumi) == 1'b0) begin
	chksum_enc = 2'b00;

	if (rx_w_checksumi & ~(rx_w_checksumu|rx_w_checksumt)) begin
		chksum_enc = 2'b01;
	end
	else if (rx_w_checksumi & rx_w_checksumt) begin
		chksum_enc = 2'b10;
	end
	else if (rx_w_checksumi & rx_w_checksumu) begin
		chksum_enc = 2'b11;
	end
end

assign out = {
	// 31
	rx_w_broadcast_frame,
	// 30
	rx_w_mult_hash_match,
	// 29
	rx_w_uni_hash_match,
	// 28
	rx_w_ext_match1 | rx_w_ext_match2 | rx_w_ext_match3 | rx_w_ext_match4,
	// 27 
	rx_w_add_match1 | rx_w_add_match2 | rx_w_add_match3 | rx_w_add_match4,
	// 26:25
	add_match,
	// 24 (not supported)
	1'b0,
	// 23:22 either or type id match status or RX checksum offloading status,
	//       depending on whether RX checksum offloading is disabled.
	//       We only support enabled checksum offloading for now.
	//typeid_match,
	chksum_enc,
	// 21
	rx_w_vlan_tagged,
	// 20
	rx_w_prty_tagged,
	// 19:17 VLAN priority. Not supported for now, because the GEM FIFO interface
	//       provides 4 bits of VLAN priority information and the DMA descriptor
	//       provides 3 bits of VLAN priority information and it's unclear to me
	//       how to map them.
	3'b000,
	// 16 see previous comment
	1'b0,
	// 15 end of frame
	1'b1,
	// 14 start of frame
	1'b1,
	// 13 fcs status
	1'b0,
	// 12:0 frame length
	frame_length
};

endmodule
