FROM node:lts-slim as node

WORKDIR /build

ARG FONTAWESOME_TOKEN
COPY package*.json ./
RUN echo "@fortawesome:registry=https://npm.fontawesome.com/\n//npm.fontawesome.com/:_authToken=${FONTAWESOME_TOKEN}" > ./.npmrc \
    && npm ci \
    && rm -f ./.npmrc

COPY webpack.*.js ./
COPY Public ./Public/
RUN npx webpack --config webpack.prod.js


FROM swiftlang/swift:nightly-main-jammy as swift
RUN export DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true \
    && apt-get -q update && apt-get -q dist-upgrade -y \
    && apt-get install -y --no-install-recommends libsqlite3-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /build
COPY --from=node /build /build
COPY ./Package.* ./
RUN swift package resolve

COPY . .
RUN swift build -c release --static-swift-stdlib -Xswiftc -DPROCESSOR_MEASUREMENTS_ENABLED -Xswiftc -enable-testing

WORKDIR /staging

RUN cp "$(swift build --package-path /build -c release --show-bin-path)/App" ./

RUN find -L "$(swift build --package-path /build -c release --show-bin-path)/" -regex '.*\.resources$' -exec cp -Ra {} ./ \;

RUN [ -d /build/Public ] && { mv /build/Public ./Public && chmod -R a-w ./Public; } || true
RUN [ -d /build/Resources ] && { mv /build/Resources ./Resources && chmod -R a-w ./Resources; } || true
RUN [ -d /build/.build ] && { mv /build/.build ./.build && chmod -R a-w ./.build; } || true


FROM swiftlang/swift:nightly-main-jammy
RUN export DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true \
    && apt-get -q update \
    && apt-get -q dist-upgrade -y \
    && apt-get -q install -y \
      ca-certificates \
      tzdata \
    && rm -r /var/lib/apt/lists/*

RUN useradd --user-group --create-home --system --skel /dev/null --home-dir /app vapor

WORKDIR /app
COPY --from=swift --chown=vapor:vapor /staging /app

USER vapor:vapor
EXPOSE 8080

ENTRYPOINT ["./App"]
CMD ["serve", "--env", "production", "--hostname", "0.0.0.0", "--port", "8080"]
 