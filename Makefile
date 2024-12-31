.PHONY: docker
docker:
	docker build -t gnss_x_linux .

.PHONY: bash
bash:
	docker run --platform linux/arm64 \
		-v .:/home/user/gnss_x_linux \
		-i -t gnss_x_linux \
		bash

# https://www.st.com/en/embedded-software/stm32mp1dev.html#st-get-software

stm32mp1-openstlinux-6.6-yocto-scarthgap-mpu-v24.11.06/sdk: en.SDK-aarch64-stm32mp1-openstlinux-6.6-yocto-scarthgap-mpu-v24.11.06.tar.gz
	tar xvf $<
	chmod +x $@/st-image-weston-openstlinux-weston-stm32mp1.rootfs-aarch64-toolchain-5.0.3-openstlinux-6.6-yocto-scarthgap-mpu-v24.11.06.sh
# Install SDK to /home/user/gnss_x_linux/sdk

stm32mp1-openstlinux-6.6-yocto-scarthgap-mpu-v24.11.06/sources: en.SOURCES-stm32mp1-openstlinux-6.6-yocto-scarthgap-mpu-v24.11.06.tar.gz
	tar xvf $<
# https://wiki.st.com/stm32mpu/wiki/Getting_started/STM32MP1_boards/STM32MP157x-DK2/Develop_on_Arm%C2%AE_Cortex%C2%AE-A7/Modify,_rebuild_and_reload_the_Linux%C2%AE_kernel