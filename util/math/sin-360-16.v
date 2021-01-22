/*
 * This IP is the sinus function table implementation.
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

module get_sin_360_16 # (
		parameter USE_REDUCED_SIN_TABLE = "FALSE"
	)(
	input clk_in,
	input [8:0]angle_i,
	output reg signed [15:0]res_o
	);

reg signed [15:0] sin_table [(USE_REDUCED_SIN_TABLE == "TRUE" ? 90 : 359):0];

initial begin
	$readmemh("sin-360-16-table.mem", sin_table);
end

always @ (posedge clk_in)
begin
	if(USE_REDUCED_SIN_TABLE == "TRUE")
	begin
		if(angle_i < 9'd90)
			res_o <= sin_table[angle_i];
		else if(angle_i < 9'd180)
			res_o <= sin_table[9'd180 - angle_i];
		else if(angle_i < 9'd270)
			res_o <= -sin_table[angle_i - 9'd180];
		else
			res_o <= -sin_table[9'd360 - angle_i];
	end
	else
	begin
		res_o <= sin_table[angle_i];
	end
end
endmodule

