FROM --platform=linux/arm64 ubuntu:22.04
ARG DEBIAN_FRONTEND=noninteractive
RUN apt update && apt upgrade -y && apt install -y --no-install-recommends --allow-unauthenticated \
    sudo git gawk wget git git-lfs diffstat unzip texinfo chrpath socat cpio python3 python3-pip python3-pexpect \
    xz-utils debianutils iputils-ping python3-git python3-jinja2 libegl1-mesa libsdl1.2-dev pylint xterm bsdmainutils \
    libssl-dev libgmp-dev libmpc-dev lz4 zstd
RUN apt update && apt upgrade -y && apt install -y --no-install-recommends --allow-unauthenticated \
    make file patch gcc flex bison bc kmod

# create user "user" with password "pass"
RUN useradd --create-home --shell /bin/bash --user-group --groups adm,sudo user
RUN sh -c 'echo "user:pass" | chpasswd'
RUN echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

# build
RUN mkdir /home/user/gnss_x_linux
RUN chown -R user:users /home/user/gnss_x_linux/
RUN RUN echo "user:user" | chpasswd
USER user
WORKDIR /home/user/gnss_x_linux