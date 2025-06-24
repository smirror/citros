#![no_std]
#![no_main]

use core::panic::PanicInfo;
use uefi::prelude::*;

#[panic_handler]
fn panic(_info: &PanicInfo) -> ! {
    loop {}
}

#[entry]
fn efi_main() -> Status {
    uefi::helpers::init().unwrap();

    system::with_stdout(|stdout| {
        stdout
            .output_string(cstr16!("Hello, World from UEFI!\r\n"))
            .ok();
    });

    loop {}
}
