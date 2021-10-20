/*
 * Copyright (c) 2021 Robert Drehmel
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
#ifndef _GEM_H_
#define _GEM_H_

/* Descriptions are taken from the Xilinx UG1085
 */
#define GEM_RX_W_STATUS_FRAME_LENGTH_BITN		0
#define GEM_RX_W_STATUS_FRAME_LENGTH_WIDTH		14

#define GEM_RX_W_STATUS_BAD_FRAME_BITN			14
#define GEM_RX_W_STATUS_VLAN_TAGGED_BITN		15

#define GEM_RX_W_STATUS_TCI_BITN				16
#define GEM_RX_W_STATUS_TCI_WIDTH				4

#define GEM_RX_W_STATUS_PRTY_TAGGED_BITN		20
#define GEM_RX_W_STATUS_BROADCAST_FRAME_BITN	21
#define GEM_RX_W_STATUS_MULT_HASH_MATCH_BITN	22
#define GEM_RX_W_STATUS_UNI_HASH_MATCH_BITN		23
#define GEM_RX_W_STATUS_EXT_MATCH1_BITN			24
#define GEM_RX_W_STATUS_EXT_MATCH2_BITN			25
#define GEM_RX_W_STATUS_EXT_MATCH3_BITN			26
#define GEM_RX_W_STATUS_EXT_MATCH4_BITN			27
#define GEM_RX_W_STATUS_ADD_MATCH1_BITN			28
#define GEM_RX_W_STATUS_ADD_MATCH2_BITN			29
#define GEM_RX_W_STATUS_ADD_MATCH3_BITN			30
#define GEM_RX_W_STATUS_ADD_MATCH4_BITN			31
#define GEM_RX_W_STATUS_TYPE_MATCH1_BITN		32
#define GEM_RX_W_STATUS_TYPE_MATCH2_BITN		33
#define GEM_RX_W_STATUS_TYPE_MATCH3_BITN		34
#define GEM_RX_W_STATUS_TYPE_MATCH4_BITN		35
#define GEM_RX_W_STATUS_CHECKSUMI_BITN			36
#define GEM_RX_W_STATUS_CHECKSUMT_BITN			37
#define GEM_RX_W_STATUS_CHECKSUMU_BITN			38
#define GEM_RX_W_STATUS_SNAP_MATCH_BITN			39
#define GEM_RX_W_STATUS_LENGTH_ERROR_BITN		40
#define GEM_RX_W_STATUS_CRC_ERROR_BITN			41
#define GEM_RX_W_STATUS_TOO_SHORT_BITN			42
#define GEM_RX_W_STATUS_TOO_LONG_BITN			43
#define GEM_RX_W_STATUS_CODE_ERROR_BITN			44

// Bits of the IXR registers
#define MACB_RXDONE_BITN	1		// RX completed
#define MACB_TXDONE_BITN	7		// TX completed

// Bits of the DMA descriptor words
#define GEM_RX_DD0_VALID_BITN					0
#define GEM_RX_DD0_WRAP_BITN					1
#define GEM_RX_DD0_ADDR_BITN					2

#define GEM_RX_DD1_FRAME_LENGTH_BITN			0
#define GEM_RX_DD1_OFFSET_BITN					12
#define GEM_RX_DD1_SOF_BITN						14
#define GEM_RX_DD1_EOF_BITN						15
#define GEM_RX_DD1_CFI_BITN						16
#define GEM_RX_DD1_TCI_BITN						17
#define GEM_RX_DD1_PRTY_TAGGED_BITN				20
#define GEM_RX_DD1_VLAN_TAGGED_BITN				21
#define GEM_RX_DD1_TYPEID_MATCH_BITN			22
#define GEM_RX_DD1_SA_MATCH_BITN				25
#define GEM_RX_DD1_SA_MATCH_VALID_BITN			27
#define GEM_RX_DD1_IOADDR_MATCH_BITN			28
#define GEM_RX_DD1_UNI_HASH_MATCH_BITN			29
#define GEM_RX_DD1_MULTI_HASH_MATCH_BITN		30
#define GEM_RX_DD1_BROADCAST_FRAME_BITN			31

#define GEM_TX_DD0_ADDR_BITN					0
#define GEM_TX_DD1_EOF_BITN						15
#define GEM_TX_DD1_NOCRC_BITN					16
#define GEM_TX_DD1_WRAP_BITN					30
#define GEM_TX_DD1_VALID_BITN					31

#define GEM3_BASE								0xff0e0000
#define GEM_NETWORK_CONFIG_OFFSET				0x004
#define GEM_RECEIVE_Q_PTR_OFFSET				0x018
#define GEM_TRANSMIT_Q_PTR_OFFSET				0x01c
#define GEM_EXTERNAL_FIFO_INTERFACE_OFFSET		0x04c
#define GEM_TRANSMIT_Q1_PTR_OFFSET				0x440
#define GEM_RECEIVE_Q1_PTR_OFFSET				0x480

#define GEM_NETWORK_CONFIG_DATA_BUS_WIDTH_BITN	21
#define TX_META_DESC_NO_CRC_BITN		31

#endif // _GEM_H_
