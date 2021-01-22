//-----------------------------------------------------------------
//                       USB Serial Port
//                            V0.1
//                     Ultra-Embedded.com
//                       Copyright 2020
//
//                 Email: admin@ultra-embedded.com
//
//                         License: LGPL
//-----------------------------------------------------------------
//
// This source file may be used and distributed without         
// restriction provided that this copyright statement is not    
// removed from the file and that any derivative work contains  
// the original copyright notice and the associated disclaimer. 
//
// This source file is free software; you can redistribute it   
// and/or modify it under the terms of the GNU Lesser General   
// Public License as published by the Free Software Foundation; 
// either version 2.1 of the License, or (at your option) any   
// later version.
//
// This source is distributed in the hope that it will be       
// useful, but WITHOUT ANY WARRANTY; without even the implied   
// warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR      
// PURPOSE.  See the GNU Lesser General Public License for more 
// details.
//
// You should have received a copy of the GNU Lesser General    
// Public License along with this source; if not, write to the 
// Free Software Foundation, Inc., 59 Temple Place, Suite 330, 
// Boston, MA  02111-1307  USA
//-----------------------------------------------------------------
//`define USE_UART_INTERFACE
//`define USE_PLATFORM_DEPENDENT_FIFO

//-----------------------------------------------------------------
//                          Generated File
//-----------------------------------------------------------------

module usb_cdc_top
//-----------------------------------------------------------------
// Params
//-----------------------------------------------------------------
#(
	parameter PLATFORM = "XILINX",
	parameter USE_ECHO = "FALSE"
)
//-----------------------------------------------------------------
// Ports
//-----------------------------------------------------------------
(
    // Inputs
     input           clk_i
	,input			 clk48m_i
    ,input           rst_i
    ,input           tx_i

    ,output          rx_o
    ,inout			usb_p
    ,inout			usb_n
	
	
	,input       rx_valid_i
	,input [7:0] rx_data_i
	,output      rx_accept_o

	,output       tx_valid_o
	,output [7:0] tx_data_o
	,input       tx_accept_i

);






wire  [  7:0]  utmi_data_out_w;
wire  [  7:0]  usb_rx_data_w;
wire           usb_tx_accept_w;
wire           enable_w = 1'h1;
wire  [  1:0]  utmi_xcvrselect_w;
wire           utmi_termselect_w;
wire           utmi_rxvalid_w;
wire  [  1:0]  utmi_op_mode_w;
wire  [  7:0]  utmi_data_in_w;
wire           utmi_rxerror_w;
wire           utmi_rxactive_w;
wire  [  1:0]  utmi_linestate_w;
wire           usb_tx_valid_w;
wire           usb_rx_accept_w;
wire           utmi_dppulldown_w;
wire  [  7:0]  usb_tx_data_w;
wire           usb_rx_valid_w;
wire           utmi_txready_w;
wire           utmi_txvalid_w;
wire           utmi_dmpulldown_w;


usb_cdc_core
u_usb
(
    // Inputs
     .clk_i(clk48m_i)
    ,.rst_i(rst_i)
    ,.enable_i(enable_w)
    ,.utmi_data_in_i(utmi_data_in_w)
    ,.utmi_txready_i(utmi_txready_w)
    ,.utmi_rxvalid_i(utmi_rxvalid_w)
    ,.utmi_rxactive_i(utmi_rxactive_w)
    ,.utmi_rxerror_i(utmi_rxerror_w)
    ,.utmi_linestate_i(utmi_linestate_w)
    ,.inport_valid_i(usb_tx_valid_w)
    ,.inport_data_i(usb_tx_data_w)
    ,.outport_accept_i(usb_rx_accept_w)

    // Outputs
    ,.utmi_data_out_o(utmi_data_out_w)
    ,.utmi_txvalid_o(utmi_txvalid_w)
    ,.utmi_op_mode_o(utmi_op_mode_w)
    ,.utmi_xcvrselect_o(utmi_xcvrselect_w)
    ,.utmi_termselect_o(utmi_termselect_w)
    ,.utmi_dppulldown_o(utmi_dppulldown_w)
    ,.utmi_dmpulldown_o(utmi_dmpulldown_w)
    ,.inport_accept_o(usb_tx_accept_w)
    ,.outport_valid_o(usb_rx_valid_w)
    ,.outport_data_o(usb_rx_data_w)
);

wire usb_rx_rcv_i;
wire usb_rx_dp_i;
wire usb_rx_dn_i;

wire usb_tx_dp_o;
wire usb_tx_dn_o;
wire usb_tx_oen_o;

usb_fs_phy usb_fs_phy_inst(
    // Inputs
	.clk_i(clk48m_i),
	.rst_i(rst_i),
	.utmi_data_out_i(utmi_data_out_w),
	.utmi_txvalid_i(utmi_txvalid_w),
	.utmi_op_mode_i(utmi_op_mode_w),
	.utmi_xcvrselect_i(utmi_xcvrselect_w),
	.utmi_termselect_i(utmi_termselect_w),
	.utmi_dppulldown_i(utmi_dppulldown_w),
	.utmi_dmpulldown_i(utmi_dmpulldown_w),
	.usb_rx_rcv_i(usb_rx_rcv_i),
	.usb_rx_dp_i(usb_rx_dp_i),
	.usb_rx_dn_i(usb_rx_dn_i),
	.usb_reset_assert_i(1'b0),
	
	// Outputs
	.utmi_data_in_o(utmi_data_in_w),
	.utmi_txready_o(utmi_txready_w),
	.utmi_rxvalid_o(utmi_rxvalid_w),
	.utmi_rxactive_o(utmi_rxactive_w),
	.utmi_rxerror_o(utmi_rxerror_w),
	.utmi_linestate_o(utmi_linestate_w),
	.usb_tx_dp_o(usb_tx_dp_o),
	.usb_tx_dn_o(usb_tx_dn_o),
	.usb_tx_oen_o(usb_tx_oen_o),
	.usb_reset_detect_o(),
	.usb_en_o()
);

usb_transceiver usb_transceiver_inst(
    // Inputs
	.usb_phy_tx_dp_i(usb_tx_dp_o),
	.usb_phy_tx_dn_i(usb_tx_dn_o),
	.usb_phy_tx_oen_i(usb_tx_oen_o),
	.mode_i(1'b1),
	
		// Outputs
	.usb_dp_io(usb_p),
	.usb_dn_io(usb_n),
	.usb_phy_rx_rcv_o(usb_rx_rcv_i),
	.usb_phy_rx_dp_o(usb_rx_dp_i),
	.usb_phy_rx_dn_o(usb_rx_dn_i)
);
generate
if (USE_ECHO == "TRUE")
begin
//-----------------------------------------------------------------
// Echo FIFO
//-----------------------------------------------------------------
`ifdef USE_PLATFORM_DEPENDENT_FIFO
usb_cdc_fifo
#(
    .PLATFORM(PLATFORM),
    .WIDTH(8),
    .DEPTH(64),
    .ADDR_W(6)
)
u_fifo_echo
(
    .clk_push_i(clk48m_i),
    .clk_pop_i(clk48m_i),
    .rst_i(rst_i),

    // In
    .push_i(usb_rx_valid_w),
    .data_in_i(usb_rx_data_w),
    .accept_o(usb_rx_accept_w),

    // Out
    .pop_i(usb_tx_accept_w),
    .data_out_o(usb_tx_data_w),
    .valid_o(usb_tx_valid_w)
);
`else
usb_cdc_fifo
#(
    .PLATFORM(PLATFORM),
    .WIDTH(8),
    .DEPTH(64),
    .ADDR_W(6)
)
u_fifo_echo
(
    .clk_i(clk48m_i),
    .rst_i(rst_i),

    // In
    .push_i(usb_rx_valid_w),
    .data_in_i(usb_rx_data_w),
    .accept_o(usb_rx_accept_w),

    // Out
    .pop_i(usb_tx_accept_w),
    .data_out_o(usb_tx_data_w),
    .valid_o(usb_tx_valid_w)
);
`endif
end
else /*USE_ECHO != "TRUE"*/
begin
//-----------------------------------------------------------------
// Input FIFO
//-----------------------------------------------------------------
usb_cdc_fifo
#(
    .PLATFORM(PLATFORM),
	.WIDTH(8),
    .DEPTH(64),
    .ADDR_W(6)
)
u_fifo_tx
(
    .clk_i(clk48m_i),
    .rst_i(rst_i),

    // In
    .push_i(rx_valid_i),
    .data_in_i(rx_data_i),
    .accept_o(rx_accept_o),

    // Out
    .pop_i(usb_tx_accept_w),
    .data_out_o(usb_tx_data_w),
    .valid_o(usb_tx_valid_w)
);
//-----------------------------------------------------------------
// Output FIFO
//-----------------------------------------------------------------
usb_cdc_fifo
#(
    .PLATFORM(PLATFORM),
    .WIDTH(8),
    .DEPTH(64),
    .ADDR_W(6)
)
u_fifo_rx
(
    .clk_i(clk48m_i),
    .rst_i(rst_i),

    // In
    .push_i(usb_rx_valid_w),
    .data_in_i(usb_rx_data_w),
    .accept_o(usb_rx_accept_w),

    // Out
    .pop_i(tx_accept_i),
    .data_out_o(tx_data_o),
    .valid_o(tx_valid_o)
);
end /*USE_ECHO == "TRUE"*/
endgenerate
endmodule


`ifdef USE_PLATFORM_DEPENDENT_FIFO
module usb_cdc_fifo
//-----------------------------------------------------------------
// Params
//-----------------------------------------------------------------
#(
	parameter PLATFORM = "XILINX",
    parameter WIDTH   = 8,
    parameter DEPTH   = 4,
    parameter ADDR_W  = 2
)
//-----------------------------------------------------------------
// Ports
//-----------------------------------------------------------------
(
    // Inputs
     input               clk_push_i
    ,input               clk_pop_i
    ,input               rst_i
    ,input  [WIDTH-1:0]  data_in_i
    ,input               push_i
    ,input               pop_i

    // Outputs
    ,output [WIDTH-1:0]  data_out_o
    ,output              accept_o
    ,output              valid_o
);
wire empty;
wire full;

pmi_fifo_dc 
#(
	.pmi_data_width_w      (WIDTH), // integer       
	.pmi_data_width_r      (WIDTH), // integer       
	.pmi_data_depth_w      (DEPTH), // integer       
	.pmi_data_depth_r      (DEPTH), // integer       
	.pmi_full_flag         ( ), // integer       
	.pmi_empty_flag        ( ), // integer		
	.pmi_almost_full_flag  ( ), // integer		
	.pmi_almost_empty_flag ( ), // integer		
	.pmi_regmode           ("noreg"), // "reg"|"noreg"     
	.pmi_resetmode         ("async"), // "async" | "sync"    
	.pmi_family            ("iCE40UP"), // "iCE40UP" | "LIFCL"		
	.pmi_implementation    ("EBR"), // "LUT"|"EBR"
    .module_type           ( )  // string	
) pmi_fifo_dc_inst (
	.Data        (data_in_i), // I:
	.WrClock     (clk_push_i), // I:
	.RdClock     (clk_pop_i), // I:
	.WrEn        (push_i), // I:
	.RdEn        (pop_i), // I:
	.Reset       (rst_i), // I:
	.RPReset     (rst_i), // I:
	.Q           (data_out_o), // O:
	.Empty       (empty), // O:
	.Full        (full), // O:
	.AlmostEmpty ( ), // O:
	.AlmostFull  ( )  // O:
);
//-------------------------------------------------------------------
// Combinatorial
//-------------------------------------------------------------------
/* verilator lint_off WIDTH */
assign valid_o       = ~empty;
assign accept_o      = ~full;
/* verilator lint_on WIDTH */

endmodule
`else /* !USE_PLATFORM_DEPENDENT_FIFO */
module usb_cdc_fifo
//-----------------------------------------------------------------
// Params
//-----------------------------------------------------------------
#(
	parameter PLATFORM = "XILINX",
    parameter WIDTH   = 8,
    parameter DEPTH   = 4,
    parameter ADDR_W  = 2
)
//-----------------------------------------------------------------
// Ports
//-----------------------------------------------------------------
(
    // Inputs
     input               clk_i
    ,input               rst_i
    ,input  [WIDTH-1:0]  data_in_i
    ,input               push_i
    ,input               pop_i

    // Outputs
    ,output [WIDTH-1:0]  data_out_o
    ,output              accept_o
    ,output              valid_o
);

//-----------------------------------------------------------------
// Local Params
//-----------------------------------------------------------------
localparam COUNT_W = ADDR_W + 1;

//-----------------------------------------------------------------
// Registers
//-----------------------------------------------------------------
reg [WIDTH-1:0]   ram_q[DEPTH-1:0];
reg [ADDR_W-1:0]  rd_ptr_q;
reg [ADDR_W-1:0]  wr_ptr_q;
reg [COUNT_W-1:0] count_q;

//-----------------------------------------------------------------
// Sequential
//-----------------------------------------------------------------
always @ (posedge clk_i)
if (rst_i)
begin
    count_q   <= {(COUNT_W) {1'b0}};
    rd_ptr_q  <= {(ADDR_W) {1'b0}};
    wr_ptr_q  <= {(ADDR_W) {1'b0}};
end
else
begin
    // Push
    if (push_i & accept_o)
    begin
        ram_q[wr_ptr_q] <= data_in_i;
        wr_ptr_q        <= wr_ptr_q + 1;
    end

    // Pop
    if (pop_i & valid_o)
        rd_ptr_q      <= rd_ptr_q + 1;

    // Count up
    if ((push_i & accept_o) & ~(pop_i & valid_o))
        count_q <= count_q + 1;
    // Count down
    else if (~(push_i & accept_o) & (pop_i & valid_o))
        count_q <= count_q - 1;
end

//-------------------------------------------------------------------
// Combinatorial
//-------------------------------------------------------------------
/* verilator lint_off WIDTH */
assign valid_o       = (count_q != 0);
assign accept_o      = (count_q != DEPTH);
/* verilator lint_on WIDTH */

assign data_out_o    = ram_q[rd_ptr_q];
endmodule
`endif /* !USE_PLATFORM_DEPENDENT_FIFO */
