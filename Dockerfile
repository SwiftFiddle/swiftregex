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


FROM swiftlang/swift:nightly-main-focal as swift
RUN export DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true \
    && apt-get -q update && apt-get -q dist-upgrade -y \
    && apt-get install -y --no-install-recommends libsqlite3-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /build
COPY --from=node /build /build
COPY ./Package.* ./
RUN swift package resolve

COPY . .
RUN swift build -c release -Xswiftc -enable-testing

WORKDIR /staging
RUN cp "$(swift build --package-path /build -c release --show-bin-path)/Run" ./ \
    && mv /build/Public ./Public && chmod -R a-w ./Public \
    && mv /build/.build ./.build && chmod -R a-w ./.build


FROM swiftlang/swift:nightly-main-focal
RUN export DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true \
    && apt-get -q update && apt-get -q dist-upgrade -y && rm -r /var/lib/apt/lists/*\
    && useradd --user-group --create-home --system --skel /dev/null --home-dir /app vapor

WORKDIR /app
COPY --from=swift --chown=vapor:vapor /staging /app

USER vapor:vapor
EXPOSE 8080

ENTRYPOINT ["./Run"]
CMD ["serve", "--env", "production", "--hostname", "0.0.0.0", "--port", "8080"]
 