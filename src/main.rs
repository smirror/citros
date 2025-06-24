#![no_std]
#![no_main]

use uefi::prelude::*;
use core::panic::PanicInfo;

#[panic_handler]
fn panic(_info: &PanicInfo) -> ! {
    loop {}
}

#[entry]
fn efi_main() -> Status {
    uefi::helpers::init().unwrap();

    system::with_stdout(|stdout| {
        stdout.output_string(cstr16!("Hello, World from UEFI!\r\n")).ok();
    });

    loop {}
    Status::SUCCESS
}
