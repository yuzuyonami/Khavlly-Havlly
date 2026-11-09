:<<"::CMDLITERAL"
@ECHO OFF
SETLOCAL
set "REPO=yuzuyonami/Khavlly-Havlly"
set "VER=%~1"
if "%VER%"=="" for /f "delims=" %%i in ('powershell -NoProfile -Command "$r=@(Invoke-RestMethod https://api.github.com/repos/%REPO%/releases?per_page=1); $r[0].tag_name"') do set "VER=%%i"
if "%VER%"=="" (
  echo Gagal menentukan versi terbaru.
  EXIT /B 1
)
set "FILE=havly-%VER%-windows-x86_64.zip"
set "URL=https://github.com/%REPO%/releases/download/%VER%/%FILE%"
set "DIR=%USERPROFILE%\.havly\bin"
if not exist "%DIR%" mkdir "%DIR%"
echo Mengunduh Havly %VER%...
curl.exe -fsSL "%URL%" -o "%TEMP%\%FILE%"
if errorlevel 1 (
  echo Gagal mengunduh. Cek koneksi atau versi.
  EXIT /B 1
)
powershell -NoProfile -Command "Expand-Archive -Force -Path '%TEMP%\%FILE%' -DestinationPath '%DIR%'"
del "%TEMP%\%FILE%"
powershell -NoProfile -Command "$p=[Environment]::GetEnvironmentVariable('Path','User'); if($p -notlike '*%DIR%*'){[Environment]::SetEnvironmentVariable('Path',$p+';%DIR%','User')}"
echo Selesai. Buka terminal baru lalu jalankan: havly
EXIT /B 0
::CMDLITERAL

# ---------- bagian Linux / macOS ----------
set -eu
REPO="yuzuyonami/Khavlly-Havlly"
VER="${1:-latest}"

os="$(uname -s)"; arch="$(uname -m)"
case "$os-$arch" in
  Linux-x86_64|Linux-amd64)   name="linux-x86_64" ;;
  Darwin-arm64|Darwin-aarch64) name="macos-arm64" ;;
  Darwin-x86_64)              name="macos-x86_64" ;;
  *) echo "Platform tidak didukung: $os $arch" >&2; exit 1 ;;
esac

if [ "$VER" = "latest" ]; then
  VER="$(curl -fsSL "https://api.github.com/repos/$REPO/releases?per_page=1" | grep -m1 '"tag_name"' | cut -d'"' -f4)"
fi
[ -n "$VER" ] || { echo "Gagal menentukan versi terbaru." >&2; exit 1; }

file="havly-${VER}-${name}.tar.gz"
url="https://github.com/$REPO/releases/download/$VER/$file"

dir="$HOME/.havly/bin"
mkdir -p "$dir"
echo "Mengunduh Havly $VER ($name)..."
tmp="$(mktemp)"
curl -fsSL "$url" -o "$tmp"
tar -xzf "$tmp" -C "$dir"
rm -f "$tmp"
chmod +x "$dir/havly"

case ":$PATH:" in
  *":$dir:"*) ;;
  *)
    for rc in "$HOME/.profile" "$HOME/.bashrc" "$HOME/.zshrc"; do
      [ -f "$rc" ] && echo "export PATH=\"$dir:\$PATH\"" >> "$rc"
    done ;;
esac
echo "Selesai. Buka terminal baru lalu jalankan: havly"
exit 0
