/*
 * This IP is the RTC timmer implementation.
 * 
 * Copyright (C) 2018  Iulian Gheorghiu (morgoth@devboard.tech)
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

`include "io-s-h.v"

module rtc #(
	parameter PERIOD_STATIC = 0,
	parameter ADDRESS = 0,
	parameter BUS_ADDR_DATA_LEN = 16,
	parameter CNT_SIZE = 10,
	parameter PERIOD_OVERFLOW_WIDTH = 4
	)(
	input rst,
	input clk,
	input [BUS_ADDR_DATA_LEN-1:0]addr,
	input wr_w,
	input rd_w,
	input [31:0]bus_in,
	output reg[31:0]bus_out,
	output req_bus,
	output reg intr,
	input int_rst
	);

assign req_bus = addr >= ADDRESS && addr < (ADDRESS + 16);
wire rd_int = req_bus && rd_w;
wire wr_int = req_bus && wr_w;
reg int_rst_int;
reg int_rst_int_n;

reg [CNT_SIZE-1:0]CNT;
reg [CNT_SIZE-1:0]PERIOD;
reg [PERIOD_OVERFLOW_WIDTH - 1:0]INT_OVF_CNT;

always @ (posedge int_rst or posedge rst)
begin
	if(rst)
		int_rst_int <= 'h0;
	else if(int_rst_int == int_rst_int_n)
		int_rst_int <= ~int_rst_int;
end

always @ (posedge clk or posedge rst)
begin
	if(rst)
	begin
		CNT <= 'h00;
		PERIOD <= PERIOD_STATIC;
		intr <= 1'b0;
		INT_OVF_CNT <= 1'b0;
		int_rst_int_n <= 'h0;
	end
	else
	begin
		if(CNT >= PERIOD - 1)
		begin
			CNT <= 'h0;
			if(PERIOD)
			begin
				intr <= 1'b1;
				INT_OVF_CNT <= INT_OVF_CNT + 1;
			end
		end
		else if(PERIOD)
		begin
			CNT <= CNT + 1;
		end
		if(int_rst_int_n != int_rst_int)
		begin
			int_rst_int_n <= ~int_rst_int_n;
			intr <= 1'b0;
			INT_OVF_CNT <= 1'b0;
		end
		if(wr_int)
		begin
			case(addr[3:0])
			`RTC_CNT: 
			begin
				CNT <= bus_in;
			end
			`RTC_PERIOD: 
			begin
				PERIOD <= bus_in;
			end
			endcase
		end
		else if(rd_int)
		begin
			case(addr[3:0])
			`RTC_STATUS: 
			begin
				INT_OVF_CNT <= 1'b0;
			end
			endcase
		end
	end
	
end
 
always @ (*)
begin
	bus_out <= 32'h00;
	if(rd_int)
	begin
		case(addr[3:0])
		`RTC_CNT: 
		begin
			bus_out <= CNT;
		end
		`RTC_PERIOD: 
		begin
			bus_out <= PERIOD;
		end
		`RTC_STATUS: 
		begin
			bus_out <= INT_OVF_CNT;
		end
		endcase
	end
end

endmodule
