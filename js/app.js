// Content browser for jander.land

let allItems = [];
let activeTag = 'all';

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

  // Sort with priority tags first, then alphabetically
  const priorityTags = ['profile', 'project', 'blog', 'release'];
  const sortedTags = Array.from(tags).sort((a, b) => {
    const aIndex = priorityTags.indexOf(a);
    const bIndex = priorityTags.indexOf(b);
    if (aIndex !== -1 && bIndex !== -1) return aIndex - bIndex;
    if (aIndex !== -1) return -1;
    if (bIndex !== -1) return 1;
    return a.localeCompare(b);
  });

  // Add 'all' to the front
  return ['all', ...sortedTags];
}

function sortItems(items) {
  const dated = items.filter(item => item.date);
  const dateless = items.filter(item => !item.date);

  // Sort dated items by date descending (newest first)
  dated.sort((a, b) => new Date(b.date) - new Date(a.date));

  // Place dateless items (projects) at the start
  return [...dateless, ...dated];
}

function renderFilterBar(tags) {
  const filterBar = document.getElementById('filter-bar');
  filterBar.innerHTML = '';

  tags.forEach(tag => {
    const button = document.createElement('button');
    button.className = 'filter-button';
    button.textContent = tag;
    button.dataset.tag = tag;

    if (activeTag === tag) {
      button.classList.add('active');
    }

    button.addEventListener('click', () => handleFilterClick(tag));
    filterBar.appendChild(button);
  });
}

function renderContentList(items) {
  const contentList = document.getElementById('content-list');
  contentList.innerHTML = '';

  const filteredItems = filterItems(items, activeTag);
  const sortedItems = sortItems(filteredItems);

  sortedItems.forEach(item => {
    const link = document.createElement('a');
    link.className = 'content-item';
    link.href = item.url;

    // Set data-type for styling
    if (item.tags && item.tags.includes('project')) {
      link.dataset.type = 'project';
    } else if (item.tags && item.tags.includes('profile')) {
      link.dataset.type = 'profile';
    }

    const title = document.createElement('span');
    title.className = 'title';

    // For releases, wrap the project name in a span for bold styling
    if (item.tags && item.tags.includes('release') && item.title.includes(':')) {
      const colonIndex = item.title.indexOf(':');
      const projectName = document.createElement('span');
      projectName.className = 'project-name';
      projectName.textContent = item.title.substring(0, colonIndex);
      title.appendChild(projectName);
      title.appendChild(document.createTextNode(' - ' + item.title.substring(colonIndex + 1).trimStart()));
    } else {
      title.textContent = item.title;
    }
    link.appendChild(title);

    // Show date and tags on hover
    const meta = document.createElement('span');
    meta.className = 'meta';
    const parts = [];
    if (item.date) {
      // Use last 2 digits of year (2025-12-27 -> 25-12-27)
      parts.push(item.date.substring(2));
    }
    if (item.tags && item.tags.length > 0) {
      parts.push(item.tags.join(' '));
    }
    if (parts.length > 0) {
      meta.textContent = parts.join(' · ');
      link.appendChild(meta);
    }

    contentList.appendChild(link);
  });
}

function filterItems(items, activeTag) {
  if (activeTag === 'all') {
    return items;
  }
  // Show items with the selected tag or whose title matches
  return items.filter(item =>
    (item.tags || []).includes(activeTag) ||
    item.title.toLowerCase() === activeTag
  );
}

function handleFilterClick(tag) {
  // Clicking the active tag reverts to 'all', otherwise select the clicked tag
  activeTag = (tag === activeTag) ? 'all' : tag;

  updateUrlHash();
  renderFilterBar(getAllTags(allItems));
  renderContentList(allItems);
}

function updateUrlHash() {
  if (activeTag === 'all') {
    history.replaceState(null, '', window.location.pathname);
  } else {
    history.replaceState(null, '', `#${activeTag}`);
  }
}

function loadFiltersFromHash() {
  const hash = window.location.hash.slice(1);
  // Use the hash as the active tag, or default to 'all'
  activeTag = hash || 'all';
}

function handleHashChange() {
  loadFiltersFromHash();
  renderFilterBar(getAllTags(allItems));
  renderContentList(allItems);
}

async function init() {
  loadFiltersFromHash();
  allItems = await loadContent();
  const tags = getAllTags(allItems);
  renderFilterBar(tags);
  renderContentList(allItems);

  window.addEventListener('hashchange', handleHashChange);
}

init();
