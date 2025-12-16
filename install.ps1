param(
  [string]$PublicKey,
  [string]$PrivateKey,
  [string]$PasswordStore
)

function Show-Usage {
    Write-Host "Usage: install.ps1 -PublicKey <PublicKey> -PrivateKey <PrivateKey> -PasswordStore <PasswordStore>"
    Write-Host "Both PublicKey and PrivateKey and PasswordStore are required."
    Exit 1
}

# 确保 PublicKey 和 PrivateKey 变量已设置
if (-not $PublicKey -or -not $PrivateKey -or -not $PasswordStore) {
    Show-Usage
}

# 检查 PublicKey 和 PrivateKey 是否存在
if (-not (Test-Path $PublicKey) -or -not (Test-Path $PrivateKey)) {
    Show-Usage
}

Write-Host "GPG Public key file: $PublicKey"
Write-Host "GPG Private key file: $PrivateKey"
Write-Host "Password Store: $PasswordStore"

function ReloadEnvPath() {
  param(
    [string[]]$Add = @()
  )
  $machinePath = [System.Environment]::GetEnvironmentVariable("Path", "Machine")
  $userPath = [System.Environment]::GetEnvironmentVariable("Path", "User")

  $Env:Path = ($machinePath + ";" + $userPath + ";" + ($Add -join ";")).TrimEnd(';')
}

$LOCAL_BIN = "$Env:USERPROFILE\.local\bin"
New-Item -ItemType Directory -Path $LOCAL_BIN -Force | Out-Null
ReloadEnvPath -Add @("$LOCAL_BIN")
$chezmoi = Join-Path $LOCAL_BIN "chezmoi.exe"

################################################
if (-not (Get-Command "chezmoi" -ErrorAction SilentlyContinue)) {
  Write-Host "install chezmoi."
  # 从官方脚本下载安装 chezmoi 到 $LOCAL_BIN
  Invoke-Expression "& { $(Invoke-RestMethod 'https://get.chezmoi.io/ps1') } -b '$LOCAL_BIN'"

  # 更新回话 PATH
  $Env:Path = "$LOCAL_BIN;$Env:Path"
  # 更新用户 PATH
  $path0 = @($LOCAL_BIN)
  $path1 = [System.Environment]::GetEnvironmentVariable("Path", "User") -split ";"
  $path2 = (($path0 + $path1) | Sort-Object -Unique) -join ";"
  [System.Environment]::SetEnvironmentVariable("Path", $path2, "User")
}
else {
  Write-Host "upgrade chezmoi"
  & $chezmoi upgrade
}
Write-Host "chezmoi: $(& $chezmoi --version)"

################################################
$apps = @(
  "Git.Git",
  "GnuPG.GnuPG",
  "gopass.gopass",
  "Microsoft.WindowsTerminal",
  "Microsoft.PowerShell"
)
foreach ($itm in $apps) {
  Write-Host "Install App [$itm]..."
  winget install `
    --id="$itm" `
    --exact `
    --nowarn `
    --authentication-mode=silent `
    --disable-interactivity `
    --accept-source-agreements `
    --accept-package-agreements `
    --uninstall-previous
}

ReloadEnvPath -Add @("$Env:USERPROFILE\AppData\Local\gopass")

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
$PASSWORD_STORE="$Env:USERPROFILE\.password-store"
if (-not (Test-Path $PASSWORD_STORE)) {
  git clone $PasswordStore $PASSWORD_STORE
}
if (Test-Path $PASSWORD_STORE) {
  gopass config mounts.path "$PASSWORD_STORE"
  gopass --nosync ls
}
