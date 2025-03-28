// calculation for CRC
// din(0), cin(0) and f_crc(0) is transmitted first in serial stream when "REVERSE" order
// CRC-32   : G(x) = 1 + x + x2 + x4 + x5 + x7 + x8 + x10 + x11 + x12 + x16 + x22 + x23 + x26 + x32
//        good FCS = 0xDEBB20E3 (REVERSE) or 
//                   0xC704DD7B (NORMAL)
// CRC-CCITT: G(x) = 1 + x5 + x12 + x16
//        good FCS = 0xF0B8 (REVERSE)
//                 = 0x1D0F (NORMAL)
// CRC-24   : G(x) = 1 + x + x5 + x6 + x8 + x9 + x11 + x15 + x17 + x20 + x21 + x24
// CRC-16   : G(x) = 1 + x2 + x15 + x16
// CRC-12   : G(x) = 1 + x + x2 + x3 + x11 + x12
// CRC-8    : G(x) = 1 + x + x2 + x8
// CRC-7    : G(x) = 1 + x3 + x7
// CRC-4    : G(x) = 1 + x + x4
// ORDER = "REVERSE" used for HDLC or MAC
// ORDER = "NORMAL" used for GFP or SDH
function [31:0] f_crc;
input [31:0]   din;       // the width of data is [DW-1:0], 0<DW<32
input [31:0]   cin;       // last crc result, width is [CW-1:0], depend on crc type
input [55:0]   bit_order; // "REVERSE" or "NORMAL"
input [71:0]   crc_type;  // "CRC_32", "CRC_META", "CRC_CCITT", "CRC_24", "CRC_16", "CRC_12", "CRC_8", "CRC_7", "CRC_4"
input [5:0]    DW;        // 0<DW<=32

reg   [31:0]   ge;
reg   [31:0]   ct;
reg            fb;
reg   [31:0]   co;
integer        i;
integer        j;
integer        CW;

begin
    if (crc_type=="CRC_32")
    begin
        ge[31:0] = 32'b0000_0100_1100_0001_0001_1101_1011_0111;
        CW       = 32;
    end
    else if (crc_type=="CRC_META")
    begin
        ge[31:0] = 32'b0001_1110_1101_1100_0110_1111_0100_0001;
        CW       = 32;
    end
    else if (crc_type=="CRC_CCITT")
    begin
        ge[15:0] = 16'b0001_0000_0010_0001;
        CW       = 16;
    end
    else if (crc_type=="CRC_24")
    begin
        ge[23:0] = 24'b0011_0010_1000_1011_0110_0011;
        CW       = 24;
    end
    else if (crc_type=="CRC_16")
    begin
        ge[15:0] = 16'b1000_0000_0000_0101;
        CW       = 16;
    end
    else if (crc_type=="CRC_12")
    begin
        ge[11:0] = 12'b1000_0000_1111;
        CW       = 12;
    end
    else if (crc_type=="CRC_8")
    begin
        ge[7:0]  = 8'b0000_0111;
        CW       = 8;
    end
    else if (crc_type=="CRC_7")
    begin
        ge[6:0]  = 7'b000_1001;
        CW       = 7;
    end
    else if (crc_type=="CRC_4")
    begin
        ge[3:0]  = 4'b0011;
        CW       = 4;
    end
    else
    begin
        $display("function f_crc has a error parameter for 'crc_type'");
        ge[31:0] = 32'b0000_0100_1100_0001_0001_1101_1011_0111;
        CW       = 32;
    end

    if (bit_order=="NORMAL")
        ct = cin;
    else if (bit_order=="REVERSE")
    begin
        for (i=0; i<CW; i=i+1)
            ct[i] = cin[CW-1-i];
    end
    else
        $display("function f_crc has a error parameter for 'bit_order'");

    for (i=DW-1; i>=0; i=i-1)
    begin
        if (bit_order=="NORMAL")
            fb = ct[CW-1] ^ din[i];
        else
            fb = ct[CW-1] ^ din[DW-1-i];
        for (j=CW-1; j>0; j=j-1)
            ct[j] = ct[j-1] ^ (fb&ge[j]);
        ct[0] = fb;
    end

    if (bit_order=="NORMAL")
        co = ct;
    else begin
        for (i=0; i<CW; i=i+1)
            co[i] = ct[CW-1-i];
    end
    f_crc = co;
end
endfunction

// calculation for PRBS
// prbs7 : G(x) = 1 + x6 + x7
// prbs19: G(x) = 1 + x + x2 + x6 + x19
function [31:0] f_prbs;
input [55:0]    prbs_type;      // "PRBS_31", "PRBS_23", "PRBS_19", "PRBS_15", "PRBS_11", "PRBS_7"
input [31:0]    di;             // previous data, next data is delivered from it
input integer   shift_num;      // shift times, 8 for a byte, 1 for a bit, and so on
input           init_value;     // 0: initial value is all zero, 1: initial value is all one
input           shift_order;    // 0: shift from 0 to 31, 1: shift from 31 to 0

integer         i;
reg   [31:0]    dtp;
reg             fb;

begin
    dtp = di;
    for (i=0; i<shift_num; i=i+1)
    begin
        if (prbs_type=="PRBS_31")
            fb = dtp[30] ^ dtp[28];
        else if (prbs_type=="PRBS_23")      // inv
            fb = dtp[22] ^ dtp[17];
        else if (prbs_type=="PRBS_19")      // non-inv
            fb = dtp[18] ^ dtp[5] ^ dtp[1] ^ dtp[0];
        else if (prbs_type=="PRBS_15")      // inv
            fb = dtp[14] ^dtp[13];
        else if (prbs_type=="PRBS_11")      // non-inv
            fb = dtp[10] ^ dtp[8];
        else if (prbs_type=="PRBS_7")
            fb = dtp[6] ^ dtp[5];
        else begin
            $display("function f_prbs has a error parameter for 'prbs_type'");
            fb = 1'b0;
        end
        dtp    = dtp << 1;
        dtp[0] = fb ^ (~init_value);
    end
    f_prbs = dtp;
end
endfunction

// encode or decode for GRAY CODE
function [31:0] f_gray_code;
input [31:0]    di;         // input data for translation
input [47:0]    op_type;    // "ENCODE" or "DECODE"
input integer   DW;         // data width
integer         i;
reg   [31:0]    dtp;

begin
    dtp[DW-1] = di[DW-1];
    for (i=DW-2; i>=0; i=i-1)
    begin
        if (op_type=="ENCODE")
            dtp[i] = di[i] ^ di[i+1];
        else if (op_type=="DECODE")
            dtp[i] = di[i] ^ dtp[i+1];
        else
            $display("function f_gray_code has a error parameter for 'op_type'");
    end
    f_gray_code = dtp;
end
endfunction
