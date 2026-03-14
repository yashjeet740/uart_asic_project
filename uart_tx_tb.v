module uart_loopback_tb;

    // Standard testbench signals
    reg clk;
    reg rst;
    
    // TX Signals
    reg tx_start;
    reg [7:0] tx_data_in;
    wire tx_busy;
    
    // The physical wire connecting TX to RX!
    wire serial_line;
    
    // RX Signals
    wire [7:0] rx_data_out;
    wire rx_done;

    // Instantiate the Transmitter (using a small CLKS_PER_BIT for faster simulation)
    uart_tx #(.CLKS_PER_BIT(10)) my_tx (
        .clk(clk),
        .rst(rst),
        .start(tx_start),
        .data_in(tx_data_in),
        .tx(serial_line), // Connects output to the wire
        .tx_busy(tx_busy)
    );

    // Instantiate the Receiver
    uart_rx #(.CLKS_PER_BIT(10)) my_rx (
        .clk(clk),
        .rst(rst),
        .rx(serial_line), // Connects input to the wire
        .data_out(rx_data_out),
        .rx_done(rx_done)
    );

    // Generate a clock (10ns period -> 100MHz)
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // The actual test sequence
    initial begin
        // Generate waveform file
        $dumpfile("loopback.vcd");
        $dumpvars(0, uart_loopback_tb);

        // 1. Initialize and Reset
        rst = 1;
        tx_start = 0;
        tx_data_in = 8'h00;
        #20 rst = 0;
        #20;

        // 2. Give the Transmitter some data (0xA5 = 10100101)
        $display("Sending data: 8'hA5");
        tx_data_in = 8'hA5;
        tx_start = 1;
        #10 tx_start = 0; // Pulse start for 1 clock cycle

        // 3. Wait for the Receiver to say it's done
        wait(rx_done == 1);
        
        // 4. Verify the result
        if (rx_data_out == 8'hA5) begin
            $display("SUCCESS! Receiver caught: 8'h%h", rx_data_out);
        end else begin
            $display("FAILED! Receiver caught: 8'h%h instead of 8'hA5", rx_data_out);
        end

        // Wait a bit to let waveforms finish, then end simulation
        #100 $finish;
    end

endmodule
