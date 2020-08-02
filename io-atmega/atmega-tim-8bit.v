/*
 * This IP is the ATMEGA 8bit TIMER implementation.
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

//`define TIFR0	('h15)
`define TOV0 0
`define OCF0A 1
`define OCF0B 2

//`define GTCCR	('h23)
`define PSRSYNC 0
`define PSRASY 	1
`define TSM 	7

//`define TCCR0A	('h24)
`define WGM00 	0
`define WGM01 	1
`define COM0B0 	4
`define COM0B1 	5
`define COM0A0 	6
`define COM0A1 	7

//`define TCCR0B	('h25)
`define CS00 	0
`define CS01 	1
`define CS02 	2
`define WGM02 	3
`define FOC0B 	6
`define FOC0A 	7

//`define TCNT0	('h26)
`define OCR0A	('h27)
`define OCR0B	('h28)

//`define TIMSK0	('h6E)
`undef TOIE0
`undef OCIE0A
`undef OCIE0B
`define TOIE0 	0
`define OCIE0A 	1
`define OCIE0B 	2



module atmega_tim_8bit # (
	parameter PLATFORM = "XILINX",
	parameter USE_OCRB = "TRUE",
	parameter BUS_ADDR_DATA_LEN = 8,
	parameter GTCCR_ADDR = 'h43,
	parameter TCCRA_ADDR = 'h44,
	parameter TCCRB_ADDR = 'h45,
	parameter TCNT_ADDR = 'h46,
	parameter OCRA_ADDR = 'h47,
	parameter OCRB_ADDR = 'h48,
	parameter TIMSK_ADDR = 'h6E,
	parameter TIFR_ADDR = 'h35,
	parameter INCREMENT_VALUE = 1
)(
	input rst_i,
	input clk_i,
	input clk8_i,
	input clk64_i,
	input clk256_i,
	input clk1024_i,
	input [BUS_ADDR_DATA_LEN-1:0]addr_i,
	input wr_i,
	input rd_i,
	input [7:0]bus_i,
	output reg [7:0]bus_o,
	
	output tov_int_o,
	input tov_int_ack_i,
	output ocra_int_o,
	input ocra_int_ack_i,
	output ocrb_int_o,
	input ocrb_int_ack_i,
	
	input t_i,
	output reg oca_o,
	output reg ocb_o,
	output oca_io_connect_o,
	output ocb_io_connect_o
	);

//reg [7:0]GTCCR;
reg [7:0]TCCRA;
reg [7:0]TCCRB;
reg [7:0]TCNT;
reg [7:0]OCRA;
reg [7:0]OCRB;
reg [7:0]OCRA_int;
reg [7:0]OCRB_int;
reg [7:0]TIMSK;
reg [7:0]TIFR;

reg tov_p;
reg tov_n;
reg ocra_p;
reg ocra_n;
reg ocrb_p;
reg ocrb_n;

//reg l1;
//reg l2;
wire t0_fall = 0;
wire t0_rising = 0;
reg clk_int;
reg clk_int_del;

reg up_count;

wire clk_active = |TCCRB[`CS02:`CS00];

/* Sampling implementation */
// Accourding to timer sampling module.
/*always @ *
begin
	if(rst_i)
	begin
		l1 = 1'b0;
	end
	else
	if(clk)
	begin
		l1 = t;
	end
end

always @ (posedge clk_i)
begin
	if(rst_i)
	begin
		l2 = 1'b0;
	end
	else
	if(clk)
	begin
		l2 = l1;
	end
end*/
/* !Sampling implementation */

/* Prescaller selection implementation */
always @ *
begin
	case(TCCRB[`CS02:`CS00])
	3'b001: clk_int = clk_i;
	3'b010: clk_int = clk8_i;
	3'b011: clk_int = clk64_i;
	3'b100: clk_int = clk256_i;
	3'b101: clk_int = clk1024_i;
	3'b110: clk_int = t0_fall;
	3'b111: clk_int = t0_rising;
	default: clk_int = 1'b0;
	endcase
end
reg updt_ocr_on_top;
always @ *
begin
	case({TCCRB[`WGM02], TCCRA[`WGM01:`WGM00]})
		3'h0, 3'h2: updt_ocr_on_top = 1'b0;
		default: updt_ocr_on_top = 1'b1;
	endcase
end

reg [7:0]top_value;
always @ *
begin
	case({TCCRB[`WGM02], TCCRA[`WGM01:`WGM00]})
		3'h2, 3'h5, 3'h7: top_value = INCREMENT_VALUE == 2 ? {OCRA_int[7:1], 1'b0} : OCRA_int;
		default: top_value = INCREMENT_VALUE == 2 ? 8'hfe : 8'hff;
	endcase
end

reg [7:0]t_ovf_value;
always @ *
begin
	case({TCCRB[`WGM02], TCCRA[`WGM01:`WGM00]})
		3'd7: t_ovf_value = top_value;
		3'd0, 3'd2, 3'd3: t_ovf_value = INCREMENT_VALUE == 2 ? 8'hfe : 8'hFF;
		default: t_ovf_value = 8'h00;
	endcase
end

// Read registers.
always @ *
begin
	if(rst_i)
	begin
		bus_o = 8'h00;
	end
	else
	begin
		bus_o = 8'h00;
		if(rd_i)
		begin
			case(addr_i)
				//GTCCR_ADDR: bus_io_out = GTCCR;
				TCCRA_ADDR: bus_o = TCCRA;
				TCCRB_ADDR: bus_o = TCCRB;
				TCNT_ADDR: bus_o = TCNT;
				OCRA_ADDR: bus_o = OCRA;
				OCRB_ADDR: bus_o = OCRB;
				TIFR_ADDR: bus_o = TIFR;
			endcase
		end
		if(rd_i & addr_i == TIMSK_ADDR)
			bus_o = TIMSK;
	end
end

/* Set "oc" pin on specified conditions*/
always @ (posedge clk_i)
begin
	if(rst_i)
	begin
		//GTCCR <= 8'h00;
		TCCRA <= 8'h00;
		TCCRB <= 8'h00;
		TCNT <= 8'h00;
		OCRA <= 8'h00;
		OCRB <= 8'h00;
		OCRA_int <= 8'h00;
		OCRB_int <= 8'h00;
		TIMSK <= 8'h00;
		TIFR <= 8'h00;
		tov_p <= 1'b0;
		tov_n <= 1'b0;
		ocra_p <= 1'b0;
		ocra_n <= 1'b0;
		ocrb_p <= 1'b0;
		ocrb_n <= 1'b0;
		oca_o <= 1'b0;
		ocb_o <= 1'b0;
		up_count <= 1'b1;
		clk_int_del <= 1'b0;
	end
	else
	begin
		if(tov_p ^ tov_n)
		begin
			TIFR[`TOV0] <= 1'b1;
			tov_n <= tov_p;
		end	
		if(ocra_p ^ ocra_n)
		begin
			TIFR[`OCF0A] <= 1'b1;
			ocra_n <= ocra_p;
		end	
		if(ocrb_p ^ ocrb_n)
		begin
			TIFR[`OCF0B] <= 1'b1;
			ocrb_n <= ocrb_p;
		end
		if(tov_int_ack_i)
		begin
			TIFR[`TOV0] <= 1'b0;
		end
		if(ocra_int_ack_i)
		begin
			TIFR[`OCF0A] <= 1'b0;
		end
		if(ocrb_int_ack_i)
		begin
			TIFR[`OCF0B] <= 1'b0;
		end
		// Sample one IO core clock once every prescaller positive edge clock.
		clk_int_del <= clk_int; // Shift prescaller clock to a delay register every IO core positive edge clock to detect prescaller positive edges.
		if(((~clk_int_del & clk_int) || TCCRB[`CS02:`CS00] == 3'b001) && TCCRB[`CS02:`CS00] != 3'b000) // if prescaller clock = IO core clock disable prescaller positive edge detector.
		begin
			if(up_count)
				TCNT <= TCNT + INCREMENT_VALUE;
			else
			if(~up_count)
				TCNT <= TCNT - INCREMENT_VALUE;
			// OCRA
			if(updt_ocr_on_top ? (TCNT == 8'hff):(TCNT == OCRA_int))
				OCRA_int <= INCREMENT_VALUE == 2 ? {OCRA[7:1], 1'b0} : OCRA;
			if(TCNT == OCRA_int)
			begin
				case({TCCRB[`WGM02], TCCRA[`WGM01:`WGM00]})
					3'h2: oca_o <= ~oca_o;
					default:
					begin
						case(OCRA_int)
							8'h00:	oca_o <= 1'b0;
							(INCREMENT_VALUE == 2 ? 8'hFE : 8'hFF):	oca_o <= 1'b1;
							default:
							begin
								if(up_count)
								begin
									case(TCCRA[`COM0A1:`COM0A0])
										2'h1: oca_o <= ~oca_o;
										2'h2: oca_o <= 1'b0;
										2'h3: oca_o <= 1'b1;
									endcase
								end
								else
								begin
									case(TCCRA[`COM0A1:`COM0A0])
										2'h1: oca_o <= ~oca_o;
										2'h2: oca_o <= 1'b1;
										2'h3: oca_o <= 1'b0;
									endcase
								end
							end
						endcase
					end
				endcase
				if(TIMSK[`OCIE0A] == 1'b1)
				begin
					if(ocra_p == ocra_n && clk_active == 1'b1)
						ocra_p <= ~ocra_p;
					else
					begin
						ocra_p <= 1'b0;
						ocra_n <= 1'b0;
					end
				end
			end
			// !OCRA
			if(USE_OCRB == "TRUE")
			begin
				// OCRB
				if(updt_ocr_on_top ? (TCNT == 8'hff):(TCNT == OCRB_int))
					OCRB_int <= INCREMENT_VALUE == 2 ? {OCRB[7:1], 1'b0} : OCRB;
				if(TCNT == OCRB_int)
				begin
					case({TCCRB[`WGM02], TCCRA[`WGM01:`WGM00]})
						3'h2: ocb_o <= ~ocb_o;
						default:
						begin
							case(OCRB_int)
								8'h00:	ocb_o <= 1'b0;
								(INCREMENT_VALUE == 2 ? 8'hFE : 8'hFF):	ocb_o <= 1'b1;
								default:
								begin
									if(up_count)
									begin
										case(TCCRA[`COM0B1:`COM0B0])
											2'h1: ocb_o <= ~ocb_o;
											2'h2: ocb_o <= 1'b0;
											2'h3: ocb_o <= 1'b1;
										endcase
									end
									else
									begin
										case(TCCRA[`COM0B1:`COM0B0])
											2'h1: ocb_o <= ~ocb_o;
											2'h2: ocb_o <= 1'b1;
											2'h3: ocb_o <= 1'b0;
										endcase
									end
								end
							endcase
						end
					endcase
					if(TIMSK[`OCIE0B] == 1'b1)
					begin
						if(ocrb_p == ocrb_n && clk_active == 1'b1)
							ocrb_p <= ~ocrb_p;
					end
					else
					begin
						ocrb_p <= 1'b0;
						ocrb_n <= 1'b0;
					end
				end
			end // USE_OCRB != "TRUE"
			// TCNT overflow logick.
			if(TCNT == t_ovf_value)
			begin
				if(TIMSK[`TOIE0] == 1'b1)
				begin
					if(tov_p == tov_n && clk_active == 1'b1)
						tov_p <= ~tov_p;
				end
				else
				begin
					tov_p <= 1'b0;
					tov_n <= 1'b0;
				end
			end
			if(TCNT == top_value)
			begin
				case({TCCRB[`WGM02], TCCRA[`WGM01:`WGM00]})
					3'h1, 3'h5: 
					begin
						up_count <= 1'b0;
						TCNT <= TCNT - INCREMENT_VALUE;
					end 
					default: TCNT <= 8'h00;
				endcase
			end
			else if(TCNT == 8'h00)
			begin
				case({TCCRB[`WGM02], TCCRA[`WGM01:`WGM00]})
					3'h1, 3'h5: 
					begin
						up_count <= 1'b1;
						TCNT <= TCNT + INCREMENT_VALUE;
					end 
				endcase
			end
		end
		// Write registers
		if(wr_i)
		begin
			case(addr_i)
				//GTCCR_ADDR: GTCCR <= bus_io_in;
				TCCRA_ADDR: TCCRA <= bus_i;
				TCCRB_ADDR: TCCRB <= bus_i;
				TCNT_ADDR: TCNT <= INCREMENT_VALUE == 2 ? {bus_i[7:1], 1'b0} : bus_i;
				OCRA_ADDR: OCRA <= INCREMENT_VALUE == 2 ? {bus_i[7:1], 1'b0} : bus_i;
				OCRB_ADDR: OCRB <= INCREMENT_VALUE == 2 ? {bus_i[7:1], 1'b0} : bus_i;
				TIFR_ADDR: TIFR <= TIFR & ~bus_i;
			endcase
		end
		if(wr_i & addr_i == TIMSK_ADDR)
			TIMSK <= bus_i;
	end
end

assign tov_int_o = TIFR[`TOV0];
assign ocra_int_o = TIFR[`OCF0A];
assign ocrb_int_o = TIFR[`OCF0B];

assign oca_io_connect_o = (TCCRA[`COM0A1:`COM0A0] == 2'b00) ? 1'b0 : (TCCRA[`COM0A1:`COM0A0] == 2'b01 ? ((TCCRA[`WGM01:`WGM00] == 2'd1 || TCCRA[`WGM01:`WGM00] == 2'd3) ? TCCRB[`WGM02] : 1'b1) : 1'b1);
assign ocb_io_connect_o = USE_OCRB == "TRUE" ? ((TCCRA[`COM0B1:`COM0B0] == 2'b00) ? 1'b0 : (TCCRA[`COM0B1:`COM0B0] == 2'b01 ? ((TCCRA[`WGM01:`WGM00] == 2'd1 || TCCRA[`WGM01:`WGM00] == 2'd3) ? TCCRB[`WGM02] : 1'b1) : 1'b1)) : 1'b0;

endmodule
