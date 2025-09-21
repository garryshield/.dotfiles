#!/usr/bin/env bash
set -euo pipefail

usage() {
    echo "Usage: install.sh --private-key <PrivateKey> --public-key <PublicKey>"
    echo "Both PrivateKey and PublicKey are required."
    exit 1
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --private-key)
            PrivateKey="$2"
            shift 2
            ;;
        --public-key)
            PublicKey="$2"
            shift 2
            ;;
        *)
            usage
            ;;
    esac
done

# 确保 PublicKey 和 PrivateKey 变量已设置
if [ -z "${PublicKey+x}" ] || [ -z "${PrivateKey+x}" ]; then
    usage
fi

# 检查 PublicKey 和 PrivateKey 是否存在
if [[ ! -e "$PublicKey" || ! -e "$PrivateKey" ]]; then
    usage
fi

echo "GPG Private key file: $PrivateKey"
echo "GPG Public key file: $PublicKey"

command_exists() { command -v "$1" >/dev/null 2>&1; }

echo "Install [chezmoi]..."

LOCAL_BIN=${LOCAL_BIN:-$HOME/.local/bin}
mkdir -p $LOCAL_BIN
export PATH="$LOCAL_BIN:$PATH"
chezmoi="$LOCAL_BIN/chezmoi"

if [ ! "$(command -v chezmoi)" ]; then
  if [ "$(command -v curl)" ]; then
    sh -c "$(curl -fsLS https://get.chezmoi.io)" -- -b "$LOCAL_BIN" -t "latest"
  elif [ "$(command -v wget)" ]; then
    sh -c "$(wget -qO- https://get.chezmoi.io)" -- -b "$LOCAL_BIN" -t "latest"
  else
    echo "To install chezmoi, you must have curl or wget installed." >&2
    exit 1
  fi

  echo "chezmoi: installed successfully."
else
  echo "chezmoi: already installed. try upgrade..."
  "${chezmoi}" upgrade
fi

echo "chezmoi: $(${chezmoi} --version)"

################################################
if [[ "$(uname)" == "Linux" ]]; then
  sudo apt-get install git gnupg2
  # gopass
  _GH_FIL="https://github.com/gopasspw/gopass/releases/download/v1.15.18/gopass-1.15.18-linux-amd64.tar.gz"
  curl -L -o gopass.tar.gz $_GH_FIL
  tar xzf gopass.tar.gz gopass
  install -Dm 755 gopass -T $LOCAL_BIN/gopass
  rm gopass gopass.tar.gz
  gopass --version
elif [[ "$(uname)" == "Darwin" ]]; then
  # homebrew
  if ! command_exists brew; then
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  else
    brew update
  fi
  brew install git gnupg gopass
fi

################################################
# 导入 GPG 密钥
gpg --import $PublicKey
gpg --import $PrivateKey

# 列出 GPG 密钥
gpg --list-keys --keyid-format long
gpg --list-secret-keys --keyid-format long

################################################
# 克隆密码存储库
PASSWORD_STORE="$HOME/.password-store"
if [ ! -d "$PASSWORD_STORE" ]; then
  git clone https://github.com/garryshield/.password-store.git "$PASSWORD_STORE"
  gopass show xxx
fi