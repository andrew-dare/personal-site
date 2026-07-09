import fs from 'node:fs'
import path from 'node:path'
import { fileURLToPath } from 'node:url'

const rootDir = fileURLToPath(new URL('..', import.meta.url))
const distDir = path.join(rootDir, 'dist')
const ssrDir = path.join(rootDir, 'dist-ssr')

const template = fs.readFileSync(path.join(distDir, 'index.html'), 'utf-8')
const { render, routeMeta } = await import(path.join(ssrDir, 'entry-server.js'))

for (const route of routeMeta) {
  const appHtml = render(route.path)

  const html = template
    .replace('<div id="root"></div>', `<div id="root">${appHtml}</div>`)
    .replace(/<title>.*?<\/title>/, `<title>${route.title}</title>`)
    .replace(
      /<meta\s+name="description"\s+content="[^"]*"\s*\/>/,
      `<meta name="description" content="${route.description}" />`,
    )

  const outDir = route.path === '/' ? distDir : path.join(distDir, route.path)
  fs.mkdirSync(outDir, { recursive: true })
  fs.writeFileSync(path.join(outDir, 'index.html'), html)
  console.log(`prerendered ${route.path} -> ${path.relative(rootDir, outDir)}/index.html`)
}

fs.rmSync(ssrDir, { recursive: true, force: true })
