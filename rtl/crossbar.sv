module crossbar #(
    parameter DATA_WIDTH = 32,
    parameter NUM_PORTS  = 5
)(
    input  logic [DATA_WIDTH-1:0] data_in      [NUM_PORTS],
    input  logic [NUM_PORTS-1:0]  grant_matrix [NUM_PORTS],
    output logic [DATA_WIDTH-1:0] data_out     [NUM_PORTS]
);

    genvar i;
    generate
        for (i = 0; i < NUM_PORTS; i++) begin : gen_muxes
            always_comb begin
                case (grant_matrix[i])
                    5'b00001: data_out[i] = data_in[0];
                    5'b00010: data_out[i] = data_in[1];
                    5'b00100: data_out[i] = data_in[2];
                    5'b01000: data_out[i] = data_in[3];
                    5'b10000: data_out[i] = data_in[4];
                    default: data_out[i] = '0;
                endcase
            end
        end
    endgenerate
endmodule
