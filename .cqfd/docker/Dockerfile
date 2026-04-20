FROM archlinux:base-20260111.0.480139

# On Arch Linux /bin is a symlink to usr/bin. Docker cannot bind-mount a file
# into a path that resolves through a symlinked directory, which breaks cqfd's
# entrypoint injection. Convert /bin into a real directory.
RUN cp -a /usr/bin/. /tmp/bin.real/ && rm /bin && mv /tmp/bin.real /bin

RUN pacman -Syu --noconfirm \
    cloc \
    curl \
    git \
    jq \
    make \
    neovim \
    sudo \
    which

COPY plenary-patches /plenary-patches

RUN mkdir -p /usr/local/share/nvim/site/pack/plenary/start && \
    cd /usr/local/share/nvim/site/pack/plenary/start && \
    git clone --depth 1 https://github.com/nvim-lua/plenary.nvim.git && \
    git -C plenary.nvim apply /plenary-patches/*.patch
