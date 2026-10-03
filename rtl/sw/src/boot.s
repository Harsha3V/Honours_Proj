/* =============================================================================
 * boot.s  —  VeeR EL2 boot program
 *
 * Boots at reset vector 0x8000_0000.
 * 1. Sets up stack pointer
 * 2. Configures UART (LCR, baud, IER)
 * 3. Sends "Hello UART!\n" one byte at a time
 * 4. Loops forever (infinite idle loop)
 *
 * UART register map (base = 0x0000_0000):
 *   0x00  THR  — TX holding register (write to send byte)
 *   0x04  IER  — Interrupt enable
 *   0x08  BAUD — Baud divisor (DLAB=1 required)
 *   0x0C  LCR  — Line control  (bit3=DLAB, bit0=stop_bits, etc.)
 *   0x14  LSR  — Line status   (bit5=THRE TX ready, bit0=data ready)
 * =============================================================================*/

.section .text
.global _start

_start:
    /* ----------------------------------------------------------------
     * Set up stack pointer at top of DCCM (0xF004FFFC)
     * ----------------------------------------------------------------*/
    lui   sp, 0xF0050       /* sp = 0xF0050000 */
    addi  sp, sp, -4        /* sp = 0xF004FFFC */

    /* ----------------------------------------------------------------
     * UART base address in t0
     * ----------------------------------------------------------------*/
    li    t0, 0x00000000    /* UART base = 0x0 */

    /* ----------------------------------------------------------------
     * Step 1: Set DLAB=1 (bit3 of LCR=0x0C) to access baud register
     * ----------------------------------------------------------------*/
    li    t1, 0x08          /* DLAB=1 */
    sw    t1, 0x0C(t0)      /* LCR = 0x08 */

    /* ----------------------------------------------------------------
     * Step 2: Set baud divisor (0x0002 = ~115200 baud @ 50MHz clk/4)
     * ----------------------------------------------------------------*/
    li    t1, 0x0002
    sw    t1, 0x08(t0)      /* BAUD = 2 */

    /* ----------------------------------------------------------------
     * Step 3: Clear DLAB, set 8-bit data (LCR = 0x03)
     * ----------------------------------------------------------------*/
    li    t1, 0x03          /* 8N1, DLAB=0 */
    sw    t1, 0x0C(t0)      /* LCR = 0x03 */

    /* ----------------------------------------------------------------
     * Step 4: Enable RX interrupt (IER = 0x01)
     * ----------------------------------------------------------------*/
    li    t1, 0x01
    sw    t1, 0x04(t0)      /* IER = 0x01 */

    /* ----------------------------------------------------------------
     * Step 5: Send "Hello UART!\n"  one byte at a time
     * ----------------------------------------------------------------*/
    la    a0, hello_str     /* a0 = pointer to string */

send_loop:
    lbu   a1, 0(a0)         /* load next byte */
    beqz  a1, done          /* if null terminator, stop */
    call  uart_putchar      /* send the byte */
    addi  a0, a0, 1         /* advance pointer */
    j     send_loop

done:
    /* Infinite idle loop */
idle:
    j     idle

/* ----------------------------------------------------------------
 * uart_putchar  —  send byte in a1 via UART THR
 *   Polls LSR bit5 (THRE = TX holding register empty)
 *   before writing.
 * ----------------------------------------------------------------*/
uart_putchar:
    li    t0, 0x00000000    /* UART base */
wait_tx:
    lw    t2, 0x14(t0)      /* read LSR */
    andi  t2, t2, 0x20      /* check THRE (bit 5) */
    beqz  t2, wait_tx       /* wait if TX not ready */
    sw    a1, 0x00(t0)      /* write byte to THR */
    ret

/* ----------------------------------------------------------------
 * String data
 * ----------------------------------------------------------------*/
.section .rodata
hello_str:
    .string "Hello UART!\n"
