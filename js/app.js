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

  // Sort with priority tags first, then alphabetically
  const priorityTags = ['project', 'profile', 'blog', 'release'];
  return Array.from(tags).sort((a, b) => {
    const aIndex = priorityTags.indexOf(a);
    const bIndex = priorityTags.indexOf(b);
    if (aIndex !== -1 && bIndex !== -1) return aIndex - bIndex;
    if (aIndex !== -1) return -1;
    if (bIndex !== -1) return 1;
    return a.localeCompare(b);
  });
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
