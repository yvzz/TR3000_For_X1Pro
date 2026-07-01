#!/bin/bash

# X1 Pro 设备支持添加脚本
set -x

WORKSPACE="$GITHUB_WORKSPACE"

echo "=== 添加 Oray X1 Pro 支持 ==="

cd "$WORKSPACE/openwrt"

# 1. 复制 DTS 文件
echo "复制 DTS 文件..."
cp "$WORKSPACE/mt7981-oraybox_x1-pro.dts" target/linux/mediatek/dts/mt7981_oray_x1-pro.dts

# 2. 重写 DTS 文件，添加标准分区定义（替换 mtd-layout 为标准 partitions）
echo "修改 DTS 文件..."
cat > target/linux/mediatek/dts/mt7981_oray_x1-pro.dts << 'EOF'
// SPDX-License-Identifier: GPL-2.0-or-later

/dts-v1/;
#include "mt7981.dtsi"
#include <dt-bindings/gpio/gpio.h>
#include <dt-bindings/input/linux-event-codes.h>

/ {
	#address-cells = <1>;
	#size-cells = <1>;
	model = "Oray X1 Pro";
	compatible = "oray,x1-pro";

	chosen {
		stdout-path = &uart0;
		tick-timer = &timer0;
	};

	memory@40000000 {
		device_type = "memory";
		reg = <0x40000000 0x20000000>;
	};

	gpio-keys {
		compatible = "gpio-keys";

		button-reset {
			label = "reset";
			linux,code = <KEY_RESTART>;
			gpios = <&pio 1 GPIO_ACTIVE_LOW>;
		};

		button-mode {
			label = "mode";
			linux,code = <EV_SW>;
			linux,input-type = <BTN_0>;
			gpios = <&pio 0 GPIO_ACTIVE_HIGH>;
			debounce-interval = <60>;
		};
	};

	gpio-leds {
		compatible = "gpio-leds";

		led_status: led-0 {
			label = "red:power";
			gpios = <&pio 11 GPIO_ACTIVE_LOW>;
		};

		led-1 {
			label = "white:status";
			gpios = <&pio 10 GPIO_ACTIVE_LOW>;
		};
	};
};

&eth {
	status = "okay";
	mediatek,gmac-id = <1>;
	phy-mode = "gmii";
	phy-handle = <&phy0>;

	mdio {
		phy0: ethernet-phy@0 {
			compatible = "ethernet-phy-id03a2.9461";
			reg = <0x0>;
			phy-mode = "gmii";
		};
	};
};

&pio {
	spi_flash_pins: spi0-pins-func-1 {
		mux {
			function = "flash";
			groups = "spi0", "spi0_wp_hold";
		};

		conf-pu {
			pins = "SPI0_CS", "SPI0_HOLD", "SPI0_WP";
			drive-strength = <MTK_DRIVE_4mA>;
			bias-pull-up = <MTK_PUPD_SET_R1R0_11>;
		};

		conf-pd {
			pins = "SPI0_CLK", "SPI0_MOSI", "SPI0_MISO";
			drive-strength = <MTK_DRIVE_4mA>;
			bias-pull-down = <MTK_PUPD_SET_R1R0_11>;
		};
	};
};

&spi0 {
	#address-cells = <1>;
	#size-cells = <0>;
	pinctrl-names = "default";
	pinctrl-0 = <&spi_flash_pins>;
	status = "okay";
	must_tx;
	enhance_timing;
	dma_ext;
	ipm_design;
	support_quad;
	tick_dly = <2>;
	sample_sel = <0>;

	spi_nand@0 {
		compatible = "spi-nand";
		reg = <0>;
		spi-max-frequency = <52000000>;

		partitions {
			compatible = "fixed-partitions";
			#address-cells = <1>;
			#size-cells = <1>;

			partition@0 {
				label = "bl2";
				reg = <0x0 0x100000>;
				read-only;
			};

			partition@100000 {
				label = "u-boot-env";
				reg = <0x100000 0x80000>;
			};

			partition@180000 {
				label = "factory";
				reg = <0x180000 0x200000>;
				read-only;
			};

			partition@380000 {
				label = "fip";
				reg = <0x380000 0x200000>;
				read-only;
			};

			partition@580000 {
				label = "bdinfo";
				reg = <0x580000 0x80000>;
			};

			partition@600000 {
				label = "kpanic";
				reg = <0x600000 0x200000>;
			};

			partition@800000 {
				label = "ubi";
				reg = <0x800000 0x7000000>;
			};
		};
	};
};

&uart0 {
	status = "okay";
};

&usb3 {
	status = "okay";
};
EOF

# 3. 添加设备定义到 filogic.mk
echo "添加设备定义到 filogic.mk..."
cat >> target/linux/mediatek/image/filogic.mk << 'EOF'

define Device/oray_x1-pro
  DEVICE_VENDOR := Oray
  DEVICE_MODEL := X1 Pro
  DEVICE_DTS := mt7981_oray_x1-pro
  DEVICE_PACKAGES := kmod-usb3 kmod-usb-net-rndis kmod-usb-net-cdc-ether
endef
TARGET_DEVICES += oray_x1-pro
EOF

# 4. 添加网络配置
echo "添加网络配置..."
mkdir -p base-files/etc/board.d
grep -q "oray,x1-pro" base-files/etc/board.d/02_network || \
cat >> base-files/etc/board.d/02_network << 'EOF'

oray,x1-pro)
	ucidef_set_interfaces_lan_wan "lan1 lan2 lan3 lan4" "wan"
	;;
EOF

# 5. 添加 LED 配置
echo "添加 LED 配置..."
grep -q "oray,x1-pro" base-files/etc/board.d/01_leds || \
cat >> base-files/etc/board.d/01_leds << 'EOF'

oray,x1-pro)
	ucidef_set_led_netdev "wan" "WAN" "blue:wan" "wan"
	;;
EOF

echo "=== X1 Pro 支持添加完成 ==="
