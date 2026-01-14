FROM archlinux:base-20260111.0.480139

RUN pacman -Syu --noconfirm \
    cloc \
    curl \
    gcc \
    git \
    jq \
    luarocks \
    make \
    neovim \
    which \
    unzip \
    zlib \
    libffi \
    openssl

# Install Lua 5.1 development headers
RUN pacman -Syu --noconfirm lua51

# Symlink lua5.1 binary if missing
RUN [ -f /usr/bin/lua5.1 ] || ln -s /usr/bin/lua /usr/bin/lua5.1

COPY plenary-patches /plenary-patches

RUN mkdir -p /usr/local/share/nvim/site/pack/plenary/start && \
    cd /usr/local/share/nvim/site/pack/plenary/start && \
    git clone --depth 1 https://github.com/nvim-lua/plenary.nvim.git && \
    git -C plenary.nvim apply /plenary-patches/*.patch

# Use Lua 5.1 for luarocks
ENV LUA_PATH="/usr/share/lua/5.1/?.lua;/usr/share/lua/5.1/?/init.lua;;"
ENV LUA_CPATH="/usr/lib/lua/5.1/?.so;;"

# Install dependencies for pegasus using Lua 5.1
RUN luarocks --lua-version=5.1 install mimetypes && \
    luarocks --lua-version=5.1 install luafilesystem && \
    luarocks --lua-version=5.1 install luasocket && \
    luarocks --lua-version=5.1 install lzlib && \
    luarocks --lua-version=5.1 install pegasus
