////////////////////////////////////////////////////////////////////////////////
//
// Filename:	wbgpio.v
//
// Project:	XuLA2-LX25 SoC based upon the ZipCPU
//
// Purpose:	This extremely simple GPIO controller, although minimally 
//		featured, is designed to control up to sixteen general purpose
//	input and sixteen general purpose output lines of a module from a
//	single address on a 32-bit wishbone bus.
//
//	Input GPIO values are contained in the top 16-bits.  Any change in
//	input values will generate an interrupt.
//
//	Output GPIO values are contained in the bottom 16-bits.  To change an
//	output GPIO value, writes to this port must also set a bit in the
//	upper sixteen bits.  Hence, to set GPIO output zero, one would write
//	a 0x010001 to the port, whereas a 0x010000 would clear the bit.  This
//	interface makes it possible to change only the bit of interest, without
//	needing to capture and maintain the prior bit values--something that
//	might be difficult from a interrupt context within a CPU.
//	
//	Unlike other controllers, this controller offers no capability to
//	change input/output direction, or to implement pull-up or pull-down
//	resistors.  It simply changes and adjusts the values going out the
//	output pins, while allowing a user to read the values on the input
//	pins.
//
//	Any change of an input pin value will result in the generation of an
//	interrupt signal.
//
// Creator:	Dan Gisselquist, Ph.D.
//		Gisselquist Technology, LLC
//
////////////////////////////////////////////////////////////////////////////////
//
// Copyright (C) 2015-2017, Gisselquist Technology, LLC
//
// This program is free software (firmware): you can redistribute it and/or
// modify it under the terms of  the GNU General Public License as published
// by the Free Software Foundation, either version 3 of the License, or (at
// your option) any later version.
//
// This program is distributed in the hope that it will be useful, but WITHOUT
// ANY WARRANTY; without even the implied warranty of MERCHANTIBILITY or
// FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
// for more details.
//
// You should have received a copy of the GNU General Public License along
// with this program.  (It's in the $(ROOT)/doc directory.  Run make with no
// target there if the PDF file isn't present.)  If not, see
// <http://www.gnu.org/licenses/> for a copy.
//
// License:	GPL, v3, as defined and found on www.gnu.org,
//		http://www.gnu.org/licenses/gpl.html
//
//
////////////////////////////////////////////////////////////////////////////////
//
//
`default_nettype	none
//
module wbgpio(i_clk, i_wb_cyc, i_wb_stb, i_wb_we, i_wb_data, o_wb_data,
		i_gpio, o_gpio, o_int);
	parameter		NIN=16, NOUT=16;
	parameter [(16-1):0]	DEFAULT=16'h00;
	input	wire		i_clk;
	//
	input	wire		i_wb_cyc, i_wb_stb, i_wb_we;
	input	wire	[31:0]	i_wb_data;
	output	wire	[31:0]	o_wb_data;
	//
	input	wire	[(NIN-1):0]	i_gpio;
	output	reg	[(NOUT-1):0]	o_gpio;
	//
	output	reg		o_int;

	// 9LUT's, 16 FF's
	initial	o_gpio = DEFAULT[(NOUT-1):0];
	always @(posedge i_clk)
		if ((i_wb_stb)&&(i_wb_we))
			o_gpio <= ((o_gpio)&(~i_wb_data[(NOUT+16-1):16]))
				|((i_wb_data[(NOUT-1):0])&(i_wb_data[(NOUT+16-1):16]));

	reg	[(NIN-1):0]	x_gpio, q_gpio, r_gpio;
	// 3 LUTs, 33 FF's
	always @(posedge i_clk)
	begin
		x_gpio <= i_gpio;
		q_gpio <= x_gpio;
		r_gpio <= q_gpio;
		o_int  <= (x_gpio != r_gpio);
	end

	wire	[15:0]	hi_bits, low_bits;
	assign	hi_bits[ (NIN -1):0] = r_gpio;
	assign	low_bits[(NOUT-1):0] = o_gpio;
	generate
	if (NIN < 16)
		assign hi_bits[ 15: NIN] = 0;
	if (NOUT < 16)
		assign low_bits[15:NOUT] = 0;
	endgenerate

	assign	o_wb_data = { hi_bits, low_bits };

	// Make Verilator happy
	// verilator lint_off UNUSED
	wire	[2:0]	unused;
	assign	unused = { i_wb_cyc, i_wb_data[31], i_wb_data[15] };
	// verilator lint_on  UNUSED
endmodule
