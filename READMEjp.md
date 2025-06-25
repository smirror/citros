# CitrOS

CitrOSは、[MikanOS](https://github.com/uchan-nos/mikanos)にインスパイアされたRust言語で書かれた教育用オペレーティングシステムです。ベアメタルプログラミングとUEFIアプリケーション開発の理解を目的とした学習プロジェクトとして設計されています。

## 特徴

- **ベアメタルRust**: システムレベルプログラミングのために`#![no_std]`と`#![no_main]`を使用
- **UEFIアプリケーション**: x86_64システム上でUEFIアプリケーションとして動作
- **最小限の依存関係**: UEFI APIアクセスのために`uefi`クレートのみを使用
- **教育重視**: OS開発コンセプトを学ぶためのシンプルで読みやすいコード

## 現在のステータス

CitrOSは開発初期段階（v0.1.0）です。現在の実装は以下の通りです：

- UEFIサービスの初期化
- コンソールに「Hello, World from UEFI!」を表示  
- 将来のOSカーネル開発のための基盤を提供

## 前提条件

- Rustツールチェーン（2024エディション）
- UEFIターゲットサポート: `rustup target add x86_64-unknown-uefi`
- テスト用QEMU with OVMFファームウェア（オプション）

## クイックスタート

### 1. リポジトリのクローン

```bash
git clone https://github.com/smirror/citros.git
cd citros
```

### 2. プロジェクトのビルド

```bash
# UEFIターゲットの追加（まだインストールされていない場合）
rustup target add x86_64-unknown-uefi

# UEFI用ビルド
cargo build --target x86_64-unknown-uefi --release
```

### 3. QEMUでの実行（オプション）

QEMUとOVMFファームウェアがインストールされている場合：

```bash
# QEMUテストスクリプトの実行
./qemu_run.sh
```

## 開発

### ビルド

```bash
# 標準ビルド
cargo build

# UEFIターゲットビルド
cargo build --target x86_64-unknown-uefi --release

# ビルドせずにコードチェック
cargo check
```

### コード品質

```bash
# コードフォーマット
cargo fmt

# リンター実行
cargo clippy

# テスト実行
cargo test
```

## プロジェクト構造

```
citros/
├── src/
│   └── main.rs          # メインUEFIアプリケーションエントリーポイント
├── Cargo.toml           # プロジェクト設定
├── README.md            # このファイル
├── CLAUDE.md            # AIアシスタント向けガイダンス
├── qemu_run.sh          # QEMUテストスクリプト
└── .github/workflows/   # CI/CDワークフロー
```

## アーキテクチャ

CitrOSは以下の動作をするUEFIアプリケーションとして構成されています：

1. UEFIエントリーポイントに`#[entry]`属性を使用
2. `uefi::helpers::init()`でUEFIサービスを初期化
3. UEFIシンプルテキスト出力プロトコルを使用してテキストを出力
4. 現在は無限ループで動作（将来のカーネル用プレースホルダー）

## 依存関係

- **uefi** (v0.35.0) - UEFI APIバインディングとヘルパー関数を提供

## 今後の開発

計画されている機能と改善：

- メモリ管理とページング
- ハードウェア抽象化レイヤー
- デバイスドライバー
- プロセスとスレッド管理
- ファイルシステムサポート
- グラフィックスとユーザーインターフェース

## 貢献

これは教育プロジェクトです。貢献、提案、学習に関する議論を歓迎します！

## ライセンス

詳細は[LICENSE](LICENSE)を参照してください。

## インスピレーション

このプロジェクトは以下からインスピレーションを受けています：
- [MikanOS](https://github.com/uchan-nos/mikanos) - 教育用OS開発
- 様々なRustベアメタルプログラミングリソース
- UEFI仕様と開発ガイド