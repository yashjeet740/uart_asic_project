#define UART_BASE 0x40001000
#define UART_DATA_REG (*(volatile unsigned int *)(UART_BASE + 0x00))
#define UART_STATUS_REG (*(volatile unsigned int *)(UART_BASE + 0x00))

void uart_send_char(char c) {
    // 1. Wait until TX is not busy (reading the status bit)
    while (UART_STATUS_REG & 0x01); 
    
    // 2. Write the character to the data register
    UART_DATA_REG = c; 
}
