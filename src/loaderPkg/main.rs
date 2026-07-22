#![no_std]
#![no_main]

use core::panic::PanicInfo;

// EFI_STATUSの定義
pub type EfiStatus = usize;
pub const EFI_SUCCESS: EfiStatus = 0;
pub const EFI_BUFFER_TOO_SMALL: EfiStatus = 0x8000000000000005;

// EFI_MEMORY_DESCRIPTORの定義
#[repr(C)]
pub struct EfiMemoryDescriptor {
    pub type_: u32,
    pub physical_start: u64,
    pub virtual_start: u64,
    pub number_of_pages: u64,
    pub attribute: u64,
}

// Boot Servicesテーブルの定義（簡略版）
#[repr(C)]
pub struct BootServices {
    // 実際のBoot Servicesテーブルには多くのフィールドがありますが、
    // ここではGetMemoryMap関数のみを定義
    pub header: [u8; 56], // ヘッダー部分のパディング
    pub get_memory_map: unsafe extern "efiapi" fn(
        memory_map_size: *mut usize,
        memory_map: *mut EfiMemoryDescriptor,
        map_key: *mut usize,
        descriptor_size: *mut usize,
        descriptor_version: *mut u32,
    ) -> EfiStatus,
    // 他の関数ポインタ...
}

// MemoryMap構造体の定義
pub struct MemoryMap {
    pub buffer: Option<&'static mut [u8]>,
    pub buffer_size: usize,
    pub map_size: usize,
    pub map_key: usize,
    pub descriptor_size: usize,
    pub descriptor_version: u32,
}

#[derive(Debug)]
pub enum MemoryMapError {
    BufferTooSmall,
    InvalidParameter,
    Other(EfiStatus),
}

impl MemoryMap {
    // no_std環境なので、静的に割り当てられたバッファを使用
    pub fn new(buffer: &'static mut [u8]) -> Self {
        let buffer_size = buffer.len();
        Self {
            buffer: Some(buffer),
            buffer_size,
            map_size: 0,
            map_key: 0,
            descriptor_size: 0,
            descriptor_version: 0,
        }
    }

    pub fn get_memory_map(&mut self, boot_services: &BootServices)
        -> Result<(), MemoryMapError> {
        // バッファの存在確認
        if self.buffer.is_none() {
            return Err(MemoryMapError::BufferTooSmall);
        }

        self.map_size = self.buffer_size;

        // GetMemoryMapを呼び出し
        let status = unsafe {
            let buffer_ptr = self.buffer.as_mut().unwrap().as_mut_ptr();

            (boot_services.get_memory_map)(
                &mut self.map_size as *mut usize,
                buffer_ptr as *mut EfiMemoryDescriptor,
                &mut self.map_key as *mut usize,
                &mut self.descriptor_size as *mut usize,
                &mut self.descriptor_version as *mut u32,
            )
        };

        match status {
            EFI_SUCCESS => Ok(()),
            EFI_BUFFER_TOO_SMALL => Err(MemoryMapError::BufferTooSmall),
            status => Err(MemoryMapError::Other(status)),
        }
    }
}

// よりシンプルなC言語スタイルの実装（元のコードに近い）
pub unsafe fn get_memory_map_simple(
    map: *mut MemoryMap,
    boot_services: *const BootServices
) -> EfiStatus {
    unsafe {
        if (*map).buffer.is_none() {
            return EFI_BUFFER_TOO_SMALL;
        }

        (*map).map_size = (*map).buffer_size;

        let buffer = (*map).buffer.as_mut().unwrap();

        ((*boot_services).get_memory_map)(
            &mut (*map).map_size as *mut usize,
            buffer.as_mut_ptr() as *mut EfiMemoryDescriptor,
            &mut (*map).map_key as *mut usize,
            &mut (*map).descriptor_size as *mut usize,
            &mut (*map).descriptor_version as *mut u32,
        )
    }
}

// パニックハンドラ（no_std環境で必要）
#[panic_handler]
fn panic(_info: &PanicInfo) -> ! {
    // UEFI環境では適切なエラー処理を実装
    // ここでは単純に無限ループ
    loop {}
}

// UEFIエントリポイント
#[unsafe(no_mangle)]
pub extern "efiapi" fn efi_main(
    _handle: usize,
    _system_table: *const u8
) -> EfiStatus {
    // 実際のUEFIアプリケーションのエントリポイント
    EFI_SUCCESS
}