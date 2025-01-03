SHELL := /bin/bash
OS := $(shell uname -s)
ifeq ($(OS),Darwin)

.PHONY: docker
docker:
	docker build -t gnss_x_linux .

.PHONY: bash
bash:
	docker run --platform linux/arm64 \
		-v .:/home/user/gnss_x_linux \
		--init -it --rm  --privileged gnss_x_linux \
		bash -c "cd /home/user/gnss_x_linux && mkdir -p build && sudo mount -o loop build.img build && sudo chown user:users build && bash"

build.img:
	truncate -s 20G build.img
	docker run --platform linux/arm64 \
		-v .:/home/user/gnss_x_linux \
		--init -it --rm gnss_x_linux \
		bash -c "cd /home/user/gnss_x_linux && mkfs.ext4 build.img"

else

# https://www.st.com/en/embedded-software/stm32mp1dev.html#st-get-software
export SDK_DIR = build/stm32mp1-openstlinux-6.6-yocto-scarthgap-mpu-v24.11.06/sdk
export ENV_SETUP = /home/user/gnss_x_linux/build/sdk/environment-setup-cortexa7t2hf-neon-vfpv4-ostl-linux-gnueabi

.PHONY: sdk
sdk: $(SDK_DIR)
$(SDK_DIR): en.SDK-aarch64-stm32mp1-openstlinux-6.6-yocto-scarthgap-mpu-v24.11.06.tar.gz
	tar xvf $< -C build
	chmod +x $@/st-image-weston-openstlinux-weston-stm32mp1.rootfs-aarch64-toolchain-5.0.3-openstlinux-6.6-yocto-scarthgap-mpu-v24.11.06.sh

.PHONY: sdk-install
sdk-install: $(SDK_DIR)
	cd $(SDK_DIR) && ./st-image-weston-openstlinux-weston-stm32mp1.rootfs-aarch64-toolchain-5.0.3-openstlinux-6.6-yocto-scarthgap-mpu-v24.11.06.sh -y -d /home/user/gnss_x_linux/build/sdk

# https://wiki.st.com/stm32mpu/wiki/Getting_started/STM32MP1_boards/STM32MP157x-DK2/Develop_on_Arm%C2%AE_Cortex%C2%AE-A7/Modify,_rebuild_and_reload_the_Linux%C2%AE_kernel
export SOURCE_DIR = build/stm32mp1-openstlinux-6.6-yocto-scarthgap-mpu-v24.11.06/sources
export LINUX_DIR = $(SOURCE_DIR)/arm-ostl-linux-gnueabi/linux-stm32mp-6.6.48-stm32mp-r1-r0/linux-6.6.48
export OUTPUT_BUILD_DIR = $(LINUX_DIR)/../build
export IMAGE_KERNEL = uImage

.PHONY: sources
sources: $(LINUX_DIR).tar.xz
$(LINUX_DIR).tar.xz: en.SOURCES-stm32mp1-openstlinux-6.6-yocto-scarthgap-mpu-v24.11.06.tar.gz
	tar xvf $< -C build

.PHONY: linux-source
linux-source: $(LINUX_DIR)
$(LINUX_DIR): $(LINUX_DIR).tar.xz
	cd $(SOURCE_DIR)/arm-ostl-linux-gnueabi/linux-stm32mp-6.6.48-stm32mp-r1-r0 && tar xvf linux-6.6.48.tar.xz
	cd $(LINUX_DIR) && for p in `ls -1 ../*.patch`; do patch -p1 < $$p; done	

.PHONY: linux-build-dir
linux-build-dir: $(OUTPUT_BUILD_DIR)
$(OUTPUT_BUILD_DIR): $(LINUX_DIR)
	mkdir -p $(OUTPUT_BUILD_DIR)

.PHONY: linux-defconfig
linux-defconfig: $(OUTPUT_BUILD_DIR)
	source $(ENV_SETUP) && cd $(LINUX_DIR) && make O="$(OUTPUT_BUILD_DIR)" defconfig fragment*.config
	source $(ENV_SETUP) && cd $(LINUX_DIR) && for f in `ls -1 ../fragment*.config`; do scripts/kconfig/merge_config.sh -m -r -O $(OUTPUT_BUILD_DIR) $(OUTPUT_BUILD_DIR)/.config $f; done
	source $(ENV_SETUP) && cd $(LINUX_DIR) && (yes '' || true) | make oldconfig O="$(OUTPUT_BUILD_DIR)"

.PHONY: linux-image
linux-image: $(OUTPUT_BUILD_DIR)
	source $(ENV_SETUP) && cd $(LINUX_DIR) && make $(IMAGE_KERNEL) vmlinux dtbs LOADADDR=0xC2000040 O="$(OUTPUT_BUILD_DIR)"

.PHONY: linux-modules
linux-modules: $(OUTPUT_BUILD_DIR)
	source $(ENV_SETUP) && cd $(LINUX_DIR) && make modules O="${OUTPUT_BUILD_DIR}"

.PHONY: linux-artifacts 
linux-artifacts: $(OUTPUT_BUILD_DIR)
	source $(ENV_SETUP) && cd $(LINUX_DIR) && make INSTALL_MOD_PATH="$(OUTPUT_BUILD_DIR)/install_artifact" modules_install O="$(OUTPUT_BUILD_DIR)"
	source $(ENV_SETUP) && cd $(LINUX_DIR) && mkdir -p $(OUTPUT_BUILD_DIR)/install_artifact/boot/
	source $(ENV_SETUP) && cd $(LINUX_DIR) && cp $(OUTPUT_BUILD_DIR)/arch/$${ARCH}/boot/$(IMAGE_KERNEL) $(OUTPUT_BUILD_DIR)/install_artifact/boot/
	source $(ENV_SETUP) && cd $(LINUX_DIR) && find $(OUTPUT_BUILD_DIR)/arch/$${ARCH}/boot/dts/ -name 'st*.dtb' -exec cp '{}' $(OUTPUT_BUILD_DIR)/install_artifact/boot/ \;

endif