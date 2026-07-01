#!/bin/bash

# X1 Pro 设备支持添加脚本
set -x

WORKSPACE="$GITHUB_WORKSPACE"

echo "=== 添加 Oray X1 Pro 支持 ==="

cd "$WORKSPACE/openwrt"

# 1. 复制 DTS 文件（文件名用下划线，内核不支持连字符）
echo "复制 DTS 文件..."
cp "$WORKSPACE/mt7981-oraybox_x1-pro.dts" target/linux/mediatek/dts/mt7981_oray_x1_pro.dts

# 2. 修改 DTS 中的 model 和 compatible
echo "修改 DTS 文件..."
sed -i 's/model = "Oray X1 Pro";/model = "OrayBox X1 Pro";/' target/linux/mediatek/dts/mt7981_oray_x1_pro.dts
sed -i 's/compatible = "oray,x1-pro";/compatible = "oray,x1_pro";/' target/linux/mediatek/dts/mt7981_oray_x1_pro.dts

# 3. 添加设备定义到 filogic.mk（DEVICE_DTS 用下划线）
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

# 4. 添加网络配置
echo "添加网络配置..."
mkdir -p package/base-files/files/etc/board.d
grep -q "oray,x1_pro" package/base-files/files/etc/board.d/02_network 2>/dev/null || \
cat >> package/base-files/files/etc/board.d/02_network << 'EOF'

oray,x1_pro)
	ucidef_set_interfaces_lan_wan "lan1 lan2 lan3 lan4" "wan"
	;;
EOF

# 5. 添加 LED 配置
echo "添加 LED 配置..."
grep -q "oray,x1_pro" package/base-files/files/etc/board.d/01_leds 2>/dev/null || \
cat >> package/base-files/files/etc/board.d/01_leds << 'EOF'

oray,x1_pro)
	ucidef_set_led_netdev "wan" "WAN" "blue:wan" "wan"
	;;
EOF

echo "=== X1 Pro 支持添加完成 ==="
