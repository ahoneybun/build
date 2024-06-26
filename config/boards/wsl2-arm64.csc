# aarch64 Windows Subsystem for Linux 2 (Hyper-V)
declare -g BOARD_NAME="WSL2 arm64"
declare -g BOARDFAMILY="uefi-arm64"
declare -g BOARD_MAINTAINER="rpardini"
declare -g KERNEL_TARGET="current,edge"

# Source vendor-specific configuration (common hooks for wsl2 - changes LINUXFAMILY etc)
source "${SRC}/config/sources/vendors/microsoft/wsl2.hooks.sh"
