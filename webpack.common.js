const path = require("path");
const CopyWebbackPlugin = require("copy-webpack-plugin");
const HtmlWebpackPlugin = require("html-webpack-plugin");
const MiniCssExtractPlugin = require("mini-css-extract-plugin");

module.exports = {
  entry: {
    index: "./Public/index.js",
  },
  output: {
    globalObject: "self",
    filename: "[name].[contenthash].js",
    path: path.resolve(__dirname, "Public/dist"),
    publicPath: "/",
    clean: true,
  },
  module: {
    rules: [
      {
        test: /\.scss$/,
        use: [
          {
            loader: MiniCssExtractPlugin.loader,
          },
          {
            loader: "css-loader",
            options: {
              url: false,
              sourceMap: true,
              importLoaders: 2,
            },
          },
          {
            loader: "postcss-loader",
            options: {
              sourceMap: true,
              postcssOptions: {
                plugins: ["autoprefixer"],
              },
            },
          },
          {
            loader: "sass-loader",
            options: {
              sourceMap: true,
            },
          },
        ],
      },
      {
        test: /\.css$/,
        use: ["style-loader", "css-loader"],
      },
      {
        test: /\.(woff|woff2|eot|ttf|otf)$/i,
        type: "asset/resource",
      },
    ],
  },
  plugins: [
    new CopyWebbackPlugin({
      patterns: [
        { from: "./Public/images/*.*", to: "images/[name][ext]" },
        { from: "./Public/favicons/*.*", to: "[name][ext]" },
        { from: "./Public/error.html", to: "error.leaf" },
        { from: "./Public/robots.txt", to: "robots.txt" },
        { from: "./.build/wasm/wasm32-unknown-wasi/release/DSLParser.wasm", to: "DSLParser.wasm" },
        { from: "./.build/wasm/wasm32-unknown-wasi/release/DSLConverter.wasm", to: "DSLConverter.wasm" },
        { from: "./.build/wasm/wasm32-unknown-wasi/release/Matcher.wasm", to: "Matcher.wasm" },
        { from: "./.build/wasm/wasm32-unknown-wasi/release/ExpressionParser.wasm", to: "ExpressionParser.wasm" },
      ],
    }),
    new HtmlWebpackPlugin({
      chunks: ["index"],
      filename: "index.leaf",
      template: "./Public/index.html",
    }),
    new MiniCssExtractPlugin({
      filename: "[name].[contenthash].css",
    }),
  ],
};
