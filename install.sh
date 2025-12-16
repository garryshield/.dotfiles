#!/usr/bin/env bash
set -euo pipefail

command_exists() {
	command -v "$@" >/dev/null 2>&1
}

is_linux() {
	[[ "$(uname -s)" == "Linux" ]]
}

is-debian() {
	[[ -f /etc/os-release ]] && grep -qi '^ID=debian' /etc/os-release
}

is-darwin() {
	[[ "$(uname -s)" == "Darwin" ]]
}

if ! is-debian && ! is-darwin; then
	echo "Only support Debian and Macos"
	exit 1
fi

usage() {
	echo "Usage: install.sh --public-key <PublicKey> --private-key <PrivateKey> --password-store <PasswordStore>"
	echo "Both PublicKey and PrivateKey and PasswordStore are required"
	exit 1
}

while [[ $# -gt 0 ]]; do
	case "$1" in
	--public-key)
		PublicKey="$2"
		shift 2
		;;
	--private-key)
		PrivateKey="$2"
		shift 2
		;;
	--password-store)
		PasswordStore="$2"
		shift 2
		;;
	*)
		usage
		;;
	esac
done

# 确保 PublicKey 和 PrivateKey 变量已设置
if [ -z "${PublicKey+x}" ] || [ -z "${PrivateKey+x}" ] || [ -z "${PasswordStore+x}" ]; then
	usage
fi

# 检查 PublicKey 和 PrivateKey 是否存在
if [[ ! -e "$PublicKey" || ! -e "$PrivateKey" ]]; then
	usage
fi

echo "GPG Public key file: $PublicKey"
echo "GPG Private key file: $PrivateKey"
echo "Password Store: $PasswordStore"

################################################
if is-debian; then
	if [ -f /etc/apt/sources.list ]; then
		sudo sed -i 's/deb.debian.org/mirrors.ustc.edu.cn/g' /etc/apt/sources.list
	fi
	if [ -f /etc/apt/sources.list.d/debian.sources ]; then
		sudo sed -i 's/deb.debian.org/mirrors.ustc.edu.cn/g' /etc/apt/sources.list.d/debian.sources
	fi
	sudo apt-get update
	sudo apt-get install -y curl wget
fi

LOCAL_BIN=${LOCAL_BIN:-$HOME/.local/bin}
mkdir -p $LOCAL_BIN
export PATH="$LOCAL_BIN:$PATH"
chezmoi="$LOCAL_BIN/chezmoi"

################################################
if ! command_exists chezmoi; then
	echo "install chezmoi"
	sh -c "$(curl -fsLS https://get.chezmoi.io)" -- -b "$LOCAL_BIN" -t "latest"
else
	echo "upgrade chezmoi"
	"${chezmoi}" upgrade
fi
echo "chezmoi: $(${chezmoi} --version)"

################################################
if is-debian; then
	sudo apt-get install -y git gnupg
	# gopass
	_GH_FIL="https://github.com/gopasspw/gopass/releases/download/v1.16.1/gopass-1.16.1-linux-amd64.tar.gz"
	curl -L -o gopass.tar.gz $_GH_FIL
	tar xzf gopass.tar.gz gopass
	install -Dm 755 gopass -T $LOCAL_BIN/gopass
	rm gopass gopass.tar.gz
	gopass --version
fi

if is-darwin; then
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
git config --global credential.helper store
PASSWORD_STORE="$HOME/.password-store"
if [ ! -d "$PASSWORD_STORE" ]; then
	git clone "$PasswordStore" "$PASSWORD_STORE"
fi
if [ -d "$PASSWORD_STORE" ]; then
	gopass config mounts.path "$PASSWORD_STORE"
	gopass --nosync ls
fi
