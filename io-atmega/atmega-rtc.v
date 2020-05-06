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

module rtc #(
	parameter PERIOD_STATIC = 0,
	parameter CNT_SIZE = 10
	)(
	input rst,
	input clk,
	output intr,
	input int_rst
	);

reg int_rst_int_p;
reg int_rst_int_n;

reg [CNT_SIZE-1:0]CNT;

always @ (posedge clk)
begin
	if(rst)
		int_rst_int_n <= 'h0;
	else if(int_rst & intr)
		int_rst_int_n <= ~int_rst_int_n;
end

always @ (posedge clk)
begin
	if(rst)
	begin
		CNT <= 'h00;
		int_rst_int_p <= 'h0;
	end
	else
	begin
		if(CNT >= PERIOD_STATIC - 1)
		begin
			CNT <= 'h0;
			if(PERIOD_STATIC)
			begin
				if(~intr)
				begin
					int_rst_int_p <= ~int_rst_int_p;
				end
			end
		end
		else if(PERIOD_STATIC)
		begin
			CNT <= CNT + 1;
		end
	end
end
 
assign intr = int_rst_int_n ^ int_rst_int_p;

endmodule
