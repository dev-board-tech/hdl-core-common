// http://chasingtrons.com/main/2012/6/14/television-fpga-verilog.html

`define BASE_PIXEL_X			10'd184
`define RESOLUTION_HORIZONTAL	10'd560
`define BASE_PIXEL_Y			10'd89
`define RESOLUTION_VERTICAL		10'd400

module interlaced_ntsc # (
	parameter PIXEL_NUANCE_DEPTH = 3
	) (
    input	rst_i,
    input	clk_i,
    input	[3:0] pixel_data_i,
    output	h_sync_out_o, // single clock tick indicating pixel_y will incrememt on next clock (for debugging)
    output	v_sync_out_o, // single clock tick indicating pixel_y will reset to 0 or 1 on next clock, depending on the field (for debugging)
    output	[9:0] pixel_y_o,    // which line
    output	[9:0] pixel_x_o,
    output	pixel_is_visible_o,
    output reg	[PIXEL_NUANCE_DEPTH:0] ntsc_out_o
    );


    reg         [9:0] line_count_reg,
                      line_count_reg_next; // 0..524

    reg         [1:0] line_type_reg,
                      line_type_reg_next;

    reg        [11:0] horizontal_count_reg,
                      horizontal_count_reg_next;

    localparam  [1:0] LINE_TYPE_EQ              = 2'b00,
                      LINE_TYPE_VERTICAL_BLANK  = 2'b01,
                      LINE_TYPE_SCANLINE        = 2'b10;

    localparam        WIDTH_FRONT_PORCH         = 75,     // 1.5 uS @ 50 MHz
                      WIDTH_SYNC_TIP            = 235,    // 4.7 uS @ 50 MHz
                      WIDTH_BACK_PORCH          = 235,    // 4.7 uS @ 50 MHz
                      WIDTH_VIDEO               = 2630,   // 52.6 uS @ 50 MHz
                      WIDTH_WHOLE_LINE          = 3175,   // 63.5 uS @ 50 MHz
                      WIDTH_HALF_LINE           = 1588,   // 31.75 uS @ 50 MHz
                      WIDTH_EQ_PULSE            = 117,    // 2.35 uS @ 50 MHz
                      WIDTH_V_SYNC_PULSE        = 1353;   // 27.05 uS @ 50 MHz

    localparam [3:0]  SIGNAL_LEVEL_SYNC         = 4'b0000,
                      SIGNAL_LEVEL_BLANK        = 4'b0001,
                      SIGNAL_LEVEL_DARK_GREY    = 4'b0011,
                      SIGNAL_LEVEL_LIGHT_GREY   = 4'b0111,
                      SIGNAL_LEVEL_WHITE        = 4'b1111;

    localparam        HALF_LINE_EVEN_FIELD      = 18,
                      HALF_LINE_ODD_FIELD       = 527;

//  ____ _   _ _  _ ____    ____ _ ____ _  _ ____ _    ____
//  [__   \_/  |\ | |       [__  | | __ |\ | |__| |    [__
//  ___]   |   | \| |___    ___] | |__] | \| |  | |___ ___]
//
    wire at_half_line_width = ( horizontal_count_reg >= WIDTH_HALF_LINE );                                        // signals that the current line has
                                                                                                                  // reached a half scanline's 31.75
    wire at_full_line_width = ( horizontal_count_reg >= WIDTH_WHOLE_LINE );                                       // signals that the current line has
                                                                                                                  // reached a normal scanline's 63.5us
    wire is_a_half_line = ( line_count_reg == HALF_LINE_EVEN_FIELD ) | ( line_count_reg == HALF_LINE_ODD_FIELD ); // signals current line should be treaded as a half
    wire is_a_whole_line = ~ is_a_half_line;                                                                      // signals current line should be treaded as a whole

    wire h_sync = ( is_a_half_line & at_half_line_width ) | ( is_a_whole_line & at_full_line_width );
    wire v_sync = h_sync & line_count_reg >= 526;

    assign h_sync_out_o = h_sync;
    assign v_sync_out_o = v_sync;


    assign pixel_is_visible_o = horizontal_count_reg[11:2] >= `BASE_PIXEL_X & horizontal_count_reg[11:2] < `BASE_PIXEL_X + `RESOLUTION_HORIZONTAL & line_count_reg >= `BASE_PIXEL_Y & line_count_reg < `BASE_PIXEL_Y + `RESOLUTION_VERTICAL;
    assign pixel_x_o          = pixel_is_visible_o ? horizontal_count_reg[11:2] - `BASE_PIXEL_X : 0;
    assign pixel_y_o          = pixel_is_visible_o ? line_count_reg - `BASE_PIXEL_Y : 0;

//  _  _ ____ _ _  _    ____ ____ ____ _ ____ ___ ____ ____
//  |\/| |__| | |\ |    |__/ |___ | __ | [__   |  |___ |__/
//  |  | |  | | | \|    |  \ |___ |__] | ___]  |  |___ |  \
//  ___ ____ ____ _  _ ____ ____ ____ ____
//   |  |__/ |__| |\ | [__  |___ |___ |__/
//   |  |  \ |  | | \| ___] |    |___ |  \
//
    always @( posedge clk_i )
        begin
            horizontal_count_reg  <= horizontal_count_reg_next; // all registers that are needed for decision
            line_count_reg        <= line_count_reg_next;       // keeping are buffered so they hold their
            line_type_reg         <= line_type_reg_next;        // current value until the next clock cycle
        end

//  _    _ _  _ ____    ____ ___ ____ ___ ____
//  |    | |\ | |___    [__   |  |__|  |  |___
//  |___ | | \| |___    ___]  |  |  |  |  |___
//
    always @*                                                                          // TODO: might be able to move this to a wire signal
        if ( line_count_reg <= 5 || ( line_count_reg >= 12 && line_count_reg <= 18 ) ) // is this an equalizing pulse line?
            line_type_reg_next = LINE_TYPE_EQ;
        else if ( line_count_reg >= 6 && line_count_reg <= 11 )                        // is this a vertical blanking line?
            line_type_reg_next = LINE_TYPE_VERTICAL_BLANK;
        else
            line_type_reg_next = LINE_TYPE_SCANLINE;                                   // must be a normal scanline

//  ____ _ ____ _  _ ____ _     ___ _ _  _ _ _  _ ____
//  [__  | | __ |\ | |__| |      |  | |\/| | |\ | | __
//  ___] | |__] | \| |  | |___   |  | |  | | | \| |__]
//
    always @*
        if ( h_sync )                                             // reached the end of the current line?
            horizontal_count_reg_next = 0;                        // yes, reset counter to 0
        else
            horizontal_count_reg_next = horizontal_count_reg + 1; // nope, advance
// this section below used to be signals, but it was hard to read
// generates the proper signals depending on line type
    always @*
      if ( line_type_reg == LINE_TYPE_EQ )
        if ( horizontal_count_reg < WIDTH_EQ_PULSE || (horizontal_count_reg > WIDTH_HALF_LINE && horizontal_count_reg < WIDTH_HALF_LINE + WIDTH_EQ_PULSE ))
          ntsc_out_o = SIGNAL_LEVEL_SYNC;
        else
          ntsc_out_o = SIGNAL_LEVEL_BLANK;
      else if ( line_type_reg == LINE_TYPE_VERTICAL_BLANK )
        if ( horizontal_count_reg < WIDTH_V_SYNC_PULSE || (horizontal_count_reg > WIDTH_HALF_LINE && horizontal_count_reg < WIDTH_HALF_LINE + WIDTH_V_SYNC_PULSE ))
          ntsc_out_o = SIGNAL_LEVEL_SYNC;
        else
          ntsc_out_o = SIGNAL_LEVEL_BLANK;
      else if ( line_type_reg == LINE_TYPE_SCANLINE )
        begin
          if ( horizontal_count_reg > WIDTH_FRONT_PORCH && horizontal_count_reg < WIDTH_FRONT_PORCH + WIDTH_SYNC_TIP )
            ntsc_out_o = SIGNAL_LEVEL_SYNC;
          else if ( horizontal_count_reg > WIDTH_WHOLE_LINE - WIDTH_VIDEO )
            ntsc_out_o = pixel_data_i; // luminance
          else
            ntsc_out_o = SIGNAL_LEVEL_BLANK;
        end

    always @*
        casex ( {v_sync, h_sync, line_count_reg} )                            // a lookup table to determine next line number
            {1'b1, 1'b1, 10'd526} : line_count_reg_next = 1;                  // v_sync & line number 526, go to line 1
            {1'b1, 1'b1, 10'd527} : line_count_reg_next = 0;                  // v_sync & line number 527, go to line 0
            {1'b0, 1'b1, 10'bx  } : line_count_reg_next = line_count_reg + 2; // hsync, but not vsync, jump a line
            default               : line_count_reg_next = line_count_reg;     // do nothing
        endcase

endmodule
