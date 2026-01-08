/**
 * Initialize syntax highlighting for specified languages.
 * @param {string[]} languages - Array of language names (e.g., ['fql', 'go'])
 */
function initHighlighting(languages) {
  // Convert class names from shorthand to language- prefix
  // e.g., class="fql" becomes class="language-fql"
  if (languages && languages.length > 0) {
    languages.forEach(lang => {
      document.querySelectorAll(`.${lang}`).forEach(e => {
        e.classList.replace(lang, `language-${lang}`);
      });
    });
  }

  // Run highlight.js on all code blocks
  hljs.highlightAll();

  // Ensure inline code blocks are also highlighted
  document.querySelectorAll(":not(pre) > code[class^='language-']").forEach((e) => {
    hljs.highlightElement(e);
  });
}
