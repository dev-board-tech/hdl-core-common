/*
 * This IP is the Simple VGA implementation.
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

module vga_simple #(
	//parameter MASTER = "TRUE",
	parameter DEBUG = "PATERN_RASTER",//"PATERN_RASTER"
	parameter DISPLAY_CFG = "",
	
	parameter VRAM_BUFFERED_OUTPUT = "TRUE",
	parameter ADDRESS = 0,
	parameter BUS_VRAM_ADDR_LEN = 24,
	parameter PIXEL_SIZE_CONF = 24,

	parameter H_RES_CONF = 800,
	parameter H_BACK_PORCH_CONF = 46,
	parameter H_FRONT_PORCH_CONF = 210,
	parameter H_PULSE_WIDTH_CONF = 2,
	parameter V_RES_CONF = 480,
	parameter V_BACK_PORCH_CONF = 23,
	parameter V_FRONT_PORCH_CONF = 22,
	parameter V_PULSE_WIDTH_CONF = 2,
	parameter HSYNK_INVERTED_CONF = 1'b1,
	parameter VSYNK_INVERTED_CONF = 1'b1,
	parameter DATA_ENABLE_INVERTED_CONF = 1'b0,
	
	parameter COLOR_INVERTED = "FALSE",

	parameter DEDICATED_VRAM_SIZE = 0
)(
	input rst_i,

	input lcd_clk_i,
	output reg lcd_h_synk_o,
	output reg lcd_v_synk_o,
	output reg[7:0]lcd_r_o,
	output reg[7:0]lcd_g_o,
	output reg[7:0]lcd_b_o,
	output lcd_de_o,
	
	output [BUS_VRAM_ADDR_LEN-1:0]vram_addr_o,
	output [12:0]h_pos_o,
	output [12:0]v_pos_o,
	input [(PIXEL_SIZE_CONF == 1 ? 0 : 31):0]video_data_i
);

/* Here we select configuration values between dinamic configuration and static configuration. */
reg [10:0]h_res_int;
reg [7:0]h_pulse_width_int;
reg [7:0]h_back_porch_int;
reg [7:0]h_front_porch_int;
reg [10:0]v_res_int;
reg [7:0]v_pulse_width_int;
reg [7:0]v_back_porch_int;
reg [7:0]v_front_porch_int;
wire [5:0]pixel_size_int = PIXEL_SIZE_CONF;
reg hsynk_inverted_int;
reg vsynk_inverted_int;
reg [12:0]h_cnt;
reg [12:0]v_cnt;
reg data_enable_inverted_int;

always @ *
begin
	if(DISPLAY_CFG == "640_480_60_CRT_27_17_Mhz")
	begin
		h_res_int 				= 640;
		h_back_porch_int 		= 48;
		h_front_porch_int 		= 16;
		h_pulse_width_int	 	= 96;
		v_res_int 				= 480;
		v_back_porch_int 		= 33;
		v_front_porch_int 		= 10;
		v_pulse_width_int 		= 2;
		hsynk_inverted_int		= 0;
		vsynk_inverted_int		= 0;
		data_enable_inverted_int= 0;
	end
	else
	if(DISPLAY_CFG == "640_480_60_DISPLAY_24_20_Mhz")
	begin
		h_res_int 				= 640;
		h_back_porch_int 		= 72;
		h_front_porch_int 		= 24;
		h_pulse_width_int	 	= 32;
		v_res_int 				= 480;
		v_back_porch_int 		= 32;
		v_front_porch_int 		= 10;
		v_pulse_width_int 		= 3;
		hsynk_inverted_int		= 0;
		vsynk_inverted_int		= 0;
		data_enable_inverted_int= 0;
	end
	else
	if(DISPLAY_CFG == "720_480_60_DISPLAY_27_00_Mhz")
	begin
		h_res_int 				= 720;
		h_back_porch_int 		= 60;
		h_front_porch_int 		= 16;
		h_pulse_width_int	 	= 62;
		v_res_int 				= 480;
		v_back_porch_int 		= 30;
		v_front_porch_int 		= 9;
		v_pulse_width_int 		= 6;
		hsynk_inverted_int		= 0;
		vsynk_inverted_int		= 0;
		data_enable_inverted_int= 0;
	end
	else
	if(DISPLAY_CFG == "800_600_60_DISPLAY_40_00_Mhz")
	begin
		h_res_int 				= 800;
		h_back_porch_int 		= 88;
		h_front_porch_int 		= 40;
		h_pulse_width_int	 	= 128;
		v_res_int 				= 600;
		v_back_porch_int 		= 23;
		v_front_porch_int 		= 4;
		v_pulse_width_int 		= 5;
		hsynk_inverted_int		= 0;
		vsynk_inverted_int		= 0;
		data_enable_inverted_int= 0;
	end
	else
	if(DISPLAY_CFG == "1024_768_60_DISPLAY_65_00_Mhz")
	begin
		h_res_int 				= 1024;
		h_back_porch_int 		= 160;
		h_front_porch_int 		= 24;
		h_pulse_width_int	 	= 136;
		v_res_int 				= 768;
		v_back_porch_int 		= 29;
		v_front_porch_int 		= 3;
		v_pulse_width_int 		= 6;
		hsynk_inverted_int		= 0;
		vsynk_inverted_int		= 0;
		data_enable_inverted_int= 0;
	end
	else
	if(DISPLAY_CFG == "1280_720_60_DISPLAY_74_25_Mhz")
	begin
		h_res_int 				= 1280;
		h_back_porch_int 		= 220;
		h_front_porch_int 		= 70;
		h_pulse_width_int	 	= 80;
		v_res_int 				= 720;
		v_back_porch_int 		= 25;
		v_front_porch_int 		= 3;
		v_pulse_width_int 		= 5;
		hsynk_inverted_int		= 0;
		vsynk_inverted_int		= 0;
		data_enable_inverted_int= 0;
	end
	else
	if(DISPLAY_CFG == "1400_1050_60_DISPLAY_119_00_Mhz")/* Working at 100Mhz pixel clock rate on -1 grade device */
	begin
		h_res_int 				= 1400;
		h_back_porch_int 		= 80;
		h_front_porch_int 		= 48;
		h_pulse_width_int	 	= 32;
		v_res_int 				= 1050;
		v_back_porch_int 		= 21;
		v_front_porch_int 		= 3;
		v_pulse_width_int 		= 6;
		hsynk_inverted_int		= 0;
		vsynk_inverted_int		= 0;
		data_enable_inverted_int= 0;
	end
	else
	if(DISPLAY_CFG == "1440_900_60_DISPLAY_106_50_Mhz")/* Working at 100Mhz pixel clock rate on -1 grade device */
	begin
		h_res_int 				= 1440;
		h_back_porch_int 		= 232;
		h_front_porch_int 		= 80;
		h_pulse_width_int	 	= 152;
		v_res_int 				= 900;
		v_back_porch_int 		= 25;
		v_front_porch_int 		= 3;
		v_pulse_width_int 		= 6;
		hsynk_inverted_int		= 0;
		vsynk_inverted_int		= 0;
		data_enable_inverted_int= 0;
	end
	else
	if(DISPLAY_CFG == "1680_1050_60_DISPLAY_146_25_Mhz")/* Not working (To fast, maybe will work on -2 grade devices) */
	begin
		h_res_int 				= 1680;
		h_back_porch_int 		= 280;
		h_front_porch_int 		= 104;
		h_pulse_width_int	 	= 176;
		v_res_int 				= 1050;
		v_back_porch_int 		= 30;
		v_front_porch_int 		= 3;
		v_pulse_width_int 		= 6;
		hsynk_inverted_int		= 1;
		vsynk_inverted_int		= 0;
		data_enable_inverted_int= 0;
	end
	else
	if(DISPLAY_CFG == "1920_1080_30_DISPLAY_74_25_Mhz")
	begin
		h_res_int 				= 1920;
		h_back_porch_int 		= 148;
		h_front_porch_int 		= 88;
		h_pulse_width_int	 	= 44;
		v_res_int 				= 1080;
		v_back_porch_int 		= 36;
		v_front_porch_int 		= 4;
		v_pulse_width_int 		= 5;
		hsynk_inverted_int		= 1;
		vsynk_inverted_int		= 0;
		data_enable_inverted_int= 0;
	end
	else
	if(DISPLAY_CFG == "1920_1080_60_DISPLAY_148_5_Mhz")/* Not working (To fast, maybe will work on -2 grade devices) */
	begin
		h_res_int 				= 1920;
		h_back_porch_int 		= 236;
		h_front_porch_int 		= 88;
		h_pulse_width_int	 	= 44;
		v_res_int 				= 1080;
		v_back_porch_int 		= 40;
		v_front_porch_int 		= 4;
		v_pulse_width_int 		= 5;
		hsynk_inverted_int		= 1;
		vsynk_inverted_int		= 0;
		data_enable_inverted_int= 0;
	end
	else
	if(DISPLAY_CFG == "AT070TN92_60_LCD_33_26_Mhz")
	begin
		h_res_int 				= 800;
		h_back_porch_int 		= 44;
		h_front_porch_int 		= 210;
		h_pulse_width_int	 	= 2;
		v_res_int 				= 480;
		v_back_porch_int 		= 21;
		v_front_porch_int 		= 22;
		v_pulse_width_int 		= 2;
		hsynk_inverted_int		= 0;
		vsynk_inverted_int		= 0;
		data_enable_inverted_int= 0;
	end
	else
	begin
		h_res_int 				= H_RES_CONF;
		h_back_porch_int 		= H_BACK_PORCH_CONF;
		h_front_porch_int 		= H_FRONT_PORCH_CONF;
		h_pulse_width_int	 	= H_PULSE_WIDTH_CONF;
		v_res_int 				= V_RES_CONF;
		v_back_porch_int 		= V_BACK_PORCH_CONF;
		v_front_porch_int 		= V_FRONT_PORCH_CONF;
		v_pulse_width_int 		= V_PULSE_WIDTH_CONF;
		hsynk_inverted_int		= HSYNK_INVERTED_CONF;
		vsynk_inverted_int		= VSYNK_INVERTED_CONF;
		data_enable_inverted_int= DATA_ENABLE_INVERTED_CONF;
	end
end
/* Here we calculate the total area to count for vertical & horisontal display area. */
wire [16:0]h_total_area = h_pulse_width_int + h_back_porch_int + h_res_int + h_front_porch_int;
wire [16:0]v_total_area = v_pulse_width_int + v_back_porch_int + v_res_int + v_front_porch_int;
/* Here are the H, V and data_enable intermediate wires. */
reg lcd_h_synk_int;
reg lcd_v_synk_int;
/* Here we select to use direct or inverse H, V and data_enable signals. */
	//if(VRAM_BUFFERED_OUTPUT != "TRUE")
	//begin
//assign lcd_h_synk_o = hsynk_inverted_int ^ lcd_h_synk_int;
//assign lcd_v_synk_o = vsynk_inverted_int ^ lcd_v_synk_int;
	//end
reg data_enable_int;
assign lcd_de_o = data_enable_inverted_int ^ data_enable_int;
/* This is the video ram counter, will contain the real address of the displayed pixel. */
reg [BUS_VRAM_ADDR_LEN-1:0]vram_mem_addr_cnt;
/* This registers are the intermediate registers for the output RGB colors. */
reg [7:0]lcd_r_int;
reg [7:0]lcd_g_int;
reg [7:0]lcd_b_int;
/* At this moment we use BRAM video ram memory, further we will develop the external memory access from a DMA like IP. */
//(* ram_style="block" *)
//reg [PIXEL_SIZE_CONF-1:0] vmem [(DEDICATED_VRAM_SIZE ? DEDICATED_VRAM_SIZE - 1 : 0):0];
/* This is an intermediary register that stores the pixel data taken from VRAM untranslated. */
reg [31:0]vmem_out_int;
/* This register will store the decoded RGB pixel data from other formats like 565. */
reg [31:0]vmem_raster_int;
/* This register is used to store most significand byte to store 16 bit configuration registry. */
reg [7:0]ctrl_write_tmp;

reg [(PIXEL_SIZE_CONF == 1 ? 0 : 7):0]cnt_colors;

always @ (posedge lcd_clk_i)
begin
	if(rst_i)
	begin
		vram_mem_addr_cnt <= 'h0;
		h_cnt <= 'h0;
		v_cnt <= 'h0;
		if(DEBUG == "PATERN_RASTER")
			cnt_colors <= 'h0;
	end
	else
	begin
/* Here we select to use direct or inverse H, V and data_enable signals. */
		if(VRAM_BUFFERED_OUTPUT == "TRUE")
		begin
			lcd_h_synk_o <= hsynk_inverted_int ^ lcd_h_synk_int;
			lcd_v_synk_o <= vsynk_inverted_int ^ lcd_v_synk_int;
		end
		h_cnt <= h_cnt + 1;
		if(data_enable_int)
		begin
			vram_mem_addr_cnt <= vram_mem_addr_cnt + 1;
		end
		if(h_cnt == h_total_area)
		begin
			h_cnt <= 'h0;
			v_cnt <= v_cnt + 1;
			if(v_cnt == v_total_area)
			begin
				v_cnt <= 'h0;
				vram_mem_addr_cnt <= 'h0;
				if(DEBUG == "PATERN_RASTER")
					cnt_colors <= cnt_colors + 1;
			end
		end
		//if(MASTER != "TRUE")
			//vmem_raster_int <= vmem[vram_mem_addr_cnt];
	end
end

always @ *
begin
/* Here we select to use direct or inverse H, V and data_enable signals. */
	if(VRAM_BUFFERED_OUTPUT != "TRUE")
	begin
		lcd_h_synk_o <= hsynk_inverted_int ^ lcd_h_synk_int;
		lcd_v_synk_o <= vsynk_inverted_int ^ lcd_v_synk_int;
	end
	//if(MASTER == "TRUE")
		vmem_raster_int = video_data_i;
	if(PIXEL_SIZE_CONF != 1)
	begin
		if(pixel_size_int == 8)
		begin
			lcd_r_int = {vmem_raster_int[2:0], 5'h0};
			lcd_g_int = {vmem_raster_int[4:3], 6'h0};
			lcd_b_int = {vmem_raster_int[7:5], 5'h0};
		end 
		else if(pixel_size_int == 16)
		begin
			lcd_r_int = {vmem_raster_int[4:0], 3'h0};
			lcd_g_int = {vmem_raster_int[10:5], 2'h0};
			lcd_b_int = {vmem_raster_int[15:11], 3'h0};
		end 
		else
		begin
			lcd_r_int = vmem_raster_int[7:0];
			lcd_g_int = vmem_raster_int[15:8];
			lcd_b_int = vmem_raster_int[23:16];
		end 
	end
end

always @ *
begin
	lcd_h_synk_int <= h_cnt < h_pulse_width_int;
	lcd_v_synk_int <= v_cnt < v_pulse_width_int;
	data_enable_int <= h_cnt >= h_pulse_width_int + h_back_porch_int && h_cnt < h_pulse_width_int + h_back_porch_int + h_res_int && v_cnt >= v_pulse_width_int + v_back_porch_int && v_cnt < v_pulse_width_int + v_back_porch_int + v_res_int;
/* Here we select between debug mode and vram mode pixel display. */
	if(PIXEL_SIZE_CONF == 1)
	begin
		{lcd_r_o, lcd_g_o, lcd_b_o} = ((DEBUG == "PATERN_RASTER") ? h_cnt[0] + cnt_colors[0] : video_data_i[0]) ? 24'hFFFFFF : 24'h000000;
	end
	else
	begin
		lcd_r_o = (DEBUG == "PATERN_RASTER") ? h_cnt + cnt_colors : lcd_r_int;
		lcd_g_o = (DEBUG == "PATERN_RASTER") ? h_cnt + v_cnt + cnt_colors : lcd_g_int;
		lcd_b_o = (DEBUG == "PATERN_RASTER") ? h_cnt + v_cnt + v_cnt + cnt_colors : lcd_b_int; // RB
	end
end

assign h_pos_o = h_cnt - (h_pulse_width_int + h_back_porch_int);// - (VRAM_BUFFERED_OUTPUT != "TRUE" ? 1 : 0);
assign v_pos_o = v_cnt - (v_pulse_width_int + v_back_porch_int);
assign vram_addr_o = vram_mem_addr_cnt;

endmodule
