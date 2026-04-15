/** @type {import('next').NextConfig} */
const nextConfig = {
  // Allow importing TypeScript files from outside the project root (plugins/sdk.ts)
  experimental: {
    externalDir: true,
  },
};

module.exports = nextConfig;
