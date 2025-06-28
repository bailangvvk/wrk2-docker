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

FROM alpine:3.12 AS build
RUN apk add --no-cache openssl-dev zlib-dev git make gcc musl-dev
# RUN git clone -b aarch64 https://github.com/shawn1m/wrk2.git && \
RUN git clone --depth=1 https://github.com/giltene/wrk2.git && \
    cd wrk2 && make

FROM alpine:3.12
RUN apk add --no-cache libgcc
RUN adduser -D -H wrk_user
USER wrk_user
COPY --from=build /wrk2/wrk /usr/bin/wrk2
ENTRYPOINT ["/usr/bin/wrk2"]

