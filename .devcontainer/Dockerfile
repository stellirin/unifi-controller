FROM ubuntu:focal

# Options: non-root user.
ARG USERNAME=vscode
ARG USER_UID=1000
ARG USER_GID=$USER_UID

ARG SCRIPT_VER=v0.162.0
ARG SCRIPT_ROOT=https://raw.githubusercontent.com/microsoft/vscode-dev-containers/$SCRIPT_VER/script-library

# Options: common-debian.sh
ARG INSTALL_ZSH=true
ARG UPGRADE_PACKAGES=false
ARG INSTALL_OH_MYS=true
ARG UPDATE_RC=true

# Options: docker-debian.sh
ARG ENABLE_NONROOT_DOCKER=true
ARG SOURCE_SOCKET=/var/run/docker-host.sock
ARG TARGET_SOCKET=/var/run/docker.sock

# Options: java-debian.sh
ARG JAVA_VERSION=8.0.282.j9-adpt
ARG SDKMAN_DIR=/usr/local/sdkman


# Options: github-debian.sh
ARG CLI_VERSION=latest

# Install needed packages and setup non-root user.
RUN apt-get update \
   && apt-get install -y \
   binutils \
   curl \
   xz-utils \
   && bash -c "$(curl -fsSL "${SCRIPT_ROOT}/common-debian.sh")" -- "${INSTALL_ZSH}" "${USERNAME}" "${USER_UID}" "${USER_GID}" "${UPGRADE_PACKAGES}" "${INSTALL_OH_MYS}" \
   && bash -c "$(curl -fsSL "${SCRIPT_ROOT}/docker-debian.sh")" -- "${ENABLE_NONROOT_DOCKER}" "${SOURCE_SOCKET}" "${TARGET_SOCKET}" "${USERNAME}" \
   && bash -c "$(curl -fsSL "${SCRIPT_ROOT}/java-debian.sh")" -- "${JAVA_VERSION}" "${SDKMAN_DIR}" "${USERNAME}" "${UPDATE_RC}" \
   && bash -c "$(curl -fsSL "${SCRIPT_ROOT}/github-debian.sh")" -- "${CLI_VERSION}" \
   && apt-get autoremove -y \
   && apt-get clean -y\
   && rm -rf /var/lib/apt/lists/* \
   && mkdir -p /home/vscode/.vscode-server/extensions \
   && chown -R vscode:vscode /home/vscode/.vscode-server

# Setting the ENTRYPOINT to docker-init.sh will configure non-root access to
# the Docker socket if "overrideCommand": false is set in devcontainer.json.
# The script will also execute CMD if you need to alter startup behaviors.
ENTRYPOINT [ "/usr/local/share/docker-init.sh" ]
CMD [ "sleep", "infinity" ]
