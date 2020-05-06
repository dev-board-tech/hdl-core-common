/*
 * This IP is the ATMEGA PIO implementation.
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
 
/************************************************************/
/* Atention!  This file contain platform dependent modules. */
/************************************************************/

`timescale 1ns / 1ps


module atmega_pio # (
	parameter PLATFORM = "XILINX",
	parameter BUS_ADDR_DATA_LEN = 8,
	parameter PORT_WIDTH = 8,
	parameter PORT_OUT_ADDR = 'h20,
	parameter DDR_ADDR = 'h23,
	parameter PIN_ADDR = 'h24,
	parameter PINMASK = 'hFF,
	parameter PULLUP_MASK = 'h0,
	parameter PULLDN_MASK = 'h0,
	parameter INVERSE_MASK = 'h0,
	parameter OUT_ENABLED_MASK = 'hFF,
	parameter INITIAL_OUTPUT_VALUE = 'h00
)(
	input rst,
	input clk,

	input [BUS_ADDR_DATA_LEN-1:0]addr,
	input wr,
	input rd,
	input [PORT_WIDTH - 1:0]bus_in,
	output reg [PORT_WIDTH - 1:0]bus_out,

	input [PORT_WIDTH - 1:0]io_in,
	output [PORT_WIDTH - 1:0]io_out,
	output [PORT_WIDTH - 1:0]pio_out_io_connect
	);

reg [PORT_WIDTH - 1:0]DDR;
reg [PORT_WIDTH - 1:0]PORT;
reg [PORT_WIDTH - 1:0]PIN;

localparam BUS_LEN_SHIFT = PORT_WIDTH > 16 ? 2 : (PORT_WIDTH > 8 ? 1 : 0);

integer cnt_int;

always @ (posedge clk)
begin
	if(rst)
	begin
		DDR <= 0;
		PORT <= INITIAL_OUTPUT_VALUE;
		PIN <=  0;
	end
	else
	begin
		for (cnt_int = 0; cnt_int < PORT_WIDTH; cnt_int = cnt_int + 1)
		begin
			if (PINMASK[cnt_int])
			begin
				PIN[cnt_int] <= io_in[cnt_int];
				if(wr)
				begin
					case(addr[BUS_ADDR_DATA_LEN-1 : BUS_LEN_SHIFT])
					DDR_ADDR[BUS_ADDR_DATA_LEN-1 : BUS_LEN_SHIFT]: DDR[cnt_int] <= bus_in[cnt_int];
					PORT_OUT_ADDR[BUS_ADDR_DATA_LEN-1 : BUS_LEN_SHIFT]: PORT[cnt_int] <= bus_in[cnt_int];
					endcase
				end
			end
		end
	end
end

always @ *
begin
	for (cnt_int = 0; cnt_int < PORT_WIDTH; cnt_int = cnt_int + 1)
	begin
		if (PINMASK[cnt_int])
		begin
			bus_out[cnt_int] = 1'b0;
			if(rd & ~rst)
			begin
				case(addr[BUS_ADDR_DATA_LEN-1 : BUS_LEN_SHIFT])
					PORT_OUT_ADDR[BUS_ADDR_DATA_LEN-1 : BUS_LEN_SHIFT]: bus_out[cnt_int] = PORT[cnt_int];
					DDR_ADDR[BUS_ADDR_DATA_LEN-1 : BUS_LEN_SHIFT]: bus_out[cnt_int] = DDR[cnt_int];
					PIN_ADDR[BUS_ADDR_DATA_LEN-1 : BUS_LEN_SHIFT]: bus_out[cnt_int] = INVERSE_MASK[cnt_int] ? ~PIN[cnt_int] : PIN[cnt_int];
				endcase
			end
		end
		else
			bus_out[cnt_int] = 1'b0;
	end
end

genvar cnt;
generate

for (cnt = 0; cnt < PORT_WIDTH; cnt = cnt + 1)
begin:OUTS_CONNECT
	assign pio_out_io_connect[cnt] = (PINMASK[cnt] & OUT_ENABLED_MASK[cnt]) ? DDR[cnt] : 1'b0;
end

for (cnt = 0; cnt < PORT_WIDTH; cnt = cnt + 1)
begin:OUTS
	if (PINMASK[cnt] & OUT_ENABLED_MASK[cnt])
	begin
		assign io_out[cnt] = DDR[cnt] ? (INVERSE_MASK[cnt] ? ~PORT[cnt] : PORT[cnt]) : 1'bz;
	end
	else
	begin
		assign io_out[cnt] = 1'bz;
	end
end

for (cnt = 0; cnt < PORT_WIDTH; cnt = cnt + 1)
begin:PULLUPS
	if (PULLUP_MASK[cnt] & PINMASK[cnt])
	begin
		if (PLATFORM == "XILINX")
		begin
			PULLUP PULLUP_inst (
				.O(io_out[cnt])     // PullUp output (connect directly to top-level port)
			);
		end
	end
end

for (cnt = 0; cnt < PORT_WIDTH; cnt = cnt + 1)
begin:PULLDOWNS
	if (PULLDN_MASK[cnt] & PINMASK[cnt])
	begin
		if (PLATFORM == "XILINX")
		begin
			PULLDOWN PULLDOWN_inst (
				.O(io_out[cnt])     // PullDown output (connect directly to top-level port)
			);
		end
	end
end

endgenerate


endmodule
