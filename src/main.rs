#![no_std]
#![no_main]

use core::arch::asm;
use core::panic::PanicInfo;

#[panic_handler]
fn panic(_info: &PanicInfo) -> ! {
    loop {
        unsafe {
            asm!("hlt");
        }
    }
}

#[unsafe(no_mangle)]
pub extern "C" fn KernelMain() -> ! {
    loop {
        unsafe {
            asm!("hlt");
        }
    }
}

// UEFI用のエントリーポイント
#[unsafe(no_mangle)]
pub extern "C" fn efi_main() -> ! {
    KernelMain()
}