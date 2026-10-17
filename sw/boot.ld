/* =============================================================================
 * File    : boot.ld
 * Project : Honours Project — VeeR EL2 Encrypted ECU Gateway SoC
 * Desc    : Linker script supporting C runtime startup.
 *
 * Memory map:
 *   ROM  : 0x8000_0000  (16 KB) — Boot ROM (IFU AXI fetch)
 *   DCCM : 0xF004_0000  (64 KB) — Fast Data RAM / Stack / Heap
 *   SRAM : 0x0600_0000  (64 KB) — AXI Shared Buffer (CPU + DMA)
 * =============================================================================*/

MEMORY
{
    ROM  (rx)  : ORIGIN = 0x80000000, LENGTH = 16K
    DCCM (rwx) : ORIGIN = 0xF0040000, LENGTH = 64K
    SRAM (rwx) : ORIGIN = 0x06000000, LENGTH = 64K
}

ENTRY(_start)

SECTIONS
{
    /* ------------------------------------------------------------------ */
    /* .text — executable code and read-only data placed in ROM          */
    /* ------------------------------------------------------------------ */
    .text 0x80000000 :
    {
        *(.text.boot)       /* _start entry must be first                 */
        *(.text*)
        *(.rodata*)
        . = ALIGN(4);
        _etext = .;
    } > ROM

    /* LMA address of .data in ROM */
    _sidata = LOADADDR(.data);

    /* ------------------------------------------------------------------ */
    /* .data — initialized globals placed in DCCM                         */
    /* ------------------------------------------------------------------ */
    .data : AT(_sidata)
    {
        _sdata = .;
        *(.data*)
        . = ALIGN(4);
        _edata = .;
    } > DCCM

    /* ------------------------------------------------------------------ */
    /* .bss — zero-initialized globals in DCCM                            */
    /* ------------------------------------------------------------------ */
    .bss :
    {
        _sbss = .;
        *(.bss*)
        *(COMMON)
        . = ALIGN(4);
        _ebss = .;
    } > DCCM

    /* ------------------------------------------------------------------ */
    /* Shared AXI Staging Buffer in on-chip SRAM                          */
    /* ------------------------------------------------------------------ */
    .sram_buf (NOLOAD) :
    {
        *(.sram_buf*)
    } > SRAM
}
