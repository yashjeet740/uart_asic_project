module uart_mmio_wrapper (
    input clk,
    input rst,
    // Bus Interface
    input [3:0]  addr,      // 4-bit address offset
    input [31:0] wdata,     // Data from CPU
    input        we,        // Write Enable
    output reg [31:0] rdata, // Data to CPU
    
    // External Pins
    output uart_tx,
    input  uart_rx
);

    // Internal wires to connect to your uart_top
    reg  tx_start;
    wire tx_busy;
    wire [7:0] rx_data;
    wire rx_done;

    // Instantiate your existing UART Transceiver
    uart_top #(.CLKS_PER_BIT(87)) core_uart (
        .clk(clk), .rst(rst),
        .tx_start(tx_start),
        .tx_data_in(wdata[7:0]),
        .tx_busy(tx_busy),
        .uart_tx_out(uart_tx),
        .uart_rx_in(uart_rx),
        .rx_data_out(rx_data),
        .rx_done(rx_done)
    );

    // Address Decoding Logic
    always @(posedge clk) begin
        tx_start <= 0; // Default: don't pulse start
        if (rst) begin
            rdata <= 0;
        end else if (we) begin
            case (addr)
                4'h0: tx_start <= 1; // Writing to Offset 0 triggers TX
                // Other registers could go here
            endcase
        end else begin
            case (addr)
                4'h0: rdata <= {31'b0, tx_busy}; // Reading Offset 0 checks status
                4'h4: rdata <= {24'b0, rx_data}; // Reading Offset 4 gets received data
            endcase
        end
    end
endmodule
