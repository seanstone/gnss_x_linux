.PHONY: docker
docker:
	docker build -t gnss_x_linux .

.PHONY: bash
bash:
	docker run --platform linux/arm64 \
		-v .:/home/user/gnss_x_linux \
		-i -t gnss_x_linux \
		bash

stm32mp1-openstlinux-6.6-yocto-scarthgap-mpu-v24.11.06/sdk: en.SDK-aarch64-stm32mp1-openstlinux-6.6-yocto-scarthgap-mpu-v24.11.06.tar.gz
	tar xvf $<
	chmod +x $@/st-image-weston-openstlinux-weston-stm32mp1.rootfs-aarch64-toolchain-5.0.3-openstlinux-6.6-yocto-scarthgap-mpu-v24.11.06.sh

# Install SDK to /home/user/gnss_x_linux/sdk