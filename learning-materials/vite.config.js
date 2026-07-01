import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';
// Builds to ./dist — Firebase Hosting (site: explore-the-cell-learn) serves this.
// base '/' because the lessons app gets its own Hosting site (not a sub-path).
export default defineConfig({
    plugins: [react()],
    server: { port: 5180, strictPort: true },
    preview: { port: 5181, strictPort: true },
    build: { outDir: 'dist', sourcemap: false },
});
