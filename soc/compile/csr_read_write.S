.section .text
.global csr_write
.global csr_read

csr_write:
    csrrw x0,a0,a1
    ret
csr_read:
    csrrw a0,a0,a0
    ret