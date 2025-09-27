## Download

Download to `~/.dotfiles`

Or use smb-mapping with windows
```ps1
New-SmbMapping -LocalPath "X:" -RemotePath "\\xxx\.dotfiles" -UserName "yyy" -Password "zzz"
Get-SmbMapping
```

Anyway, the following doc suppose your dotfiles directory is `~/.dotfiles`

## Install

- install chezmoi
- install git gnupg gopass
- import gpg public-key and private-key
- clone password-store

linux and darwin
```bash
rm -rf ~/.config/chezmoi
rm -rf ~/.local/bin/chezmoi

install.sh \
  --public-key xxxxxx.pub.asc \
  --private-key xxxxxx.prv.asc \
  --password-store https://github.com/garryshield/.password-store.git
```

windows
```ps1
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope CurrentUser

Remove-Item -Recurse -Force $Env:USERPROFILE\.config\chezmoi -ErrorAction SilentlyContinue
Remove-Item -Force $Env:USERPROFILE\.local\bin\chezmoi.exe -ErrorAction SilentlyContinue
install.ps1 \
  -PublicKey xxxxxx.pub.asc \
  -PrivateKey xxxxxx.prv.asc \
  -PasswordStore https://github.com/garryshield/.password-store.git
```

## Init Chezmoi

```
chezmoi init --source ~/.dotfiles
```

## Apply Chezmoi

```
chezmoi apply
```

## Windows
Microsoft.WindowsTerminal
```bash
~\AppData\Local\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json
```

PROFILE
```ps1
# pwsh
$PROFILE | Select-Object *
AllUsersAllHosts       : C:\Program Files\PowerShell\7\profile.ps1
AllUsersCurrentHost    : C:\Program Files\PowerShell\7\Microsoft.PowerShell_profile.ps1
CurrentUserAllHosts    : ~\Documents\PowerShell\profile.ps1
CurrentUserCurrentHost : ~\Documents\PowerShell\Microsoft.PowerShell_profile.ps1
Length                 : 68

# powershell
$PROFILE | Select-Object *
AllUsersAllHosts       : C:\Windows\System32\WindowsPowerShell\v1.0\profile.ps1
AllUsersCurrentHost    : C:\Windows\System32\WindowsPowerShell\v1.0\Microsoft.PowerShell_profile.ps1
CurrentUserAllHosts    : ~\Documents\WindowsPowerShell\profile.ps1
CurrentUserCurrentHost : ~\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1
Length                 : 75
```

PSModulePath
```ps1
# pwsh
$Env:PSModulePath -split ';'
~\Documents\PowerShell\Modules
C:\Program Files\PowerShell\Modules
c:\program files\powershell\7\Modules
C:\Program Files\WindowsPowerShell\Modules
C:\WINDOWS\system32\WindowsPowerShell\v1.0\Modules

# powershell
$Env:PSModulePath -split ';'
~\Documents\WindowsPowerShell\Modules
C:\Program Files\WindowsPowerShell\Modules
C:\WINDOWS\system32\WindowsPowerShell\v1.0\Modules
```

Env
```ps1
Get-ChildItem Env:
```

WSL
```ps1
# 计算机\HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Lxss
Get-Item `HKCU:\Software\Microsoft\Windows\CurrentVersion\Lxss`
```




## SSH
```bash
ssh-keygen -t ed25519 -q -N "" -C "test" -f ./id_ed25519
ssh-keygen -t rsa -b 4096 -q -N "" -C "test" -f ./id_rsa
```

```bash
# 密钥列表
lst=(
  'github'
  'pve'
  'openwrt'
  'wsl/garry'
  'wsl/root'
)
keys_dir="${HOME}/.ssh/keys"
dots_dir="$(chezmoi source-path)/private_dot_ssh/keys"

for itm in "${lst[@]}"; do
  # 创建目标目录
  mkdir -p "$keys_dir/$itm"
  mkdir -p $dots_dir/$itm

  # 根据项目选择密钥类型
  if [[ "$itm" == "openwrt" ]]; then
    key_type="rsa"
    key_bits=4096          # RSA 需要指定长度
    private_key_name="id_rsa"
    public_key_name="id_rsa.pub"
  else
    key_type="ed25519"
    key_bits=""            # ed25519 不需要指定长度
    private_key_name="id_ed25519"
    public_key_name="id_ed25519.pub"
  fi

  public_key_file="$keys_dir/$itm/$public_key_name"
  private_key_file="$keys_dir/$itm/$private_key_name"

  # 如果密钥不存在就生成
  if [[ ! -f "$private_key_file" ]]; then
    if [[ -n "$key_bits" ]]; then
      ssh-keygen -t "$key_type" -b "$key_bits" -q -N "" -C "$itm" -f "$private_key_file"
    else
      ssh-keygen -t "$key_type" -q -N "" -C "$itm" -f "$private_key_file"
    fi
    echo "Generated $key_type key for $itm"
  else
    echo "Key for $itm already exists, skipping."
  fi

  cat $public_key_file | pass insert -m -f ssh/$itm/$public_key_name
  cat $private_key_file | pass insert -m -f ssh/$itm/$private_key_name

  echo "{{ gopassRaw \"ssh/$itm/$public_key_name\" }}" > $dots_dir/$itm/$public_key_name.tmpl
  echo "{{ gopassRaw \"ssh/$itm/$private_key_name\" }}" > $dots_dir/$itm/private_$private_key_name.tmpl
done
```

```bash
ssh-copy-id -f -i id_ed25519.pub xxx@yyy:zzz
```