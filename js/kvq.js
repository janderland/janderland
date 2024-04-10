(function() {
  const STRING = {
    scope: 'string',
    begin: /"/,
    end: /"/,
  };

  const DSTRING = {
    scope: 'string',
    begin: /[^\/]/,
    end: /(?=\/)/,
    endsWithParent: true,
  };

  const DATA = {
    scope: 'number',
    begin: /[^\/,\(\)=<>\s]/,
    end: /(?=[\/,\(\)=<>\s])/,
  };

  const VARIABLE = {
    scope: 'variable',
    begin: /</,
    end: />/,
    keywords: {
      $$pattern: /[^:|<>]+/,
      keyword: ['int', 'uint', 'bool', 'float', 'bigint', 'string', 'bytes', 'uuid', 'tuple'],
    },
  };

  const REFERENCE = {
    scope: 'reference',
    begin: /:/,
    end: /,/,
  };

  const DIRECTORY = {
    scope: 'directory',
    begin: /\//,
    end: /(?=\()/,
    contains: [STRING, DSTRING],
  };

  const TUPLE = {
    scope: 'tuple',
    begin: /\(/,
    end: /\)/,
    keywords: {
      $$pattern: /[^,\)\s]+/,
      literal: ['nil', 'true', 'false'],
    },
    contains: [STRING, VARIABLE, REFERENCE, DATA],
  };

  const VALUE = {
    scope: 'value',
    begin: /=/,
    end: /\s/,
    keywords: {
      $$pattern: /[^=\s]+/,
      literal: ['nil', 'true', 'false'],
    },
    contains: [STRING, VARIABLE, REFERENCE, DATA],
  };

  hljs.registerLanguage('fql', (hljs) => ({
    classNameAliases: {
      directory: 'built_in',
      tuple: 'built_in',
      value: 'built_in',
      reference: 'variable',
    },
    contains: [DIRECTORY, TUPLE, VALUE],
  }));
})();
