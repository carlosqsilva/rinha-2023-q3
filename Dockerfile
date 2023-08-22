FROM ubuntu:22.04 AS base

RUN apt update && \
    DEBIAN_FRONTEND=noninteractive apt install -y --no-install-recommends libpq-dev && \
    apt clean && rm -rf /var/cache/apt/archives/* && \
    rm -rf /var/lib/apt/lists/*

FROM base as builder

WORKDIR /opt/vlang

ENV VFLAGS -cc clang

RUN apt update && \
    DEBIAN_FRONTEND=noninteractive apt install -y --no-install-recommends build-essential clang make git binutils libpq-dev ca-certificates && \
    apt clean && rm -rf /var/cache/apt/archives/* && \
    rm -rf /var/lib/apt/lists/*

COPY . /vlang-local

RUN git clone --depth 1 https://github.com/vlang/v/ /opt/vlang

RUN make && \
    ln -s /opt/vlang/v /usr/local/bin/v

RUN v --version

WORKDIR /app

COPY ./v.mod ./
COPY ./src ./src

RUN v -prod .

FROM base AS final

WORKDIR /app
COPY --from=builder /app ./

EXPOSE 8080
CMD ["./app"]
