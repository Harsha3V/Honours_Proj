/* =============================================================================
 * File    : boot.S
 * Project : Honours Project — VeeR EL2 Encrypted ECU Gateway SoC
 * Desc    : RISC-V C runtime startup assembly (CRT0).
 *
 * Responsibilities:
 *   1. Set stack pointer (sp) to top of DCCM (0xF004_FFFC).
 *   2. Copy initialised .data section from ROM (LMA) to DCCM (VMA).
 *   3. Zero-out .bss section in DCCM.
 *   4. Call C application main().
 *   5. Spin in infinite loop on return.
 * =============================================================================*/

    .section .text.boot, "ax", @progbits
    .global  _start
    .type    _start, @function

_start:
    /* ------------------------------------------------------------------ */
    /* 1. Set up stack pointer (top of 64KB DCCM at 0xF004_0000)          */
    /*    Top address: 0xF004_FFFC (4-byte aligned)                       */
    /* ------------------------------------------------------------------ */
    lui     sp, 0xF0050
    addi    sp, sp, -4

    /* ------------------------------------------------------------------ */
    /* Configure MRAC (CSR 0x7C0) to mark Region 0 (0x0000_0000 to         */
    /* 0x0FFF_FFFF) as non-cacheable side-effect I/O (peripherals)         */
    /* ------------------------------------------------------------------ */
    li      t0, 0x00000002
    csrw    0x7C0, t0

    /* ------------------------------------------------------------------ */
    /* 2. Copy .data from ROM (_sidata) to DCCM (_sdata .. _edata)        */
    /* ------------------------------------------------------------------ */
    la      a0, _sidata             /* Source address in ROM              */
    la      a1, _sdata              /* Destination address in DCCM        */
    la      a2, _edata              /* End address in DCCM                */
    bgeu    a1, a2, copy_data_done

copy_data_loop:
    lw      t0, 0(a0)
    sw      t0, 0(a1)
    addi    a0, a0, 4
    addi    a1, a1, 4
    bltu    a1, a2, copy_data_loop
copy_data_done:

    /* ------------------------------------------------------------------ */
    /* 3. Zero-out .bss section (_sbss .. _ebss) in DCCM                  */
    /* ------------------------------------------------------------------ */
    la      a0, _sbss
    la      a1, _ebss
    bgeu    a0, a1, zero_bss_done

zero_bss_loop:
    sw      zero, 0(a0)
    addi    a0, a0, 4
    bltu    a0, a1, zero_bss_loop
zero_bss_done:

    /* ------------------------------------------------------------------ */
    /* 4. Jump to C application main()                                    */
    /* ------------------------------------------------------------------ */
    call    main

    /* ------------------------------------------------------------------ */
    /* 5. Infinite loop if main returns                                   */
    /* ------------------------------------------------------------------ */
halt:
    wfi
    j       halt

    .size _start, . - _start
