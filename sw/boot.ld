/* =============================================================================
 * File    : boot.ld
 * Project : Honours Project — VeeR EL2 + UART SoC
 * Desc    : Linker script for the RISC-V boot program.
 *
 * Memory map (must match VeeR EL2 default config):
 *
 *   ROM  : 0x8000_0000  (16 KB)  — instruction fetch via IFU AXI → ifu_rom_stub
 *   DCCM : 0x5000_0000  (128 KB) — data / stack (VeeR EL2 default DCCM range)
 *
 * The IFU ROM stub (ifu_rom_stub.v) is loaded with boot.hex at simulation
 * start.  The stub maps byte address 0x8000_0000 to ROM word index 0 by
 * stripping the top bits inside the module.
 * =============================================================================*/

MEMORY
{
    ROM  (rx)  : ORIGIN = 0x80000000, LENGTH = 16K
    DCCM (rwx) : ORIGIN = 0xF0040000, LENGTH = 64K
}

ENTRY(_start)

SECTIONS
{
    /* ------------------------------------------------------------------ */
    /* .text — executable code, placed in ROM                             */
    /* ------------------------------------------------------------------ */
    .text 0x80000000 :
    {
        *(.text.boot)       /* _start must be first                       */
        *(.text*)
        *(.rodata*)
        . = ALIGN(4);
    } > ROM

    /* ------------------------------------------------------------------ */
    /* .data — initialised globals, placed in DCCM                        */
    /* (We have no C runtime, so this is empty for a pure-asm program)    */
    /* ------------------------------------------------------------------ */
    .data :
    {
        *(.data*)
        . = ALIGN(4);
    } > DCCM

    /* ------------------------------------------------------------------ */
    /* .bss — zero-initialised globals                                     */
    /* ------------------------------------------------------------------ */
    .bss :
    {
        *(.bss*)
        *(COMMON)
        . = ALIGN(4);
    } > DCCM

    /* ------------------------------------------------------------------ */
    /* Stack sits at the top of DCCM — sp is set manually in _start       */
    /* ------------------------------------------------------------------ */
}
