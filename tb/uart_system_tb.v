module uart_system_tb;
    reg clk, rst, we;
    reg [3:0] addr;
    reg [31:0] wdata;
    wire [31:0] rdata;
    wire uart_wire;

    // Instantiate the Wrapper
    uart_mmio_wrapper dut (
        .clk(clk), .rst(rst),
        .addr(addr), .wdata(wdata), .we(we), .rdata(rdata),
        .uart_tx(uart_wire),
        .uart_rx(uart_wire)
    );

    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    initial begin
        $dumpfile("system.vcd");
        $dumpvars(0, uart_system_tb);
        
        // 1. Reset System
        rst = 1; we = 0; addr = 0; wdata = 0;
        #20 rst = 0;
        #10;

        // 2. FAKE CPU: Write 'A' (0x41) to the UART Data Register
        $display("CPU: Writing 'A' to UART...");
        @(posedge clk);
        addr = 4'h0; wdata = 32'h41; we = 1;
        @(posedge clk);
        we = 0;

        // 3. FAKE CPU: Poll Status Register until TX is done
        // Standard Verilog while loop
        addr = 4'h0; // Set address to status reg
        @(posedge clk);
        while (rdata[0] == 1) begin
            @(posedge clk);
        end
        $display("CPU: TX finished detected.");

        // 4. FAKE CPU: Wait for RX_DONE and read the data
        wait(dut.core_uart.rx_done == 1);
        @(posedge clk);
        addr = 4'h4; // Read received data register
        #5; // Small delay to let data stabilize
        $display("CPU: Read Received Data: 8'h%h", rdata[7:0]);

        #100 $finish;
    end
endmodule
