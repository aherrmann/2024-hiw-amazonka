const mermaidOptions = {
  startOnLoad: false,
  lazyLoad: false,
  securityLevel: 'loose',
  theme: 'dark',
  darkMode: true,
  logLevel: 3,
};

RevealMermaid = new EventTarget();
Reveal.on('ready', asyncMermaidRender);
Reveal.on('slidechanged', asyncMermaidRender);
// Reveal.on('slidetransitionend', event => asyncMermaidRender(event));

async function asyncMermaidRender(event) {
  mermaid.init(mermaidOptions, '.stack.present >.present pre code.mermaid');
  mermaid.init(mermaidOptions, '.slides .present:not(.stack) pre code.mermaid');
}
