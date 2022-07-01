set -eu

SWIFTWASM_TOOLCHAIN="${SWIFTWASM_TOOLCHAIN:?"Install SwiftWasm toolchain snapshot https://github.com/swiftwasm/swift/releases/tag/swift-wasm-5.7-SNAPSHOT-2022-06-25-a"}"

for product in "DSLParser" "DSLConverter" "Matcher" "ExpressionParser"; do
    echo "Building ${product} for WebAssembly..."
    $SWIFTWASM_TOOLCHAIN/usr/bin/swift build \
        --triple wasm32-unknown-wasi \
        --scratch-path .build/wasm \
        --configuration release \
        -Xswiftc -enable-testing \
        --product "$product"
done
