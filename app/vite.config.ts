import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";

// base:'./' keeps the build loadable from the file system / Capacitor webview,
// matching how the legacy static app is packaged.
export default defineConfig({
  base: "./",
  plugins: [react()],
  // host:true binds IPv4 (127.0.0.1) + IPv6 + LAN; strictPort keeps the port
  // fixed (fail loudly instead of silently hopping to 5184/5185/…).
  server: { host: true, port: 5183, strictPort: true },
  build: { outDir: "dist" }
});
