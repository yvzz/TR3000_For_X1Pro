#!/bin/bash

# X1 Pro 设备支持添加脚本
set -x

WORKSPACE="$GITHUB_WORKSPACE"

echo "=== 添加 Oray X1 Pro 支持 ==="

cd "$WORKSPACE/openwrt"

# 1. 创建 files 目录结构（内核编译时会复制到源码树）
echo "创建 files 目录..."
mkdir -p target/linux/mediatek/files/arch/arm64/boot/dts/mediatek

# 2. 复制 DTS 文件到 files 目录
echo "复制 DTS 文件..."
cp "$WORKSPACE/mt7981-oraybox_x1-pro.dts" target/linux/mediatek/files/arch/arm64/boot/dts/mediatek/mt7981_oray_x1_pro.dts

# 3. 修改 DTS 中的 model 和 compatible
echo "修改 DTS 文件..."
sed -i 's/model = "oraybox_x1-pro";/model = "OrayBox X1 Pro";/' target/linux/mediatek/files/arch/arm64/boot/dts/mediatek/mt7981_oray_x1_pro.dts
sed -i 's/compatible = "mediatek,mt7981", "mediatek,mt7981-rfb";/compatible = "oray,x1_pro", "mediatek,mt7981";/' target/linux/mediatek/files/arch/arm64/boot/dts/mediatek/mt7981_oray_x1_pro.dts

# 4. 添加设备定义到 filogic.mk
echo "添加设备定义到 filogic.mk..."
cat >> target/linux/mediatek/image/filogic.mk << 'EOF'

define Device/oray_x1_pro
  DEVICE_VENDOR := Oray
  DEVICE_MODEL := X1 Pro
  DEVICE_DTS := mt7981_oray_x1_pro
  DEVICE_PACKAGES := kmod-usb3 kmod-usb-net-rndis kmod-usb-net-cdc-ether
endef
TARGET_DEVICES += oray_x1_pro
EOF

# 5. 添加网络配置到 base-files
echo "添加网络配置..."
mkdir -p package/base-files/files/etc/board.d

# 创建 02_network
cat > package/base-files/files/etc/board.d/02_network << 'EOF'
#!/bin/sh

. /lib/functions/uci-defaults.sh
board_config_update

case "$(board_name)" in
oray,x1_pro)
	ucidef_set_interfaces_lan_wan "lan1 lan2 lan3 lan4" "wan"
	;;
esac

board_config_flush
exit 0
EOF
chmod +x package/base-files/files/etc/board.d/02_network

# 创建 01_leds
cat > package/base-files/files/etc/board.d/01_leds << 'EOF'
#!/bin/sh

. /lib/functions/uci-defaults.sh
board_config_update

case "$(board_name)" in
oray,x1_pro)
	ucidef_set_led_netdev "wan" "WAN" "blue:wan" "wan"
	;;
esac

board_config_flush
exit 0
EOF
chmod +x package/base-files/files/etc/board.d/01_leds

echo "=== X1 Pro 支持添加完成 ==="
