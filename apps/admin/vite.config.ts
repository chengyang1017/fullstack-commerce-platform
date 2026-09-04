import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

// https://vite.dev/config/
export default defineConfig({
  plugins: [react()],
  preview: {
    // Railway health checks reach the preview server through an internal host.
    // Allow that host while the public service remains protected by Railway.
    allowedHosts: true,
  },
})
