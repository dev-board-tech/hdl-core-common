/*
 * This IP is the 2D graphic accelerator implementation.
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

`include "io_s_h.v"

/*
 * The first sixteen addresses after ADDRESS parameter address are used by LCD IP, the next sixteen addresses are used by this IP.
 */

module gfx_accel #(
	parameter DISPLAY_CFG = "1440_900_60_DISPLAY_106_50_Mhz",
	parameter DEBUG = "",//"PATERN_RASTER"
	
	parameter ADDRESS = 0,
	parameter BUS_VRAM_ADDR_LEN = 24,
	parameter BUS_VRAM_DATA_LEN = 8,
	parameter BUS_ADDR_DATA_LEN = 16,
	
	parameter ACCEL_DINAMIC_CONFIG = "FALSE",
	parameter LCD_DINAMIC_CONFIG = "FALSE",
	parameter VRAM_BASE_ADDRESS_CONF = 0,
	parameter H_RES_CONF = 800,
	parameter H_BACK_PORCH_CONF = 46,
	parameter H_FRONT_PORCH_CONF = 210,
	parameter H_PULSE_WIDTH_CONF = 2,
	parameter V_RES_CONF = 480,
	parameter V_BACK_PORCH_CONF = 23,
	parameter V_FRONT_PORCH_CONF = 22,
	parameter V_PULSE_WIDTH_CONF = 2,
	parameter ACCEL_PIXEL_SIZE_CONF = 16,
	parameter LCD_PIXEL_SIZE_CONF = 16,
	parameter HSYNK_INVERTED_CONF = 1'b1,
	parameter VSYNK_INVERTED_CONF = 1'b1,
	parameter DATA_ENABLE_INVERTED_CONF = 1'b0,
	parameter DEDICATED_VRAM_SIZE = 0
	)(
	input rst,
	input ctrl_clk,
    input [BUS_ADDR_DATA_LEN-1:0]ctrl_addr,
	input ctrl_wr,
	input ctrl_rd,
	input [7:0]ctrl_data_in,
	output reg [7:0]ctrl_data_out,
	output req_bus,

	inout [BUS_VRAM_ADDR_LEN-1:0]vmem_addr,
	input [BUS_VRAM_DATA_LEN-1:0]vmem_in,
	output [BUS_VRAM_DATA_LEN-1:0]vmem_out,
	input vmem_rd,
	input vmem_wr,
	
	input lcd_clk,
	output lcd_h_synk,
	output lcd_v_synk,
	output [7:0]lcd_r,
	output [7:0]lcd_g,
	output [7:0]lcd_b,
	output lcd_de
    );

assign req_bus = ctrl_addr >= ADDRESS + 16 && ctrl_addr < (ADDRESS + 32);
wire rd_int = req_bus && ctrl_rd;
wire wr_int = req_bus && ctrl_wr;

wire [BUS_VRAM_ADDR_LEN-1:0]lcd_vmem_addr;
wire [BUS_VRAM_DATA_LEN-1:0]lcd_vmem_in;
wire [BUS_VRAM_DATA_LEN-1:0]lcd_vmem_out;
wire lcd_vmem_rd;
wire lcd_vmem_wr;

wire [7:0]ctrl_data_out_;

lcd # (
	.MASTER("FALSE"),
	.DISPLAY_CFG(DISPLAY_CFG),
	.DEBUG(DEBUG),
	
	.ADDRESS(ADDRESS),
	.BUS_VRAM_ADDR_LEN(BUS_VRAM_ADDR_LEN),
	.BUS_VRAM_DATA_LEN(BUS_VRAM_DATA_LEN),
	.BUS_ADDR_DATA_LEN(BUS_ADDR_DATA_LEN),
	
	.DINAMIC_CONFIG(LCD_DINAMIC_CONFIG),
	.VRAM_BASE_ADDRESS_CONF(0),
	.H_RES_CONF(H_RES_CONF),
	.H_BACK_PORCH_CONF(H_BACK_PORCH_CONF),
	.H_FRONT_PORCH_CONF(H_FRONT_PORCH_CONF),
	.H_PULSE_WIDTH_CONF(H_PULSE_WIDTH_CONF),
	.V_RES_CONF(V_RES_CONF),
	.V_BACK_PORCH_CONF(V_BACK_PORCH_CONF),
	.V_FRONT_PORCH_CONF(V_FRONT_PORCH_CONF),
	.V_PULSE_WIDTH_CONF(V_PULSE_WIDTH_CONF),
	.PIXEL_SIZE_CONF(LCD_PIXEL_SIZE_CONF),
	.HSYNK_INVERTED_CONF(HSYNK_INVERTED_CONF),
	.VSYNK_INVERTED_CONF(VSYNK_INVERTED_CONF),
	.DATA_ENABLE_INVERTED_CONF(DATA_ENABLE_INVERTED_CONF),

	.DEDICATED_VRAM_SIZE(DEDICATED_VRAM_SIZE)
	)lcd_inst(
	.rst(rst),
	.ctrl_clk(ctrl_clk),
    .ctrl_addr(ctrl_addr),
	.ctrl_wr(ctrl_wr),
	.ctrl_rd(ctrl_rd),
	.ctrl_data_in(ctrl_data_in),
	.ctrl_data_out(ctrl_data_out_),

	.vmem_addr(lcd_vmem_addr),
	.vmem_in(lcd_vmem_in),
	.vmem_out(lcd_vmem_out),
	.vmem_rd(lcd_vmem_rd),
	.vmem_wr(lcd_vmem_wr),
	
	.lcd_clk(lcd_clk),
	.lcd_h_synk(lcd_h_synk),
	.lcd_v_synk(lcd_v_synk),
	.lcd_r(lcd_r),
	.lcd_g(lcd_g),
	.lcd_b(lcd_b),
	.lcd_de(lcd_de)
);

reg [7:0]CMD;
reg [10:0]CLIP_X_MIN;
reg [10:0]CLIP_X_MAX;
reg [10:0]CLIP_Y_MIN;
reg [10:0]CLIP_Y_MAX;
reg [31:0]COLOR;
reg [7:0]cmd_int;
reg [10:0]clip_x_min_int;
reg [10:0]clip_x_max_int;
reg [10:0]clip_y_min_int;
reg [10:0]clip_y_max_int;
reg [31:0]color;
reg [31:0]color_int;
reg [10:0]x_cnt_int;
reg [10:0]y_cnt_int;

reg [7:0]tmp_write;
reg [7:0]color_byte_2;
reg [7:0]color_byte_3;
reg direct_vram_access;
reg new_cmd;

reg [10:0]h_res_int;
reg [10:0]v_res_int;
always @ *
begin
	if(DISPLAY_CFG == "640_480_60_CRT_27_17_Mhz")
	begin
		h_res_int 				= 640;
		v_res_int 				= 480;
	end
	else
	if(DISPLAY_CFG == "640_480_60_DISPLAY_24_20_Mhz")
	begin
		h_res_int 				= 640;
		v_res_int 				= 480;
	end
	else
	if(DISPLAY_CFG == "720_480_60_DISPLAY_27_00_Mhz")
	begin
		h_res_int 				= 720;
		v_res_int 				= 480;
	end
	else
	if(DISPLAY_CFG == "800_600_60_DISPLAY_40_00_Mhz")
	begin
		h_res_int 				= 800;
		v_res_int 				= 600;
	end
	else
	if(DISPLAY_CFG == "1024_768_60_DISPLAY_65_00_Mhz")
	begin
		h_res_int 				= 1024;
		v_res_int 				= 768;
	end
	else
	if(DISPLAY_CFG == "1280_720_60_DISPLAY_74_25_Mhz")
	begin
		h_res_int 				= 1280;
		v_res_int 				= 720;
	end
	else
	if(DISPLAY_CFG == "1400_1050_60_DISPLAY_119_00_Mhz")/* Working at 100Mhz pixel clock rate on -1 grade device */
	begin
		h_res_int 				= 1400;
		v_res_int 				= 1050;
	end
	else
	if(DISPLAY_CFG == "1440_900_60_DISPLAY_106_50_Mhz")/* Working at 100Mhz pixel clock rate on -1 grade device */
	begin
		h_res_int 				= 1440;
		v_res_int 				= 900;
	end
	else
	if(DISPLAY_CFG == "1680_1050_60_DISPLAY_146_25_Mhz")/* Not working (To fast, maybe will work on -2 grade devices) */
	begin
		h_res_int 				= 1680;
		v_res_int 				= 1050;
	end
	else
	if(DISPLAY_CFG == "1920_1080_60_DISPLAY_148_5_Mhz")/* Not working (To fast, maybe will work on -2 grade devices) */
	begin
		h_res_int 				= 1920;
		v_res_int 				= 1080;
	end
	else
	if(DISPLAY_CFG == "AT070TN92_60_LCD_33_26_Mhz")
	begin
		h_res_int 				= 800;
		v_res_int 				= 480;
	end
	else
	begin
		h_res_int 				= H_RES_CONF;
		v_res_int 				= V_RES_CONF;
	end
end

always @ (posedge ctrl_clk or posedge rst)
begin
	if(rst)
	begin
		CMD <= `GFX_ACCEL_CMD_FILL_RECT;
		CLIP_X_MIN <= 16'h0000;
		CLIP_X_MAX <= 16'h10;//h_res_int;
		CLIP_Y_MIN <= 16'h0000;
		CLIP_Y_MAX <= 16'h10;//v_res_int;
		COLOR <= 32'h000000FF;
		cmd_int <= 8'h00;
		clip_x_min_int <= 16'h0000;
		clip_x_max_int <= 16'h0000;
		clip_y_min_int <= 16'h0000;
		clip_y_max_int <= 16'h0000;
		x_cnt_int <= 16'h0000;
		y_cnt_int <= 16'h0000;
		
		direct_vram_access <= 1'b0;
		new_cmd  <= 1'b0;
	end
	else
	begin
		if(wr_int && !CMD)
		begin
			case(ctrl_addr[4:0])
			`GFX_ACCEL_CMD: CMD <= ctrl_data_in;
			`GFX_ACCEL_CLIP_X_MIN_L: CLIP_X_MIN <= {tmp_write, ctrl_data_in};
			`GFX_ACCEL_CLIP_X_MIN_H: tmp_write <= ctrl_data_in;
			`GFX_ACCEL_CLIP_X_MAX_L: CLIP_X_MAX <= {tmp_write, ctrl_data_in};
			`GFX_ACCEL_CLIP_X_MAX_H: tmp_write <= ctrl_data_in;
			`GFX_ACCEL_CLIP_Y_MIN_L: CLIP_Y_MIN <= {tmp_write, ctrl_data_in};
			`GFX_ACCEL_CLIP_Y_MIN_H: tmp_write <= ctrl_data_in;
			`GFX_ACCEL_CLIP_Y_MAX_L: CLIP_Y_MAX <= {tmp_write, ctrl_data_in};
			`GFX_ACCEL_CLIP_Y_MAX_H: tmp_write <= ctrl_data_in;
			`GFX_ACCEL_COLOR_BYTE_0: COLOR <= {color_byte_3, color_byte_2, tmp_write, ctrl_data_in};
			`GFX_ACCEL_COLOR_BYTE_1: tmp_write <= ctrl_data_in;
			`GFX_ACCEL_COLOR_BYTE_2: color_byte_2 <= ctrl_data_in;
			`GFX_ACCEL_COLOR_BYTE_3: color_byte_3 <= ctrl_data_in;
			endcase
		end
		else if(!cmd_int && CMD)
		begin
			cmd_int <= CMD;
			clip_x_min_int <= CLIP_X_MIN;
			clip_x_max_int <= CLIP_X_MAX;
			clip_y_min_int <= CLIP_Y_MIN;
			clip_y_max_int <= CLIP_Y_MAX;
			x_cnt_int <= CLIP_X_MIN;
			y_cnt_int <= CLIP_Y_MIN;
			CMD <= 8'h00;
			color <= COLOR;
			new_cmd <= 1'b1;
		end
		else
		begin
			case(cmd_int)
			`GFX_ACCEL_CMD_VRAM_ACCESS: 
			begin
				direct_vram_access <= 1'b1;
				cmd_int <= 'h0;
			end
			`GFX_ACCEL_CMD_CTRL_ACCESS: 
			begin
				direct_vram_access <= 1'b0;
				cmd_int <= 8'h00;
			end
			`GFX_ACCEL_CMD_PIXEL_LOAD:
			begin
				//x_cnt_int <= CLIP_X_MIN;
				//y_cnt_int <= CLIP_Y_MIN;
				//color <= COLOR;
				if(x_cnt_int >= clip_x_max_int)
				begin
					x_cnt_int <= clip_x_min_int;
					y_cnt_int <= x_cnt_int + 1;
					if(y_cnt_int >= clip_y_max_int)
						y_cnt_int <= clip_y_min_int;
				end
				cmd_int <= 8'h00;
			end
			`GFX_ACCEL_CMD_PIXEL:
			begin
				//color <= COLOR;
				if(x_cnt_int >= clip_x_max_int)
				begin
					x_cnt_int <= clip_x_min_int;
					y_cnt_int <= x_cnt_int + 1;
					if(y_cnt_int >= clip_y_max_int)
						y_cnt_int <= clip_y_min_int;
				end
				cmd_int <= 8'h00;
			end
			`GFX_ACCEL_CMD_FILL_RECT:
			begin
				if(~new_cmd)
				begin
					if(x_cnt_int >= clip_x_max_int && y_cnt_int >= clip_y_max_int)
					begin
						cmd_int <= 8'h00;
					end
					else
					begin
						if(x_cnt_int >= clip_x_max_int)
						begin
							x_cnt_int <= clip_x_min_int;
							y_cnt_int <= y_cnt_int + 1;
						end
						else
							x_cnt_int <= x_cnt_int + 1;
					end
				end
			end
			endcase
			if(cmd_int && new_cmd)
			begin
				new_cmd <= 1'b0;
			end
		end
	end
end

always @ *
begin
	if(rd_int)
	begin
		case(ctrl_addr[4:0])
		`GFX_ACCEL_CMD: ctrl_data_out <= CMD;
		default: ctrl_data_out <= 8'h00;
		endcase
	end
	else
	begin
		ctrl_data_out <= ctrl_data_out_;
	end
end

always @ *
begin
	if(LCD_PIXEL_SIZE_CONF == 8 && ACCEL_PIXEL_SIZE_CONF >= 24)
	begin
		color_int <= {color[23:21], color[15:14], color[7:5]};
	end
	else
	if(LCD_PIXEL_SIZE_CONF == 8 && ACCEL_PIXEL_SIZE_CONF == 16)
	begin
		color_int <= {color[15:13], color[10:9], color[4:2]};
	end
	else
	if(LCD_PIXEL_SIZE_CONF == 16 && ACCEL_PIXEL_SIZE_CONF >= 24)
	begin
		color_int <= {color[23:19], color[15:10], color[7:3]};
	end
	else
	begin
		color_int <= color;
	end
end

(* use_dsp48 = "yes" *)
assign lcd_vmem_addr = direct_vram_access ? vmem_addr : (y_cnt_int * h_res_int) + x_cnt_int;
assign lcd_vmem_in = direct_vram_access ? vmem_in : color_int;
assign vmem_out = direct_vram_access ? lcd_vmem_out : 8'h00;
assign lcd_vmem_rd = direct_vram_access ? vmem_rd : 1'b0;
assign lcd_vmem_wr = direct_vram_access ? vmem_wr : (|cmd_int)/* && x_cnt_int != clip_x_max_int && y_cnt_int != clip_y_max_int*/;

endmodule