FROM archlinux:base-20260111.0.480139

RUN pacman -Syu --noconfirm \
    cloc \
    curl \
    gcc \
    git \
    jq \
    lua51 \
    luarocks \
    make \
    neovim \
    which \
    unzip \
    zlib \
    libffi \
    openssl

COPY plenary-patches /plenary-patches

RUN mkdir -p /usr/local/share/nvim/site/pack/plenary/start && \
    cd /usr/local/share/nvim/site/pack/plenary/start && \
    git clone --depth 1 https://github.com/nvim-lua/plenary.nvim.git && \
    git -C plenary.nvim apply /plenary-patches/*.patch

RUN luarocks --lua-version=5.1 install mimetypes && \
    luarocks --lua-version=5.1 install luafilesystem && \
    luarocks --lua-version=5.1 install luasocket && \
    luarocks --lua-version=5.1 install lzlib && \
    luarocks --lua-version=5.1 install pegasus

COPY pegasus-patches /pegasus-patches

RUN git -C /usr/share/lua/5.1/pegasus/ init 2> /dev/null && \
    git -C /usr/share/lua/5.1/pegasus/ apply /pegasus-patches/*.patch
