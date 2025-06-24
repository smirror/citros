#!/usr/bin/env bash

# スクリプトが途中で失敗したときに、エラーを表示して終了する
set -e

# --- 変数の設定 ---
# ディスクイメージファイル名
DISK_IMG="disk.img"
# マウント先のディレクトリ
MOUNT_POINT="/mnt/citros"
# ビルドされるEFIファイルのパス
EFI_FILE="target/x86_64-unknown-uefi/release/citros.efi"
# QEMU用のOVMFファームウェアファイルがあるディレクトリ
# ご自身の環境に合わせてパスを修正してください
OVMF_DIR="./mikanos-build/devenv"


# --- クリーンアップ用の関数定義 ---
# スクリプト終了時に、マウントとループデバイスを確実に解除するための関数
cleanup() {
  # ループデバイスが設定されていれば解除
  if [ -n "${LOOP_DEV}" ] && [ -b "${LOOP_DEV}" ]; then
    echo "Detaching loop device ${LOOP_DEV}..."
    sudo losetup -d "${LOOP_DEV}"
  fi
}
# スクリプトが終了する際(EXIT)にcleanup関数を呼び出すように設定
trap cleanup EXIT

# 1. Rustコードのビルド
echo "Building a kernel..."
cargo build --release

# 2. ディスクイメージの作成
# (dosfstools パッケージが必要な場合があります: sudo apt install dosfstools)
echo "Creating disk image..."
qemu-img create -f raw "${DISK_IMG}" 200M
mkfs.fat -n 'CitrOS' -s 2 -f 2 -R 32 -F 32 "${DISK_IMG}"

# 3. ディスクイメージをループデバイスにアタッチしてマウント
echo "Mounting disk image..."
# 空いているループデバイスを探して、イメージファイルをアタッチ
# --show オプションで使われたデバイス名を取得
LOOP_DEV=$(sudo losetup -f --show "${DISK_IMG}")
if [ ! -b "${LOOP_DEV}" ]; then
    echo "Failed to set up loop device."
    exit 1
fi

# マウントポイントを作成し、ループデバイスをマウント
sudo mkdir -p "${MOUNT_POINT}"
sudo mount "${LOOP_DEV}" "${MOUNT_POINT}"

# 4. EFIファイルをディスクイメージにコピー
echo "Copying EFI file..."
sudo mkdir -p "${MOUNT_POINT}/EFI/BOOT"
sudo cp "${EFI_FILE}" "${MOUNT_POINT}/EFI/BOOT/BOOTX64.EFI"

# 5. アンマウント
# (ループデバイスの解除はtrapで設定したcleanup関数が自動的に行います)
echo "Unmounting disk image..."
sudo umount "${MOUNT_POINT}"

echo "Setup finished successfully."
echo "-------------------------------------"

# 6. QEMUでOSを起動
echo "Starting QEMU..."
qemu-system-x86_64 \
    -drive if=pflash,format=raw,file="${OVMF_DIR}/OVMF_CODE.fd" \
    -drive if=pflash,format=raw,file="${OVMF_DIR}/OVMF_VARS.fd" \
    -hda "${DISK_IMG}"