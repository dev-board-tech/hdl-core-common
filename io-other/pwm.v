/*
 * This IP is simple PWM implementation module.
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

module pwm # (
	parameter WIDTH = 2
	)(
	input rst_i,
	input clk_i,
	input en_i,
	input hiz_i,
	input [WIDTH - 1:0]val_i,
	output pwm_o
	);

reg [WIDTH - 1:0]cnt;
reg pwm;

always @ (posedge clk_i)
begin
	if(rst_i | hiz_i | ~en_i)
	begin
		cnt <= {WIDTH{1'b0}};
		pwm <= 1'b0;
	end
	else
	begin
		cnt <= cnt + {{WIDTH-1{1'b0}}, 1'b1};

		if(cnt == val_i)
			pwm <= 1'b0;
		else if(&(~cnt))
			pwm <= 1'b1;
	end
end

assign pwm_o = hiz_i ? 1'bz : pwm;

endmodule