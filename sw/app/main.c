/* =============================================================================
 * Project        : Honours Project — AES-128 ECU Gateway SoC
 * File           : main.c
 * Description    : Autonomous Hardware-Accelerated Encrypted ECU Gateway.
 *
 * Execution Flow:
 *   1. Initialize UART at 115200 baud (100 MHz clock divisor = 868).
 *   2. Print SoC banner and configuration info.
 *   3. Configure GPIO direction (LED outputs).
 *   4. Load 128-bit AES Encryption Key into hardware engine (FIPS-197).
 *   5. Setup ECU sensor frame in AXI Staging SRAM (CAN ID + Plaintext).
 *   6. Hardware-accelerate AES-128 encryption (~10 cycles).
 *   7. Dispatch encrypted frame via SPI to external MCP2515 CAN controller.
 *   8. Report status and ciphertext over UART.
 * =============================================================================*/

#include "soc_regs.h"

// NIST FIPS-197 Appendix B Test Vectors
// Key:       2b 7e 15 16 28 ae d2 a6 ab f7 15 88 09 cf 4f 3c
// Plaintext: 32 43 f6 a8 88 5a 30 8d 31 31 98 a2 e0 37 07 34
// Ciphertext:39 25 84 1d 02 dc 09 fb dc 11 85 97 19 6a 0b 32
static const uint32_t nist_key[4] = {
    0x16157e2bUL, 0xa6d2ae28UL, 0x8815f7abUL, 0x3c4fcf09UL
};

static const uint32_t ecu_plaintext[4] = {
    0xa8f64332UL, 0x8d305a88UL, 0xa2983131UL, 0x340737e0UL
};

static uint32_t ciphertext[4];

static inline char hex_nibble(uint8_t n) {
    return (n < 10) ? ('0' + n) : ('A' + n - 10);
}

static void print_hex32(uint32_t val) {
    for (int i = 7; i >= 0; i--) {
        uart_putc(hex_nibble((uint8_t)((val >> (i * 4)) & 0xFU)));
    }
}

int main(void) {
    // 1. Initialize Peripherals
    uart_init(868);        // 115200 baud at 100 MHz
    gpio_set_dir(0xFF);    // GPIO pins [7:0] as outputs
    gpio_write(0x01);      // Turn on Status LED 0
    spi_init(16);          // 16 bytes per SPI frame transaction

    // 2. Print Startup Banner
    uart_puts("\n======================================================\n");
    uart_puts(" RISC-V Hardware-Accelerated Encrypted ECU Gateway\n");
    uart_puts(" VeeR EL2 RV32IMC Core + NIST AES-128 + AXI4 Crossbar\n");
    uart_puts(" Roll No: 1602-23-735-189 (Honours Project)\n");
    uart_puts("======================================================\n\n");

    // 3. Configure Hardware AES-128 Engine
    uart_puts("[SEC] Loading 128-bit AUTOSAR SecOC AES Key...\n");
    aes_set_key(nist_key);
    uart_puts("[SEC] Key successfully loaded into AES hardware engine.\n");

    // 4. Stage ECU Frame into AXI SRAM (0x0600_0000)
    volatile uint32_t *sram_staging = (volatile uint32_t *)SRAM_BASE;
    sram_staging[0] = ecu_plaintext[0];
    sram_staging[1] = ecu_plaintext[1];
    sram_staging[2] = ecu_plaintext[2];
    sram_staging[3] = ecu_plaintext[3];

    uart_puts("[ECU] Plaintext Frame Staged in AXI SRAM:\n");
    uart_puts("      Payload: 0x");
    for (int i = 0; i < 4; i++) print_hex32(ecu_plaintext[i]);
    uart_puts("\n");

    // 5. Hardware AES-128 Encryption
    gpio_write(0x03);      // LED 0 + 1 (Encryption in progress)
    uart_puts("[AES] Triggering autonomous 10-round hardware pipeline...\n");

    aes_encrypt_block(ecu_plaintext, ciphertext);

    // Read hardware-accelerated ciphertext from AES engine
    uint32_t c0 = AES_TEXTOUT0_REG;
    uint32_t c1 = AES_TEXTOUT1_REG;
    uint32_t c2 = AES_TEXTOUT2_REG;
    uint32_t c3 = AES_TEXTOUT3_REG;

    uart_puts("[AES] Encryption complete! Ciphertext generated:\n");
    uart_puts("      Cipher : 0x");
    print_hex32(c0);
    print_hex32(c1);
    print_hex32(c2);
    print_hex32(c3);
    uart_puts("\n");

    // Store ciphertext back to SRAM staging buffer (0x0600_0010)
    sram_staging[4] = c0;
    sram_staging[5] = c1;
    sram_staging[6] = c2;
    sram_staging[7] = c3;

    // 6. Dispatch Encrypted Frame over SPI to MCP2515 CAN Controller
    gpio_write(0x07);      // LED 0 + 1 + 2 (SPI Transmission active)
    uart_puts("[SPI] Transmitting encrypted frame to MCP2515 CAN bus...\n");

    spi_send_byte((uint8_t)(c0 >> 0));
    spi_send_byte((uint8_t)(c0 >> 8));
    spi_send_byte((uint8_t)(c0 >> 16));
    spi_send_byte((uint8_t)(c0 >> 24));

    spi_send_byte((uint8_t)(c1 >> 0));
    spi_send_byte((uint8_t)(c1 >> 8));
    spi_send_byte((uint8_t)(c1 >> 16));
    spi_send_byte((uint8_t)(c1 >> 24));

    spi_send_byte((uint8_t)(c2 >> 0));
    spi_send_byte((uint8_t)(c2 >> 8));
    spi_send_byte((uint8_t)(c2 >> 16));
    spi_send_byte((uint8_t)(c2 >> 24));

    spi_send_byte((uint8_t)(c3 >> 0));
    spi_send_byte((uint8_t)(c3 >> 8));
    spi_send_byte((uint8_t)(c3 >> 16));
    spi_send_byte((uint8_t)(c3 >> 24));

    uart_puts("[SPI] 16 bytes transmitted over SPI (MOSI).\n");
    uart_puts("[SUCCESS] ECU Gateway Secure Transaction Completed Successfully!\n\n");

    gpio_write(0x05);      // Green LED: System Ready & Secure

    // 7. Background Loop: Heartbeat
    uint32_t heartbeat = 0;
    while (1) {
        heartbeat++;
        if ((heartbeat & 0x7FFFF) == 0) {
            gpio_write(gpio_read() ^ 0x01); // Toggle heartbeat LED
        }
    }

    return 0;
}
