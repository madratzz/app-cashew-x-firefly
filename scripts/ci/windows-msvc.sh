#!/usr/bin/env bash
# Flutter 3.19's C++ client wrapper (encodable_value.h) fails to compile with
# MSVC 14.40+ (error C2665 in firebase_auth). Install the 14.38 toolset and make
# CMake's Visual Studio generator use it. flutter_secure_storage_windows also
# needs that toolset's ATL headers.
set -euo pipefail
version=14.38
components=(
  "Microsoft.VisualStudio.Component.VC.$version.17.8.x86.x64"
  "Microsoft.VisualStudio.Component.VC.$version.17.8.ATL"
)
vswhere="/c/Program Files (x86)/Microsoft Visual Studio/Installer/vswhere.exe"
install_path="$("$vswhere" -latest -property installationPath)"
tools="$(ls "$install_path/VC/Tools/MSVC" | grep "^$version" | head -n1 || true)"
if [[ -z "$tools" || ! -f "$install_path/VC/Tools/MSVC/$tools/atlmfc/include/atlstr.h" ]]; then
  "/c/Program Files (x86)/Microsoft Visual Studio/Installer/setup.exe" modify \
    --installPath "$install_path" $(printf -- "--add %s " "${components[@]}") --quiet --norestart --nocache
fi
ls "$install_path/VC/Tools/MSVC"
echo "CMAKE_GENERATOR=Visual Studio 17 2022" >> "$GITHUB_ENV"
echo "CMAKE_GENERATOR_TOOLSET=v143,version=$version" >> "$GITHUB_ENV"
