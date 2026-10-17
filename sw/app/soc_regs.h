/* =============================================================================
 * Project        : Honours Project — AES-128 ECU Gateway SoC
 * File           : soc_regs.h
 * Description    : Hardware Register Map and Drivers for VeeR EL2 SoC.
 *
 * Memory Map:
 *   AES-128 Engine   : 0x0000_0000
 *   DMA Controller   : 0x0100_0000
 *   SPI Master       : 0x0200_0000
 *   UART             : 0x0300_0000
 *   Timer EF_TCC32   : 0x0400_0000
 *   GPIO EF_GPIO8    : 0x0500_0000
 *   AXI SRAM Buffer  : 0x0600_0000
 *   DCCM Data Memory : 0xF004_0000
 *   ICCM Code Memory : 0xEE00_0000
 *   Boot ROM         : 0x8000_0000
 * =============================================================================*/

#ifndef SOC_REGS_H
#define SOC_REGS_H

#include <stdint.h>

#define REG32(addr) (*(volatile uint32_t *)(uintptr_t)(addr))
#define REG8(addr)  (*(volatile uint8_t  *)(uintptr_t)(addr))

// =============================================================================
// Base Addresses
// =============================================================================
#define AES_BASE        0x00000000UL
#define DMA_BASE        0x01000000UL
#define SPI_BASE        0x02000000UL
#define UART_BASE       0x03000000UL
#define TIMER_BASE      0x04000000UL
#define GPIO_BASE       0x05000000UL
#define SRAM_BASE       0x06000000UL
#define DCCM_BASE       0xF0040000UL

// =============================================================================
// 1. AES-128 Engine Registers (0x0000_0000)
// =============================================================================
#define AES_CSR_REG     REG32(AES_BASE + 0x00)
#define AES_KEY0_REG    REG32(AES_BASE + 0x04)
#define AES_KEY1_REG    REG32(AES_BASE + 0x08)
#define AES_KEY2_REG    REG32(AES_BASE + 0x0C)
#define AES_KEY3_REG    REG32(AES_BASE + 0x10)
#define AES_TEXTIN0_REG REG32(AES_BASE + 0x14)
#define AES_TEXTIN1_REG REG32(AES_BASE + 0x18)
#define AES_TEXTIN2_REG REG32(AES_BASE + 0x1C)
#define AES_TEXTIN3_REG REG32(AES_BASE + 0x20)
#define AES_TEXTOUT0_REG REG32(AES_BASE + 0x24)
#define AES_TEXTOUT1_REG REG32(AES_BASE + 0x28)
#define AES_TEXTOUT2_REG REG32(AES_BASE + 0x2C)
#define AES_TEXTOUT3_REG REG32(AES_BASE + 0x30)

#define AES_CSR_DONE    (1U << 0)
#define AES_CSR_BUSY    (1U << 1)
#define AES_CSR_START   (1U << 16)

static inline void aes_set_key(const uint32_t key[4]) {
    AES_KEY0_REG = key[0];
    AES_KEY1_REG = key[1];
    AES_KEY2_REG = key[2];
    AES_KEY3_REG = key[3];
}

static inline void aes_encrypt_block(const uint32_t plain[4], uint32_t cipher[4]) {
    AES_TEXTIN0_REG = plain[0];
    AES_TEXTIN1_REG = plain[1];
    AES_TEXTIN2_REG = plain[2];
    AES_TEXTIN3_REG = plain[3];

    // Trigger encryption
    AES_CSR_REG = AES_CSR_START;

    // Poll for hardware completion (10 rounds ~10-12 clock cycles)
    while (!(AES_CSR_REG & AES_CSR_DONE));

    cipher[0] = AES_TEXTOUT0_REG;
    cipher[1] = AES_TEXTOUT1_REG;
    cipher[2] = AES_TEXTOUT2_REG;
    cipher[3] = AES_TEXTOUT3_REG;
}

// =============================================================================
// 2. DMA Controller Registers (0x0100_0000)
// =============================================================================
#define DMA_CTRL_REG      REG32(DMA_BASE + 0x00)
#define DMA_STATUS_REG    REG32(DMA_BASE + 0x08)
#define DMA_DESC0_SRC_REG REG32(DMA_BASE + 0x20)
#define DMA_DESC0_DST_REG REG32(DMA_BASE + 0x30)
#define DMA_DESC0_LEN_REG REG32(DMA_BASE + 0x40)

#define DMA_CTRL_GO       (1U << 0)
#define DMA_CTRL_ABORT    (1U << 1)
#define DMA_STATUS_DONE   (1U << 16)
#define DMA_STATUS_ERROR  (1U << 17)

static inline void dma_transfer(uint32_t src, uint32_t dst, uint32_t bytes) {
    DMA_DESC0_SRC_REG = src;
    DMA_DESC0_DST_REG = dst;
    DMA_DESC0_LEN_REG = bytes;
    DMA_CTRL_REG      = DMA_CTRL_GO;
}

static inline int dma_poll_done(void) {
    uint32_t st = DMA_STATUS_REG;
    if (st & DMA_STATUS_DONE)  return 1;
    if (st & DMA_STATUS_ERROR) return -1;
    return 0;
}

// =============================================================================
// 3. SPI Master Registers (0x0200_0000) — Connects to MCP2515 CAN controller
// =============================================================================
#define SPI_TX_DATA_REG   REG32(SPI_BASE + 0x00)
#define SPI_RX_DATA_REG   REG32(SPI_BASE + 0x04)
#define SPI_STATUS_REG    REG32(SPI_BASE + 0x08)
#define SPI_TX_COUNT_REG  REG32(SPI_BASE + 0x0C)

#define SPI_STATUS_TX_READY (1U << 0)
#define SPI_STATUS_RX_DV    (1U << 1)

static inline void spi_init(uint8_t bytes_per_cs) {
    SPI_TX_COUNT_REG = bytes_per_cs;
}

static inline void spi_send_byte(uint8_t data) {
    while (!(SPI_STATUS_REG & SPI_STATUS_TX_READY));
    SPI_TX_DATA_REG = (uint32_t)data;
}

static inline uint8_t spi_read_byte(void) {
    return (uint8_t)(SPI_RX_DATA_REG & 0xFF);
}

// =============================================================================
// 4. UART Registers (0x0300_0000)
// =============================================================================
#define UART_RBR_REG      REG32(UART_BASE + 0x00)
#define UART_THR_REG      REG32(UART_BASE + 0x00)
#define UART_IER_REG      REG32(UART_BASE + 0x04)
#define UART_BAUD_REG     REG32(UART_BASE + 0x08)
#define UART_LCR_REG      REG32(UART_BASE + 0x0C)
#define UART_LSR_REG      REG32(UART_BASE + 0x14)

#define UART_LSR_DR       (1U << 0)  // Data Ready in RX FIFO
#define UART_LSR_THRE     (1U << 5)  // Transmit Holding Register Empty

static inline void uart_init(uint32_t baud_div) {
    UART_BAUD_REG = baud_div; // 868 for 115200 @ 100MHz
    UART_LCR_REG  = 0x03;     // 8 data bits, 1 stop bit, no parity (8-N-1)
}

static inline void uart_putc(char c) {
    while (!(UART_LSR_REG & UART_LSR_THRE));
    UART_THR_REG = (uint32_t)(uint8_t)c;
}

static inline void uart_puts(const char *s) {
    while (*s) {
        if (*s == '\n') uart_putc('\r');
        uart_putc(*s++);
    }
}

static inline int uart_getc_nonblocking(char *c) {
    if (UART_LSR_REG & UART_LSR_DR) {
        *c = (char)(UART_RBR_REG & 0xFF);
        return 1;
    }
    return 0;
}

// =============================================================================
// 5. Timer EF_TCC32 Registers (0x0400_0000)
// =============================================================================
#define TIMER_COUNT_REG   REG32(TIMER_BASE + 0x0000)
#define TIMER_PERIOD_REG  REG32(TIMER_BASE + 0x0004)
#define TIMER_CTRL_REG    REG32(TIMER_BASE + 0x0010)
#define TIMER_ICR_REG     REG32(TIMER_BASE + 0x0F00)
#define TIMER_IM_REG      REG32(TIMER_BASE + 0x0F08)

static inline void timer_init(uint32_t period) {
    TIMER_PERIOD_REG = period;
    TIMER_CTRL_REG   = 0x03;   // EN=1, TMR_EN=1
    TIMER_IM_REG     = 0x01;   // Enable Timeout Interrupt
}

static inline void timer_clear_irq(void) {
    TIMER_ICR_REG = 0x01;
}

// =============================================================================
// 6. GPIO EF_GPIO8 Registers (0x0500_0000)
// =============================================================================
#define GPIO_DATAI_REG    REG32(GPIO_BASE + 0x0000)
#define GPIO_DATAO_REG    REG32(GPIO_BASE + 0x0004)
#define GPIO_DIR_REG      REG32(GPIO_BASE + 0x0008)

static inline void gpio_set_dir(uint8_t dir_mask) {
    GPIO_DIR_REG = (uint32_t)dir_mask; // 1 = Output, 0 = Input
}

static inline void gpio_write(uint8_t val) {
    GPIO_DATAO_REG = (uint32_t)val;
}

static inline uint8_t gpio_read(void) {
    return (uint8_t)(GPIO_DATAI_REG & 0xFF);
}

#endif // SOC_REGS_H
