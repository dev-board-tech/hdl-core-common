/*
 * This IP is the ATMEGA USB2UART implementation.
 * 
 * Copyright (C) 2020  Iulian Gheorghiu (morgoth@devboard.tech)
 * 
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 */
 
`timescale 1ns / 1ps


// UCSRA
`define RXC		7
`define TXC		6
`define UDRE	5
`define FE		4
`define DOR		3
`define UPE		2
`define U2X		1
`define MPCM	0
// UCSRB
`define RXCIE	7
`define TXCIE	6
`define UDREIE	5
`define RXEN	4
`define TXEN	3
`define UCSZ2	2
`define RXB8	1
`define TXB8	0
// UCSRC
`define UMSEL1	7
`define UMSEL0	6
`define UPM1	5
`define UPM0	4
`define USBS	3
`define UCSZ1	2
`define UCSZ0	1
`define UCPOL	0
// UCSRD
`define CTSEN	1
`define RTSEN	0


module atmega_usb2uart # (
	parameter PLATFORM = "XILINX",
	parameter BUS_ADDR_DATA_LEN = 8,
	parameter UDR_ADDR = 'hc1,
	parameter UCSRA_ADDR = 'hc8,
	parameter UCSRB_ADDR = 'hc9,
	parameter USE_TX = "TRUE",
	parameter USE_RX = "TRUE"
	)(
	input rst_i,
	input rst_usb_i,
	input clk_i,
	input clk48m_i,
	input [BUS_ADDR_DATA_LEN-1:0]addr_i,
	input wr_i,
	input rd_i,
	input [7:0]bus_i,
	output reg [7:0]bus_o,
	
	output rxc_int_o,
	input rxc_int_ack_i,
	output txc_int_o,
	input txc_int_ack_i,
	output udre_int_o,
	input udre_int_ack_i,

	inout usbp_io,
	inout usbn_io
	);


reg [`RXC:`UDRE]UCSRA;
reg [`RXEN:`TXEN]UCSRB;

reg usb_rst;
always @ (posedge clk48m_i) usb_rst <= rst_usb_i;

reg push_data;
reg [7:0] tx_data;
wire buff_empty;

wire char_received;
wire [7:0] rx_data;
reg [7:0] rx_buffer;
reg pop_data;

usb_cdc_top # (
	.PLATFORM(PLATFORM),
	.USE_ECHO("FALSE"))usb_cdc_top_inst(
	.clk_i(clk_i),
	.clk48m_i(clk48m_i),
	.rst_i(usb_rst),
	.tx_i(UART_RXD),
	.rx_o(UART_TXD),
    .usb_p(usbp_io),
    .usb_n(usbn_io),
	
	.rx_valid_i(push_data),
	.rx_data_i(tx_data),
	.rx_accept_o(buff_empty),

	.tx_valid_o(char_received),
	.tx_data_o(rx_data),
	.tx_accept_i(pop_data)
);

/* Tx dual frequency bus adapter */
reg push_p;
reg push_n;
always @ (posedge clk_i) begin
	if(rst_i)
		push_p <= 0;
	else begin
		if(push_p == push_n && addr_i == UDR_ADDR && wr_i) begin
			push_p <= ~push_p;
			tx_data <= bus_i;
		end
	end
end

always @ (posedge clk48m_i) begin
	push_data <= 1'b0;
	if(usb_rst)
		push_n <= 0;
	else begin
		if(push_n != push_p && buff_empty) begin
			push_n <= ~push_n;
			push_data <= 1'b1;
		end
	end
end
/* Rx dual frequency bus adapter */
reg pop_p;
reg pop_n;
always @ (posedge clk_i) begin
	if(rst_i)
		pop_n <= 0;
	else begin
		if(pop_n != pop_p && ((addr_i == UDR_ADDR && rd_i) || ~UCSRB[`RXEN])) begin
			pop_n <= ~pop_n;
		end
	end
end

always @ (posedge clk48m_i) begin
	pop_data <= 1'b0;
	if(usb_rst)
		pop_p <= 0;
	else begin
		if(pop_p == pop_n && char_received) begin
			pop_p <= ~pop_p;
			pop_data <= 1'b1;
			rx_buffer <= rx_data;
		end
	end
end
	
always @(posedge clk_i) UCSRA[`UDRE] <= push_n == push_p;
always @(posedge clk_i) UCSRA[`RXC] <= pop_p != pop_n;
	
always @(posedge clk_i) begin
	if(wr_i && addr_i == UCSRB_ADDR)
	begin
		UCSRB[`RXEN] <= bus_i[`RXEN];
		UCSRB[`TXEN] <= bus_i[`TXEN];
	end
end

always @ *
begin
	if(rst_i)
	begin
		bus_o = 8'b0;
	end
	else
	begin
		bus_o = 8'b0;
		if(rd_i)
		begin
			case(addr_i)
				UDR_ADDR: bus_o = rx_buffer;
				UCSRA_ADDR: 
				begin
					bus_o[`UDRE] = UCSRA[`UDRE];
					bus_o[`RXC] = UCSRA[`RXC];
				end
				UCSRB_ADDR: 
				begin
					bus_o[`RXEN] = UCSRB[`RXEN];
					bus_o[`TXEN] = UCSRB[`TXEN];
				end
			endcase
		end
	end
end
endmodule