FROM swiftlang/swift:nightly-main-focal as swift
RUN export DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true \
    && apt-get -q update && apt-get -q dist-upgrade -y \
    && apt-get install -y --no-install-recommends libsqlite3-dev curl \
    && rm -rf /var/lib/apt/lists/*

RUN set -e; \
    SWIFT_PLATFORM_SUFFIX="ubuntu20.04_x86_64.tar.gz" \
    SWIFTWASM_TAG=swift-wasm-5.7-SNAPSHOT-2022-06-25-a \
    SWIFTWASM_BIN_URL="https://github.com/swiftwasm/swift/releases/download/$SWIFTWASM_TAG/$SWIFTWASM_TAG-$SWIFT_PLATFORM_SUFFIX" \
    && export DEBIAN_FRONTEND=noninteractive \
    && curl -fsSL "$SWIFTWASM_BIN_URL" -o swiftwasm.tar.gz \
    && mkdir -p /opt/swiftwasm \
    && tar -xzf swiftwasm.tar.gz --directory /opt/swiftwasm --strip-components=1 \
    && chmod -R o+r /opt/swiftwasm/usr/lib/swift \
    && rm -rf swiftwasm.tar.gz

WORKDIR /build
COPY ./Package.* ./
RUN swift package resolve

COPY . .
RUN --mount=type=cache,target=/build/.build \
    swift build -c release -Xswiftc -enable-testing
RUN --mount=type=cache,target=/build/.build \
    SWIFTWASM_TOOLCHAIN=/opt/swiftwasm ./Scripts/build-wasm.sh

WORKDIR /staging
RUN --mount=type=cache,target=/build/.build \
    cp "$(swift build --package-path /build -c release --show-bin-path)/Run" ./ \
    && mv /build/Public ./Public && chmod -R a-w ./Public \
    && cp -R /build/.build ./.build && chmod -R a-w ./.build

FROM node:lts-slim as node

WORKDIR /build

ARG FONTAWESOME_TOKEN
COPY package*.json ./
RUN echo "@fortawesome:registry=https://npm.fontawesome.com/\n//npm.fontawesome.com/:_authToken=${FONTAWESOME_TOKEN}" > ./.npmrc \
    && npm ci \
    && rm -f ./.npmrc

COPY webpack.*.js ./
COPY Public ./Public/
COPY --from=swift /staging/.build/wasm .build/wasm
RUN npx webpack --config webpack.prod.js



FROM swiftlang/swift:nightly-main-focal
RUN export DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true \
    && apt-get -q update && apt-get -q dist-upgrade -y && rm -r /var/lib/apt/lists/*\
    && useradd --user-group --create-home --system --skel /dev/null --home-dir /app vapor

WORKDIR /app
COPY --from=node /build /staging
COPY --from=swift --chown=vapor:vapor /staging /app

USER vapor:vapor
EXPOSE 8080

ENTRYPOINT ["./Run"]
CMD ["serve", "--env", "production", "--hostname", "0.0.0.0", "--port", "8080"]
 
