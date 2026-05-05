let projects = [];
const grid = document.getElementById('projectsGrid');
const searchInput = document.getElementById('searchInput');

// Fetch projects from JSON
async function loadProjects() {
    try {
        const response = await fetch('projects.json');
        if (!response.ok) throw new Error('Failed to load projects.json');
        projects = await response.json();
        // Sort by latest commit date descending
        projects.sort((a, b) => new Date(b.pushed_at) - new Date(a.pushed_at));
        renderProjects();
    } catch (error) {
        console.error('Error loading projects:', error);
        grid.innerHTML = '<div class="empty-state">Failed to load projects. Are you viewing this through a local server? CORS might be blocking the request.</div>';
    }
}

function renderProjects(filterText = '') {
    grid.innerHTML = '';
    const lowerFilter = filterText.toLowerCase().trim();
    
    let matchCount = 0;

    projects.forEach(project => {
        const descMatch = project.description && project.description.toLowerCase().includes(lowerFilter);
        const nameMatch = project.name.toLowerCase().includes(lowerFilter);

        if (nameMatch || descMatch) {
            matchCount++;
            const a = document.createElement('a');
            a.href = project.url;
            a.className = 'project-card';
            a.target = '_blank';
            a.rel = 'noopener noreferrer';
            
            a.innerHTML = `
                <div class="gh-badge">Page</div>
                <div class="project-title">
                    <span class="project-icon">✦</span>
                    ${project.name}
                </div>
                <div class="project-url">${project.url}</div>
                ${project.description ? `<div class="project-desc">${project.description}</div>` : ''}
            `;
            grid.appendChild(a);
        }
    });

    if (matchCount === 0 && projects.length > 0) {
        grid.innerHTML = `<div class="empty-state">No projects found matching "${filterText}"</div>`;
    }
}

searchInput.addEventListener('input', (e) => {
    renderProjects(e.target.value);
});

// Initial load
loadProjects();
