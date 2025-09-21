param(
  [string]$PrivateKey,
  [string]$PublicKey
)

function Show-Usage {
    Write-Host "Usage: install.ps1 -PrivateKey <PrivateKey> -PublicKey <PublicKey>"
    Write-Host "Both PrivateKey and PublicKey are required."
    Exit 1
}

# 确保 PublicKey 和 PrivateKey 变量已设置
if (-not $PrivateKey -or -not $PublicKey) {
    Show-Usage
}

# 检查 PublicKey 和 PrivateKey 是否存在
if (-not (Test-Path $PrivateKey) -or -not (Test-Path $PublicKey)) {
    Show-Usage
}

Write-Host "GPG Private key file: $PrivateKey"
Write-Host "GPG Public key file: $PublicKey"

function ReloadEnvPath() {
  param(
    [string[]]$Add = @()
  )
  $machinePath = [System.Environment]::GetEnvironmentVariable("Path", "Machine")
  $userPath = [System.Environment]::GetEnvironmentVariable("Path", "User")

  $Env:Path = ($machinePath + ";" + $userPath + ";" + ($Add -join ";")).TrimEnd(';')
}

Write-Host "Install [chezmoi]..."

$LOCAL_BIN = "$Env:USERPROFILE\.local\bin"
New-Item -ItemType Directory -Path $LOCAL_BIN -Force | Out-Null
ReloadEnvPath -Add @("$LOCAL_BIN")
$chezmoi = Join-Path $LOCAL_BIN "chezmoi.exe"

if (-not (Get-Command "chezmoi" -ErrorAction SilentlyContinue)) {
  # 从官方脚本下载安装 chezmoi 到 $LOCAL_BIN
  Invoke-Expression "& { $(Invoke-RestMethod 'https://get.chezmoi.io/ps1') } -b '$LOCAL_BIN'"

  # 更新回话 PATH
  $Env:Path = "$LOCAL_BIN;$Env:Path"

  # 更新用户 PATH
  $path0 = @($LOCAL_BIN)
  $path1 = [System.Environment]::GetEnvironmentVariable("Path", "User") -split ";"
  $path2 = (($path0 + $path1) | Sort-Object -Unique) -join ";"
  [System.Environment]::SetEnvironmentVariable("Path", $path2, "User")

  Write-Host "chezmoi: installed successfully."
}
else {
  Write-Host "chezmoi: already installed. try upgrade..."
  & $chezmoi upgrade
}

Write-Host "chezmoi: $(& $chezmoi --version)"

################################################
$apps = @(
  "Microsoft.WindowsTerminal",
  "Microsoft.PowerShell",
  "Git.Git",
  "GnuPG.GnuPG",
  "gopass.gopass"
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
$PASSWORD_STORE="$Env:USERPROFILE\.password-store"
if (-not (Test-Path $PASSWORD_STORE)) {
    git clone https://github.com/garryshield/.password-store.git $PASSWORD_STORE
    gopass show xxx
}