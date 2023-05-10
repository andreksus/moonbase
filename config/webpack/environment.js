const { environment } = require("@rails/webpacker");
const { merge } = require("webpack-merge");
const webpack = require("webpack");
const path = require("path");

const CompressionPlugin = require("compression-webpack-plugin");
const zlib = require("zlib");

const plugins = {
    plugins: [
        new CompressionPlugin({
            filename: "[path].br",
            algorithm: "brotliCompress",
            // test: /\.(js|css|html|svg|png|jpg)$/,
            compressionOptions: {
                params: {
                    [zlib.constants.BROTLI_PARAM_QUALITY]: 11,
                },
            },
            threshold: 10240,
            minRatio: 0.8,
            deleteOriginalAssets: false,
        }),
        new webpack.NamedModulesPlugin(),
        new webpack.HashedModuleIdsPlugin()
    ],
    // optimization: {
    //     minimize: true,
    //     runtimeChunk: 'single',
    //     splitChunks: {
    //       chunks: 'all',
    //       maxInitialRequests: Infinity,
    //       minSize: 0,
    //       cacheGroups: {
    //         // @see https://hackernoon.com/the-100-correct-way-to-split-your-chunks-with-webpack-f8a9df5b7758
    //         vendor: {
    //           test: /[\\/]node_modules[\\/]/,
    //           name(module) {
    //             const packageName = module.context.match(/[\\/]node_modules[\\/](.*?)([\\/]|$)/)[1];
    //             return `npm.${packageName.replace('@', '')}`;
    //           },
    //           priority: 10,
    //         },
    //       }
    //     }
    //   }    
};

environment.splitChunks();

module.exports = merge(environment.toWebpackConfig(), plugins);
