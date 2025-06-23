# Stage 1: Build wrk2 from source
FROM alpine:3.12 AS build
ARG WRK2_COMMIT_HASH=master
RUN apk add --no-cache openssl-dev zlib-dev git make gcc musl-dev
RUN git clone https://github.com/giltene/wrk2 && \
    cd wrk2 && git checkout $WRK2_COMMIT_HASH && make

# Stage 2: Minimal runtime image
FROM alpine:3.12
RUN apk add --no-cache libgcc
RUN adduser -D -H wrk_user
USER wrk_user
COPY --from=build /wrk2/wrk /usr/bin/wrk2
ENTRYPOINT ["/usr/bin/wrk2"]
