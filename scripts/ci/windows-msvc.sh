#!/usr/bin/env bash
# Flutter 3.19's C++ client wrapper (encodable_value.h) fails to compile with
# MSVC 14.40+ (error C2665 in firebase_auth). Install the 14.38 toolset and make
# CMake's Visual Studio generator use it.
set -euo pipefail
version=14.38
component="Microsoft.VisualStudio.Component.VC.$version.17.8.x86.x64"
vswhere="/c/Program Files (x86)/Microsoft Visual Studio/Installer/vswhere.exe"
install_path="$("$vswhere" -latest -property installationPath)"
if ! ls "$install_path/VC/Tools/MSVC" | grep -q "^$version"; then
  "/c/Program Files (x86)/Microsoft Visual Studio/Installer/setup.exe" modify \
    --installPath "$install_path" --add "$component" --quiet --norestart --nocache
fi
ls "$install_path/VC/Tools/MSVC"
echo "CMAKE_GENERATOR_TOOLSET=v143,version=$version" >> "$GITHUB_ENV"
