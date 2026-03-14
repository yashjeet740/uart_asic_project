## UART ASIC Project

### 1. Why this project is cool

Imagine taking the tiny UART block behind a USB‑to‑serial cable… and **turning it into your own chip**.  
This repo is a **small, friendly UART design** that you can:

- Simulate on your laptop.
- Drive from simple C code.
- Push through an open‑source **Sky130** flow to see real ASIC layout.

If you’re curious about “how does a serial port actually work under the hood?”, this project walks you through it step by step.

---

### 2. How the UART works (big picture)

Think of the UART as a **translator between bytes and timed pulses** on a wire:

- **Transmitter (`uart_tx.v`)**
  - Takes an 8‑bit value.
  - Sends it out one bit at a time on the `tx` wire (start bit → 8 data bits → stop bit).
  - Uses a counter (`CLKS_PER_BIT`) to control how long each bit stays on the line.

- **Receiver (`uart_rx.v`)**
  - Watches the `rx` wire for a falling edge (start bit).
  - Samples 8 bits at the right times.
  - Rebuilds the original byte and pulses `rx_done` for one clock.

- **Top level (`uart_top.v`)**
  - Glues TX and RX together.
  - Connects them to `uart_tx_out` and `uart_rx_in`.

So the mental model is: **byte in → serial bits out** (TX) and **serial bits in → byte out** (RX).

---

### 3. How the CPU talks to the UART

File: `uart_mmio_wrapper.v`

To the CPU, the UART just looks like **two simple registers**:

- At **address 0x0**
  - **Write**: send a byte (lower 8 bits of `wdata`).
  - **Read**: see `tx_busy` (1 = still sending, 0 = ready for next byte).

- At **address 0x4**
  - **Read**: get the last received byte in the lower 8 bits.

File: `software/uart_driver.c`

- Shows how simple C code would:
  - Wait until `tx_busy` is 0.
  - Write a character to the data register to send it.

You can remember the flow as:  
**C code → MMIO registers → UART hardware → serial line → UART hardware → MMIO registers → C code**.

---

### 4. Run a quick “serial story” simulation

Goal: watch a single character leave the “CPU”, travel across a wire, and come back.

The testbench `uart_system_tb.v`:

- Creates a clock and reset.
- Plays the role of a tiny CPU:
  - Writes `'A'` to the transmit register.
  - Waits until TX is done.
  - Waits until RX has received the byte.
  - Prints the received value.
- Dumps a waveform file `system.vcd` so you can see the bits move.

Run from the project root:

```bash
iverilog -g2012 -o uart_system_tb.out \
  uart_tx.v uart_rx.v uart_top.v uart_mmio_wrapper.v uart_system_tb.v
vvp uart_system_tb.out
gtkwave system.vcd &  # optional, to see waveforms
```

You’ll literally see the **whole story**: fake CPU write → serial wiggles on `uart_wire` → byte showing up again in the CPU’s read data.

---

### 5. Files and how to explore them

- **`uart_tx.v`**: sends bytes out, 1 bit at a time.
- **`uart_rx.v`**: receives bits and rebuilds bytes.
- **`uart_top.v`**: connects TX and RX together.
- **`uart_mmio_wrapper.v`**: makes the UART look like registers to a CPU.
- **`uart_system_tb.v`**: simple system test with a fake CPU.
- **`software/uart_driver.c`**: example C code to send a character.
- **`config.json`**: settings for running an ASIC flow (clock, PDK, RTL files).
- **`gds/` and `reports/`**: layout and timing/power artifacts from the ASIC flow.

If you’re new, a nice path is:

1. Open `uart_system_tb.v` and run the sim → see what happens.  
2. Open `uart_top.v` → see how TX and RX are wired.  
3. Dive into `uart_tx.v` and `uart_rx.v` → understand the state machines and timing.  
4. When you’re ready for ASIC details, peek into `config.json`, `gds/`, and `reports/`.