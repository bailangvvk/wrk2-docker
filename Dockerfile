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

# syntax=docker/dockerfile:1.4

FROM alpine:3.20 AS builder

ARG TARGETPLATFORM
RUN apk add --no-cache build-base git build-base openssl-dev

# 克隆 wrk2
RUN git clone --depth=1 https://github.com/giltene/wrk2.git
WORKDIR /wrk2

# 删除原 LuaJIT
RUN rm -rf deps/luajit

# 拉取 LuaJIT 2.1.0-beta3（支持 ARM64）
RUN git clone --branch v2.1 --depth=1 https://github.com/LuaJIT/LuaJIT.git deps/luajit

# 编译 LuaJIT
WORKDIR /wrk2/deps/luajit
RUN make && make install PREFIX=/usr/local

# 回到 wrk2 目录，编译 wrk2（使用系统 LuaJIT）
WORKDIR /wrk2
ENV LUAJIT_LIB=/usr/local/lib LUAJIT_INC=/usr/local/include/luajit-2.1
RUN make

# 最小运行环境
FROM scratch
COPY --from=builder /wrk2/wrk /usr/local/bin/wrk
ENTRYPOINT ["/usr/local/bin/wrk"]

