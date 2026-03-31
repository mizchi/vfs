default:
  moon check

build:
  moon build --target js

test:
  moon test

bench: build
  cd .. && pnpm exec vite-node src/bench/run.ts
