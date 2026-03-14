## UART ASIC Project

### 1. What this project is

This is a **simple UART (serial port) design** that is meant to be turned into a real chip using the **Sky130** open‑source fabrication process.  
You can use it to learn:

- How bits move over a serial line (TX and RX).
- How a CPU talks to hardware using memory‑mapped registers.
- How RTL can go through an ASIC flow to become layout.

---

### 2. How the UART works (high level)

- **Transmitter (`uart_tx.v`)**
  - Takes an 8‑bit value.
  - Sends it out one bit at a time on the `tx` wire.
  - Uses a counter (`CLKS_PER_BIT`) to control how long each bit stays on the line.

- **Receiver (`uart_rx.v`)**
  - Watches the `rx` wire.
  - Detects a start bit, then samples 8 bits.
  - Outputs the received byte and pulses `rx_done` for one clock.

- **Top level (`uart_top.v`)**
  - Instantiates the TX and RX blocks.
  - Connects them to the external `uart_tx_out` and `uart_rx_in` pins.

Think of it as: **byte in → serial bits out** (TX) and **serial bits in → byte out** (RX).

---

### 3. How the CPU talks to the UART

File: `uart_mmio_wrapper.v`

The wrapper makes the UART look like **two simple registers** to a CPU:

- At **address 0x0**
  - **Write**: send a byte (lower 8 bits of `wdata`).
  - **Read**: get `tx_busy` (1 = still sending, 0 = ready).

- At **address 0x4**
  - **Read**: get the last received byte in the lower 8 bits.

File: `software/uart_driver.c`

- Shows how C code would:
  - Wait until `tx_busy` is 0.
  - Write a character to the data register to send it.

So the flow is: **C code → MMIO registers → UART hardware → serial line**.

---

### 4. How to run a quick simulation

Goal: see one character go out of the UART and come back in (loopback).

The testbench `uart_system_tb.v`:

- Creates a clock.
- Resets the design.
- Pretends to be a CPU:
  - Writes `'A'` to the transmit register.
  - Waits until TX is done.
  - Waits until RX has received the byte.
  - Prints the received value.
- Dumps a waveform file `system.vcd`.

Run from the project root:

```bash
iverilog -g2012 -o uart_system_tb.out \
  uart_tx.v uart_rx.v uart_top.v uart_mmio_wrapper.v uart_system_tb.v
vvp uart_system_tb.out
gtkwave system.vcd &  # optional, to see waveforms
```

This lets a beginner **see the whole path** from CPU write → serial wire activity → CPU read.

---

### 5. Files and what they mean

- **`uart_tx.v`**: sends bytes out, 1 bit at a time.
- **`uart_rx.v`**: receives bits and rebuilds bytes.
- **`uart_top.v`**: connects TX and RX together.
- **`uart_mmio_wrapper.v`**: makes the UART look like registers to a CPU.
- **`uart_system_tb.v`**: simple system test with a fake CPU.
- **`software/uart_driver.c`**: example C code to send a character.
- **`config.json`**: settings for running an ASIC flow (clock, PDK, RTL files).
- **`gds/` and `reports/`**: examples of layout and timing/power reports from the ASIC flow.

If you are very new, focus first on:

1. `uart_system_tb.v` – see the whole story.  
2. `uart_top.v` – see how TX and RX are connected.  
3. `uart_tx.v` and `uart_rx.v` – learn how the state machines work.