// Content browser for jander.land

let allItems = [];
let activeTags = new Set();

async function loadContent() {
  const response = await fetch('content.json');
  const data = await response.json();
  return data.items || [];
}

function getAllTags(items) {
  const tags = new Set();
  items.forEach(item => {
    (item.tags || []).forEach(tag => tags.add(tag));
  });
  return Array.from(tags).sort();
}

function sortAndInterleave(items) {
  const dated = items.filter(item => item.date);
  const dateless = items.filter(item => !item.date);

  // Sort dated items by date descending (newest first)
  dated.sort((a, b) => new Date(b.date) - new Date(a.date));

  // Randomly insert dateless items throughout the list
  const result = [...dated];
  dateless.forEach(item => {
    const position = Math.floor(Math.random() * (result.length + 1));
    result.splice(position, 0, item);
  });

  return result;
}

function renderFilterBar(tags) {
  const filterBar = document.getElementById('filter-bar');
  filterBar.innerHTML = '';

  tags.forEach(tag => {
    const button = document.createElement('button');
    button.className = 'filter-button';
    button.textContent = tag;
    button.dataset.tag = tag;

    if (activeTags.has(tag)) {
      button.classList.add('active');
    }

    button.addEventListener('click', () => handleFilterClick(tag));
    filterBar.appendChild(button);
  });
}

function renderContentList(items) {
  const contentList = document.getElementById('content-list');
  contentList.innerHTML = '';

  const filteredItems = filterItems(items, activeTags);
  const sortedItems = sortAndInterleave(filteredItems);

  sortedItems.forEach(item => {
    const link = document.createElement('a');
    link.className = 'content-item';
    link.href = item.url;

    const title = document.createElement('span');
    title.className = 'title';
    title.textContent = item.title;
    link.appendChild(title);

    if (item.tags && item.tags.length > 0) {
      const tags = document.createElement('span');
      tags.className = 'tags';
      tags.textContent = item.tags.join(', ');
      link.appendChild(tags);
    }

    contentList.appendChild(link);
  });
}

function filterItems(items, activeTags) {
  if (activeTags.size === 0) {
    return items;
  }
  // OR logic - show items with ANY selected tag
  return items.filter(item =>
    (item.tags || []).some(tag => activeTags.has(tag))
  );
}

function handleFilterClick(tag) {
  if (activeTags.has(tag)) {
    activeTags.delete(tag);
  } else {
    activeTags.add(tag);
  }

  updateUrlHash();
  renderFilterBar(getAllTags(allItems));
  renderContentList(allItems);
}

function updateUrlHash() {
  if (activeTags.size === 0) {
    history.replaceState(null, '', window.location.pathname);
  } else {
    const hash = Array.from(activeTags).join(',');
    history.replaceState(null, '', `#${hash}`);
  }
}

function loadFiltersFromHash() {
  const hash = window.location.hash.slice(1);
  if (hash) {
    hash.split(',').forEach(tag => activeTags.add(tag));
  }
}

async function init() {
  loadFiltersFromHash();
  allItems = await loadContent();
  const tags = getAllTags(allItems);
  renderFilterBar(tags);
  renderContentList(allItems);
}

init();
