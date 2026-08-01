module alu_w_dh #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 5
)(
    input clk,
    input rst,

    // Instruction inputs
    input [3:0] opcode_in,
    input [ADDR_WIDTH-1:0] rs1_in,
    input [ADDR_WIDTH-1:0] rs2_in,
    input [ADDR_WIDTH-1:0] rd_in,
    input [DATA_WIDTH-1:0] imm_in,
    input use_imm,

    // Output
    output reg [DATA_WIDTH-1:0] wb_data_out
);

    // ========================================================
    // OPCODES
    // ========================================================

    localparam ADD  = 4'b0000;
    localparam SUB  = 4'b0001;
    localparam ANDD = 4'b0010;
    localparam ORR  = 4'b0011;
    localparam XORR = 4'b0100;
    localparam SLT  = 4'b0101;
    localparam MUL  = 4'b0110;

    // ========================================================
    // REGISTER FILE
    // ========================================================

    reg [DATA_WIDTH-1:0] regfile [0:31];

    integer i;

    always @(posedge clk or posedge rst)
    begin
        if(rst)
        begin
            for(i=0;i<32;i=i+1)
                regfile[i] <= 0;
        end
    end

    // ========================================================
    // IF/ID PIPELINE REGISTER
    // ========================================================

    reg [3:0] IF_ID_opcode;
    reg [ADDR_WIDTH-1:0] IF_ID_rs1;
    reg [ADDR_WIDTH-1:0] IF_ID_rs2;
    reg [ADDR_WIDTH-1:0] IF_ID_rd;
    reg [DATA_WIDTH-1:0] IF_ID_imm;
    reg IF_ID_use_imm;

    always @(posedge clk)
    begin
        IF_ID_opcode  <= opcode_in;
        IF_ID_rs1     <= rs1_in;
        IF_ID_rs2     <= rs2_in;
        IF_ID_rd      <= rd_in;
        IF_ID_imm     <= imm_in;
        IF_ID_use_imm <= use_imm;
    end

    // ========================================================
    // ID STAGE
    // ========================================================

    wire [DATA_WIDTH-1:0] rs1_data;
    wire [DATA_WIDTH-1:0] rs2_data;

    assign rs1_data = regfile[IF_ID_rs1];
    assign rs2_data = regfile[IF_ID_rs2];

    // ========================================================
    // ID/EX PIPELINE REGISTER
    // ========================================================

    reg [3:0] ID_EX_opcode;
    reg [ADDR_WIDTH-1:0] ID_EX_rs1;
    reg [ADDR_WIDTH-1:0] ID_EX_rs2;
    reg [ADDR_WIDTH-1:0] ID_EX_rd;

    reg [DATA_WIDTH-1:0] ID_EX_op1;
    reg [DATA_WIDTH-1:0] ID_EX_op2;

    always @(posedge clk)
    begin
        ID_EX_opcode <= IF_ID_opcode;
        ID_EX_rs1    <= IF_ID_rs1;
        ID_EX_rs2    <= IF_ID_rs2;
        ID_EX_rd     <= IF_ID_rd;

        ID_EX_op1    <= rs1_data;

        if(IF_ID_use_imm)
            ID_EX_op2 <= IF_ID_imm;
        else
            ID_EX_op2 <= rs2_data;
    end

    // ========================================================
    // FORWARDING UNIT
    // ========================================================

    reg [1:0] forwardA;
    reg [1:0] forwardB;

    always @(*)
    begin

        forwardA = 2'b00;
        forwardB = 2'b00;

        // EX hazard

        if((EX_MEM_rd != 0) &&
           (EX_MEM_rd == ID_EX_rs1))
            forwardA = 2'b10;

        if((EX_MEM_rd != 0) &&
           (EX_MEM_rd == ID_EX_rs2))
            forwardB = 2'b10;

        // MEM hazard

        if((MEM_WB_rd != 0) &&
           (MEM_WB_rd == ID_EX_rs1))
            forwardA = 2'b01;

        if((MEM_WB_rd != 0) &&
           (MEM_WB_rd == ID_EX_rs2))
            forwardB = 2'b01;
    end

    // ========================================================
    // FORWARDED OPERANDS
    // ========================================================

    reg [DATA_WIDTH-1:0] alu_in1;
    reg [DATA_WIDTH-1:0] alu_in2;

    always @(*)
    begin

        // Operand A
        case(forwardA)

            2'b00: alu_in1 = ID_EX_op1;
            2'b01: alu_in1 = MEM_WB_result;
            2'b10: alu_in1 = EX_MEM_result;

            default: alu_in1 = ID_EX_op1;

        endcase

        // Operand B
        case(forwardB)

            2'b00: alu_in2 = ID_EX_op2;
            2'b01: alu_in2 = MEM_WB_result;
            2'b10: alu_in2 = EX_MEM_result;

            default: alu_in2 = ID_EX_op2;

        endcase
    end

    // ========================================================
    // EX STAGE
    // ========================================================

    reg [DATA_WIDTH-1:0] alu_result;

    always @(*)
    begin

        case(ID_EX_opcode)

            ADD:
                alu_result = alu_in1 + alu_in2;

            SUB:
                alu_result = alu_in1 - alu_in2;

            ANDD:
                alu_result = alu_in1 & alu_in2;

            ORR:
                alu_result = alu_in1 | alu_in2;

            XORR:
                alu_result = alu_in1 ^ alu_in2;

            SLT:
                alu_result = (alu_in1 < alu_in2) ? 1 : 0;

            MUL:
                alu_result = alu_in1 * alu_in2;

            default:
                alu_result = 0;

        endcase
    end

    // ========================================================
    // EX/MEM PIPELINE REGISTER
    // ========================================================

    reg [DATA_WIDTH-1:0] EX_MEM_result;
    reg [ADDR_WIDTH-1:0] EX_MEM_rd;

    always @(posedge clk)
    begin
        EX_MEM_result <= alu_result;
        EX_MEM_rd     <= ID_EX_rd;
    end

    // ========================================================
    // MEM STAGE
    // ========================================================

    // No memory operation here
    // Only forwarding pipeline stage

    // ========================================================
    // MEM/WB PIPELINE REGISTER
    // ========================================================

    reg [DATA_WIDTH-1:0] MEM_WB_result;
    reg [ADDR_WIDTH-1:0] MEM_WB_rd;

    always @(posedge clk)
    begin
        MEM_WB_result <= EX_MEM_result;
        MEM_WB_rd     <= EX_MEM_rd;
    end

    // ========================================================
    // WB STAGE
    // ========================================================

    always @(posedge clk)
    begin

        if(MEM_WB_rd != 0)
            regfile[MEM_WB_rd] <= MEM_WB_result;

        wb_data_out <= MEM_WB_result;

    end

endmodule