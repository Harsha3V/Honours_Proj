/* =============================================================================
 * File    : boot.S
 * Project : Honours Project — VeeR EL2 + UART SoC
 * Desc    : RISC-V RV32IMC boot program.
 *
 *   1. Initialise the AXI-Lite UART:
 *        - Write baud-rate divisor  (100 MHz / 115200 ≈ 868 = 0x364)
 *        - Write LCR = 0x03  (8-N-1, no parity, 1 stop bit)
 *   2. Send the string "Hello UART\r\n" one byte at a time,
 *      polling the LSR THRE bit (bit 5) before each byte.
 *   3. Spin in an infinite loop.
 *
 * UART register map (base = 0x0000_0000, decode on addr[4:2]):
 *   0x00  THR / RBR   (addr[4:2] = 3'd0)
 *   0x04  IER         (addr[4:2] = 3'd1)
 *   0x08  BAUD_DIV    (addr[4:2] = 3'd2)
 *   0x0C  LCR         (addr[4:2] = 3'd3)
 *   0x14  LSR         (addr[4:2] = 3'd5)
 *
 * VeeR EL2 default reset vector: 0x8000_0000
 * This program is linked to start at 0x8000_0000.
 * =============================================================================*/

    .section .text.boot, "ax", @progbits
    .global  _start
    .type    _start, @function

_start:
    /* ------------------------------------------------------------------ */
    /* 1. Set up stack pointer (top of DCCM)                               */
    /*    Actual DCCM range: 0xF004_0000 .. 0xF004_FFFF (64 KB)           */
    /*    Stack at top: 0xF004_FFFC (aligned to 4 bytes)                  */
    /* ------------------------------------------------------------------ */
    lui     sp, 0xF0050       /* sp = 0xF0050000                          */
    addi    sp, sp, -4        /* sp = 0xF004FFFC (top of DCCM)            */

    /* ------------------------------------------------------------------ */
    /* 2. Base address of UART                                             */
    /* ------------------------------------------------------------------ */
    li      a0, 0x00000000          /* UART_BASE = 0x0000_0000            */

    /* ------------------------------------------------------------------ */
    /* 3. Set baud-rate divisor = 868 (0x364)                             */
    /*    100 MHz clock / 115200 baud = 868.05 → 868                      */
    /*    Register: UART_BASE + 0x08                                       */
    /* ------------------------------------------------------------------ */
    li      t0, 868
    sw      t0, 0x08(a0)            /* write BAUD_DIV                     */

    /* ------------------------------------------------------------------ */
    /* 4. Set LCR = 0x03  → 8-bit word, 1 stop bit, no parity            */
    /*    Register: UART_BASE + 0x0C                                       */
    /* ------------------------------------------------------------------ */
    li      t0, 0x03
    sw      t0, 0x0C(a0)            /* write LCR                          */

    /* ------------------------------------------------------------------ */
    /* 5. Transmit "Hello UART\r\n"                                        */
    /*    Load the address of the string, then call uart_putchar for each  */
    /* ------------------------------------------------------------------ */
    la      a1, hello_str           /* a1 = pointer to string             */
send_loop:
    lbu     t1, 0(a1)               /* load next byte                     */
    beqz    t1, done                /* null terminator → done             */
    mv      a2, t1                  /* character to send in a2            */
    call    uart_putchar            /* send it                            */
    addi    a1, a1, 1               /* advance pointer                    */
    j       send_loop

    /* ------------------------------------------------------------------ */
    /* 6. Infinite loop — CPU halts here after sending the string          */
    /* ------------------------------------------------------------------ */
done:
    j       done

/* ======================================================================
 * uart_putchar
 *   Send one character (in a2) over the UART.
 *   Polls LSR.THRE (bit 5) until TX holding register is empty, then
 *   writes the byte to THR.
 *
 *   Arguments : a0 = UART base address
 *               a2 = character to send (byte)
 *   Clobbers  : t2, t3
 * ====================================================================== */
uart_putchar:
    /* Poll LSR (offset 0x14) bit 5 (THRE = TX Holding Register Empty) */
wait_thre:
    lw      t2, 0x14(a0)            /* read LSR                           */
    andi    t2, t2, 0x20            /* mask THRE bit (bit 5 = 0x20)       */
    beqz    t2, wait_thre           /* loop while THRE == 0               */

    /* Write character to THR (offset 0x00) */
    sw      a2, 0x00(a0)            /* write to THR                       */
    ret

/* ======================================================================
 * Read-only data: the string to transmit
 * ====================================================================== */
    .section .rodata
    .align 2
hello_str:
    .string "Hello UART\r\n"
