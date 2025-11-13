FROM archlinux:base-20251019.0.436919

RUN pacman -Syu --noconfirm \
    cloc \
    curl \
    git \
    make \
    neovim \
    which

RUN mkdir -p /usr/local/share/nvim/site/pack/plenary/start
RUN git clone --depth 1 https://github.com/nvim-lua/plenary.nvim.git /usr/local/share/nvim/site/pack/plenary/start/plenary.nvim
