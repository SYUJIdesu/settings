#!/bin/bash

# --- 1. Homebrew本体のインストール ---
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# --- 2. パスを通す設定（~/.zprofile への書き込み） ---
# Apple Silicon (M1/M2/M3/M4) Mac用のパス設定です
# インストール済みか確認してから、設定ファイルに1回だけ追記します
if [ -f /opt/homebrew/bin/brew ]; then
    (echo; echo 'eval "$(/opt/homebrew/bin/brew shellenv)"') >> ~/.zprofile
    eval "$(/opt/homebrew/bin/brew shellenv)"
    echo "Success: Homebrew path has been added to ~/.zprofile"
else
    echo "Error: Homebrew installation might have failed."
fi
