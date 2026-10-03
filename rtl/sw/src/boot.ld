/* boot.ld — Linker script for VeeR EL2 boot program
 * Reset vector = 0x8000_0000  (RV_RESET_VEC from common_defines.vh)
 * Stack in DCCM  = 0xF004_FFFC
 */

ENTRY(_start)

MEMORY {
    ROM  (rx)  : ORIGIN = 0x80000000, LENGTH = 4K
    DCCM (rw)  : ORIGIN = 0xF0040000, LENGTH = 64K
}

SECTIONS {
    .text 0x80000000 : {
        *(.text*)
    } > ROM

    .rodata : {
        *(.rodata*)
    } > ROM

    .bss : {
        *(.bss*)
    } > DCCM
}
