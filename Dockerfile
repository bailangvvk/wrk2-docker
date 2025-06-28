# FROM alpine:3.12 as build
# ARG WRK2_COMMIT_HASH=44a94c17d8e6a0bac8559b53da76848e430cb7a7
# # Install deps and build from source
# RUN apk add --no-cache openssl-dev zlib-dev git make gcc musl-dev
# RUN git clone https://github.com/giltene/wrk2 && cd wrk2 && git checkout $WRK2_COMMIT_HASH && make


# FROM alpine:3.12
# # it seems libgcc_s.so is dynamically linked so we need to install libgcc
# RUN apk add --no-cache libgcc
# RUN adduser wrk_user -D -H
# USER wrk_user

# COPY --from=build /wrk2/wrk /usr/bin/wrk2
# ENTRYPOINT ["/usr/bin/wrk2"]

# 不支持ARM64
# FROM alpine:3.12 AS build
# RUN apk add --no-cache openssl-dev zlib-dev git make gcc musl-dev
# # RUN git clone -b aarch64 https://github.com/shawn1m/wrk2.git && \
# RUN git clone --depth=1 https://github.com/giltene/wrk2.git && \
#     cd wrk2 && make

# FROM alpine:3.12
# RUN apk add --no-cache libgcc
# RUN adduser -D -H wrk_user
# USER wrk_user
# COPY --from=build /wrk2/wrk /usr/bin/wrk2
# ENTRYPOINT ["/usr/bin/wrk2"]

FROM alpine:3.12 AS builder

# 安装依赖
RUN apk add --no-cache \
    openssl-dev \
    zlib-dev \
    git make \
    gcc \
    musl-dev \
    libbsd-dev \
    perl
    
# 克隆 wrk2 仓库
RUN git clone --depth=1 https://github.com/giltene/wrk2.git
WORKDIR /wrk2

# 替换为官方支持 ARM64 的 LuaJIT
RUN rm -rf deps/luajit && \
    git clone --branch v2.1 --depth=1 https://github.com/LuaJIT/LuaJIT.git deps/luajit

WORKDIR /wrk2/deps/luajit
RUN make && make install PREFIX=/usr/local

# 构建 wrk2
WORKDIR /wrk2
ENV LUAJIT_LIB=/usr/local/lib LUAJIT_INC=/usr/local/include/luajit-2.1

# 替换老旧结构体
RUN sed -i 's/struct luaL_reg/luaL_Reg/g' src/script.c

# 编译 wrk2
RUN make

# 运行阶段，基于 Alpine，安装运行时依赖
FROM alpine:3.12

# 安装运行时所需的 luajit 依赖库（包含 libluajit-5.1.so.2）
RUN apk add --no-cache luajit libgcc libstdc++

# 拷贝编译好的 wrk 二进制和 LuaJIT 库
COPY --from=build /wrk2/wrk /usr/bin/wrk2
COPY --from=builder /usr/local/lib/libluajit-5.1.so.2* /usr/lib/

ENTRYPOINT ["/usr/local/bin/wrk"]
