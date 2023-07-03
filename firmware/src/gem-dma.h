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
#ifndef _GEM_DMA_H_
#define _GEM_DMA_H_

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

static inline uint32_t
gem_tx_dma_desc0_get_addr(gem_tx_dma_desc_word_type desc)
{
	return desc;
}

static inline int
gem_tx_dma_desc1_get_length(gem_tx_dma_desc_word_type desc)
{
	// 13:0 is the buffer length
	return desc & 0x3fff;
}

static inline uint32_t
gem_rx_dma_desc0_get_addr(gem_rx_dma_desc_word_type desc)
{
	return desc & ~(uint32_t)0x3;
}

static inline int
gem_rx_dma_desc1_get_length(gem_rx_dma_desc_word_type desc)
{
	return desc & 0x1fff;
}

#endif // _GEM_DMA_H_
