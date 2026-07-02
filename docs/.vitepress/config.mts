import { defineConfig } from 'vitepress'
import { withMermaid } from 'vitepress-plugin-mermaid'

const REPO = 'https://github.com/Surge-Studios-Dev/Daedalus'

export default withMermaid(
  defineConfig({
    title: 'Daedalus',
    description:
      'The Surge Studios app factory: one manifest becomes an app, its backend, its legal, its store listing, and its web presence.',
    lang: 'en-US',
    lastUpdated: true,
    // Links to files outside docs/ are rewritten to GitHub below; anything
    // else unusual should never fail the build of a living wiki.
    ignoreDeadLinks: true,

    markdown: {
      config(md) {
        // 0. Inline code must never be parsed for Vue interpolations - this
        //    wiki legitimately documents mustache templating ({{slug}} etc.).
        const origCodeInline = md.renderer.rules.code_inline!
        md.renderer.rules.code_inline = (tokens, idx, options, env, self) =>
          origCodeInline(tokens, idx, options, env, self).replace(
            /^<code/,
            '<code v-pre',
          )
        // 1. Rewrite links that point outside docs/ (../FRAMEWORK.md, the
        //    manifest example, package files) to the GitHub blob view, so
        //    they work on the website too. Token-level, before render.
        md.core.ruler.push('daedalus-external-links', (state) => {
          for (const blockToken of state.tokens) {
            if (blockToken.type !== 'inline' || !blockToken.children) continue
            for (const t of blockToken.children) {
              if (t.type !== 'link_open') continue
              const href = t.attrGet('href')
              if (href && href.startsWith('../')) {
                t.attrSet(
                  'href',
                  `${REPO}/blob/main/${href.replace(/^(\.\.\/)+/, '')}`,
                )
              }
            }
          }
        })
        // 2. Tag the 🔲 TODO stub blockquotes so the theme can style them
        //    as what they are: future-system markers, not ordinary quotes.
        md.core.ruler.push('daedalus-todo-stubs', (state) => {
          const tokens = state.tokens
          for (let i = 0; i < tokens.length; i++) {
            if (tokens[i].type !== 'blockquote_open') continue
            for (let j = i + 1; j < tokens.length; j++) {
              if (tokens[j].type === 'blockquote_close') break
              if (tokens[j].type === 'inline' && tokens[j].content.includes('🔲')) {
                tokens[i].attrJoin('class', 'todo-stub')
                break
              }
            }
          }
        })
      },
    },

    mermaid: {
      // One look for both color schemes; the diagrams' own classDefs
      // (forest-green "truth" nodes etc.) read fine on neutral.
      theme: 'neutral',
    },

    themeConfig: {
      siteTitle: 'Daedalus',
      nav: [
        { text: 'Wiki hub', link: '/README' },
        { text: 'Pipeline', link: '/pipeline' },
        { text: 'Future', link: '/future' },
        { text: 'Roadmap', link: `${REPO}/blob/main/ROADMAP.md` },
      ],
      sidebar: [
        {
          text: 'Start here',
          items: [
            { text: 'The factory in one picture', link: '/README' },
            { text: 'Pipeline: idea → shipped', link: '/pipeline' },
          ],
        },
        {
          text: 'The factory',
          items: [
            { text: 'Architecture: tiers & seams', link: '/architecture' },
            { text: 'The manifest', link: '/manifest' },
            { text: 'Foundation (the canvas)', link: '/foundation' },
            { text: 'Brick (stamping)', link: '/brick' },
            { text: 'surge_ui (the toolbox)', link: '/surge-ui' },
          ],
        },
        {
          text: 'Ship it',
          items: [
            { text: 'Backend safety rail', link: '/backend' },
            { text: 'Provisioning (cloud)', link: '/provisioning' },
            { text: 'Analytics (monitoring)', link: '/analytics' },
            { text: 'Compliance & web', link: '/compliance-and-web' },
            { text: 'Release rail', link: '/release' },
          ],
        },
        {
          text: "What's next",
          items: [{ text: 'Future systems', link: '/future' }],
        },
      ],
      outline: { level: [2, 3], label: 'On this page' },
      search: { provider: 'local' },
      socialLinks: [{ icon: 'github', link: REPO }],
      footer: {
        message: 'Surge Studios LLC · the factory is the plumbing, never the product.',
      },
      lastUpdated: { text: 'Updated' },
    },
  }),
)
