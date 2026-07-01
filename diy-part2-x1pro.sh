

# Modify default IP
#sed -i 's/192.168.1.1/192.168.50.5/g' package/base-files/files/bin/config_generate

# Modify default theme
#sed -i 's/luci-theme-bootstrap/luci-theme-argon/g' feeds/luci/collections/luci/Makefile

# Modify hostname
#sed -i 's/OpenWrt/P3TERX-Router/g' package/base-files/files/bin/config_generate

# 修复 Rust 编译失败：强制关闭 download-ci-llvm
sed -i 's/$(TARGET_CONFIGURE_ARGS)/--set llvm.download-ci-llvm=false \\\n\t$(TARGET_CONFIGURE_ARGS)/' feeds/packages/lang/rust/Makefile
