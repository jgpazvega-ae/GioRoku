/** @type {import('tailwindcss').Config} */
export default {
  content: ['./index.html', './src/**/*.{js,ts,jsx,tsx}'],
  darkMode: 'class',
  theme: {
    extend: {
      colors: {
        bg: { primary: '#0D0D0D', surface: '#1A1A1A', elevated: '#262626' },
        accent: { primary: '#E50000', secondary: '#FF6B35' },
        online: '#00C851',
        offline: '#FF4444',
        pending: '#FFBB33',
      },
    },
  },
  plugins: [],
}
