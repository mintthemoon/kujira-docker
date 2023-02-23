FROM golang:1.19-bullseye AS build
ARG tag_version=v0.8.0

WORKDIR /build
RUN git clone \
        -c advice.detachedHead=false \
        --single-branch \
        --branch ${tag_version} \
        --depth 1 \
        https://github.com/Team-Kujira/core.git \
        . \
    && make install \
    && kujirad version
WORKDIR /dist
RUN mkdir kujira bin lib \
    && mv $(ldd $(which kujirad) | grep libgcc_s.so.1 | awk '{print $3}') lib/ \
    && mv $(ldd $(which kujirad) | grep libwasmvm.x86_64.so | awk '{print $3}') lib/ \
    && mv $(which kujirad) bin/


FROM gcr.io/distroless/base-debian11:latest

COPY --from=build --chown=nonroot:nonroot /dist/kujira /kujira
COPY --from=build /dist/bin/* /usr/local/bin/
COPY --from=build /bin/stty /bin/stty
COPY --from=build /dist/lib/* /usr/lib/
USER nonroot:nonroot
WORKDIR /kujira
ENTRYPOINT ["kujirad", "--home", "."]
