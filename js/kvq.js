(function() {
  const STR = {
    scope: 'string',
    begin: /"/,
    end: /"/,
  };

  const DIR_STR = {
    scope: 'string',
    begin: /[^\/]/,
    end: /(?=\/)/,
    endsWithParent: true,
  };

  const NUM = {
    scope: 'number',
    begin: /[^\/,\(\)=<>\s]/,
    end: /(?=[\/,\(\)=<>\s])/,
  };

  const VAR = {
    scope: 'variable',
    begin: /</,
    end: />/,
    keywords: {
      $$pattern: /[^:|<>]+/,
      keyword: ['int', 'uint', 'bool', 'float', 'bigint', 'string', 'bytes', 'uuid', 'tuple'],
    },
  };

  const VAR_REF = {
    scope: 'reference',
    begin: /:/,
    end: /,/,
  };

  const DIR = {
    scope: 'directory',
    begin: /\//,
    end: /(?=\()/,
    contains: [STR, DIR_STR],
  };

  const TUP = {
    scope: 'tuple',
    begin: /\(/,
    end: /\)/,
    keywords: {
      $$pattern: /[^,\)\s]+/,
      literal: ['nil', 'true', 'false'],
    },
    contains: [STR, VAR, VAR_REF, NUM],
  };

  const VAL = {
    scope: 'value',
    begin: /=/,
    end: /\s/,
    keywords: {
      $$pattern: /[^=\s]+/,
      literal: ['nil', 'true', 'false'],
    },
    contains: [STR, VAR, VAR_REF, NUM],
  };

  hljs.registerLanguage('fql', (hljs) => ({
    classNameAliases: {
      directory: 'built_in',
      tuple: 'built_in',
      value: 'built_in',
      reference: 'variable',
    },
    contains: [DIR, TUP, VAL],
  }));
})();
