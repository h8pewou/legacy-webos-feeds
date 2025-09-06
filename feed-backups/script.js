// Global variables
var currentFeed = 'wosa';
var allApps = [];
var filteredApps = [];
var currentPage = 1;
var appsPerPage = 12;
var categories = [];
var currentSort = 'name-asc';

// Initialize the application
function init() {
    loadFeed(currentFeed);
    setupEventListeners();
}

// Setup event listeners
function setupEventListeners() {
    var feedSelect = document.getElementById('feed-select');
    var searchInput = document.getElementById('search-input');
    var sectionFilter = document.getElementById('section-filter');
    var deviceFilter = document.getElementById('device-filter');
    var sortSelect = document.getElementById('sort-select');
    var prevBtn = document.getElementById('prev-btn');
    var nextBtn = document.getElementById('next-btn');
    var closeModal = document.getElementsByClassName('close')[0];
    var closeScreenshotModal = document.getElementsByClassName('close')[1];

    feedSelect.addEventListener('change', function() {
        currentFeed = this.value;
        loadFeed(currentFeed);
    });

    searchInput.addEventListener('input', function() {
        filterApps();
    });

    sectionFilter.addEventListener('change', function() {
        filterApps();
    });

    deviceFilter.addEventListener('change', function() {
        filterApps();
    });

    sortSelect.addEventListener('change', function() {
        currentSort = this.value;
        sortApps();
    });

    prevBtn.addEventListener('click', function() {
        if (currentPage > 1) {
            currentPage--;
            displayApps();
        }
    });

    nextBtn.addEventListener('click', function() {
        var totalPages = Math.ceil(filteredApps.length / appsPerPage);
        if (currentPage < totalPages) {
            currentPage++;
            displayApps();
        }
    });

    closeModal.addEventListener('click', function() {
        document.getElementById('app-detail-modal').style.display = 'none';
    });

    closeScreenshotModal.addEventListener('click', function() {
        document.getElementById('screenshot-modal').style.display = 'none';
    });

    // Close modals when clicking outside
    window.addEventListener('click', function(event) {
        var appModal = document.getElementById('app-detail-modal');
        var screenshotModal = document.getElementById('screenshot-modal');
        if (event.target === appModal) {
            appModal.style.display = 'none';
        }
        if (event.target === screenshotModal) {
            screenshotModal.style.display = 'none';
        }
    });
}

// Load feed data
function loadFeed(feedName) {
    var loading = document.getElementById('loading');
    var appGrid = document.getElementById('app-grid');
    
    loading.style.display = 'block';
    appGrid.innerHTML = '';
    
    var xhr = new XMLHttpRequest();
    xhr.open('GET', feedName + '/Packages', true);
    xhr.onreadystatechange = function() {
        if (xhr.readyState === 4) {
            loading.style.display = 'none';
            if (xhr.status === 200) {
                parsePackagesData(xhr.responseText);
                populateCategoryFilter();
                filterApps();
            } else {
                appGrid.innerHTML = '<div class="error">Error loading feed data</div>';
            }
        }
    };
    xhr.send();
}

// Parse Packages file data
function parsePackagesData(data) {
    allApps = [];
    categories = [];
    
    var entries = data.split('\n\n');
    
    for (var i = 0; i < entries.length; i++) {
        var entry = entries[i].trim();
        if (entry === '') continue;
        
        var app = parseAppEntry(entry);
        if (app) {
            allApps.push(app);
            
            // Collect unique categories
            if (app.section && categories.indexOf(app.section) === -1) {
                categories.push(app.section);
            }
        }
    }
    
    categories.sort();
}

// Parse individual app entry
function parseAppEntry(entry) {
    var lines = entry.split('\n');
    var app = {};
    
    for (var i = 0; i < lines.length; i++) {
        var line = lines[i];
        var colonIndex = line.indexOf(':');
        if (colonIndex === -1) continue;
        
        var key = line.substring(0, colonIndex).trim();
        var value = line.substring(colonIndex + 1).trim();
        
        switch (key) {
            case 'Package':
                app.package = value;
                break;
            case 'Version':
                app.version = value;
                break;
            case 'Section':
                app.section = value;
                break;
            case 'Architecture':
                app.architecture = value;
                break;
            case 'Maintainer':
                app.maintainer = value;
                break;
            case 'Size':
                app.size = parseInt(value);
                break;
            case 'Filename':
                app.filename = value;
                break;
            case 'Description':
                app.description = value;
                break;
            case 'Source':
                try {
                    var sourceData = JSON.parse(value);
                    app.title = sourceData.Title || app.package;
                    app.icon = sourceData.Icon || '';
                    app.screenshots = sourceData.Screenshots || [];
                    app.homepage = sourceData.Homepage || '';
                    app.fullDescription = sourceData.FullDescription || app.description;
                    app.deviceCompatibility = sourceData.DeviceCompatibility || [];
                    app.category = sourceData.Category || app.section;
                    app.license = sourceData.License || '';
                    app.countries = sourceData.Countries || [];
                    app.languages = sourceData.Languages || [];
                    app.location = sourceData.Location || '';
                    app.lastUpdated = sourceData.LastUpdated || '';
                } catch (e) {
                    // If JSON parsing fails, use basic data
                    app.title = app.package;
                    app.icon = '';
                    app.screenshots = [];
                    app.homepage = '';
                    app.fullDescription = app.description;
                    app.deviceCompatibility = [];
                    app.category = app.section;
                    app.license = '';
                    app.countries = [];
                    app.languages = [];
                    app.location = '';
                    app.lastUpdated = '';
                }
                break;
        }
    }
    
    // Ensure we have required fields
    if (!app.title) app.title = app.package;
    if (!app.fullDescription) app.fullDescription = app.description || 'No description available';
    
    return app;
}

// Populate category filter
function populateCategoryFilter() {
    var sectionFilter = document.getElementById('section-filter');
    sectionFilter.innerHTML = '<option value="">All Categories</option>';
    
    for (var i = 0; i < categories.length; i++) {
        var option = document.createElement('option');
        option.value = categories[i];
        option.textContent = categories[i];
        sectionFilter.appendChild(option);
    }
}

// Filter apps based on search and filters
function filterApps() {
    var searchTerm = document.getElementById('search-input').value.toLowerCase();
    var selectedCategory = document.getElementById('section-filter').value;
    var selectedDevice = document.getElementById('device-filter').value;
    
    filteredApps = allApps.filter(function(app) {
        // Search filter
        var matchesSearch = true;
        if (searchTerm) {
            matchesSearch = (
                app.title.toLowerCase().indexOf(searchTerm) !== -1 ||
                app.description.toLowerCase().indexOf(searchTerm) !== -1 ||
                app.category.toLowerCase().indexOf(searchTerm) !== -1
            );
        }
        
        // Category filter
        var matchesCategory = true;
        if (selectedCategory) {
            matchesCategory = app.section === selectedCategory;
        }
        
        // Device filter
        var matchesDevice = true;
        if (selectedDevice) {
            matchesDevice = app.deviceCompatibility.indexOf(selectedDevice) !== -1;
        }
        
        return matchesSearch && matchesCategory && matchesDevice;
    });
    
    currentPage = 1;
    sortApps();
}

// Sort apps based on current sort option
function sortApps() {
    if (filteredApps.length === 0) return;
    
    filteredApps.sort(function(a, b) {
        switch (currentSort) {
            case 'name-asc':
                return a.title.localeCompare(b.title);
            case 'name-desc':
                return b.title.localeCompare(a.title);
            case 'maintainer-asc':
                return a.maintainer.localeCompare(b.maintainer);
            case 'maintainer-desc':
                return b.maintainer.localeCompare(a.maintainer);
            case 'updated-desc':
                var aTime = parseInt(a.lastUpdated) || 0;
                var bTime = parseInt(b.lastUpdated) || 0;
                return bTime - aTime;
            case 'updated-asc':
                var aTime = parseInt(a.lastUpdated) || 0;
                var bTime = parseInt(b.lastUpdated) || 0;
                return aTime - bTime;
            default:
                return 0;
        }
    });
    
    currentPage = 1;
    displayApps();
}

// Display apps with pagination
function displayApps() {
    var appGrid = document.getElementById('app-grid');
    var startIndex = (currentPage - 1) * appsPerPage;
    var endIndex = startIndex + appsPerPage;
    var pageApps = filteredApps.slice(startIndex, endIndex);
    
    appGrid.innerHTML = '';
    
    for (var i = 0; i < pageApps.length; i++) {
        var app = pageApps[i];
        var appCard = createAppCard(app);
        appGrid.appendChild(appCard);
    }
    
    updatePagination();
}

// Create app card element
function createAppCard(app) {
    var card = document.createElement('div');
    card.className = 'app-card';
    card.onclick = function() { showAppDetail(app); };
    
    var iconStyle = app.icon ? 'background-image: url(' + app.icon + ')' : '';
    
    var devicesHtml = '';
    if (app.deviceCompatibility && app.deviceCompatibility.length > 0) {
        for (var i = 0; i < app.deviceCompatibility.length; i++) {
            devicesHtml += '<span class="device-tag">' + app.deviceCompatibility[i] + '</span>';
        }
    }
    
    var sizeText = app.size ? formatFileSize(app.size) : 'Unknown size';
    
    card.innerHTML = 
        '<div class="app-header">' +
            '<div class="app-icon" style="' + iconStyle + '"></div>' +
            '<div class="app-title">' + escapeHtml(app.title) + '</div>' +
            '<div class="app-version">v' + escapeHtml(app.version) + '</div>' +
            '<div class="app-category">' + escapeHtml(app.category) + '</div>' +
        '</div>' +
        '<div class="app-description">' + escapeHtml(truncateText(app.fullDescription, 100)) + '</div>' +
        '<div class="app-meta">' +
            '<span>Size: ' + sizeText + '</span>' +
            '<span>Maintainer: ' + escapeHtml(app.maintainer) + '</span>' +
        '</div>' +
        '<div class="app-devices">' + devicesHtml + '</div>' +
        '<div class="app-actions">' +
            '<a href="' + (app.location || currentFeed + '/' + escapeHtml(app.filename)) + '" class="download-btn" onclick="event.stopPropagation();">Download</a>' +
        '</div>';
    
    return card;
}

// Show app detail modal
function showAppDetail(app) {
    var modal = document.getElementById('app-detail-modal');
    var modalContent = document.getElementById('modal-content');
    
    var iconStyle = app.icon ? 'background-image: url(' + app.icon + ')' : '';
    
    var devicesHtml = '';
    if (app.deviceCompatibility && app.deviceCompatibility.length > 0) {
        for (var i = 0; i < app.deviceCompatibility.length; i++) {
            devicesHtml += '<span class="device-tag">' + app.deviceCompatibility[i] + '</span>';
        }
    }
    
    var screenshotsHtml = '';
    if (app.screenshots && app.screenshots.length > 0) {
        screenshotsHtml = '<div class="modal-screenshots">';
        for (var i = 0; i < app.screenshots.length; i++) {
            screenshotsHtml += '<img src="' + app.screenshots[i] + '" alt="Screenshot ' + (i + 1) + '" onclick="showScreenshot(\'' + app.screenshots[i] + '\')">';
        }
        screenshotsHtml += '</div>';
    }
    
    var sizeText = app.size ? formatFileSize(app.size) : 'Unknown size';
    
    modalContent.innerHTML = 
        '<div class="modal-app-icon" style="' + iconStyle + '"></div>' +
        '<div class="modal-app-title">' + escapeHtml(app.title) + '</div>' +
        '<div class="modal-app-version">Version ' + escapeHtml(app.version) + '</div>' +
        '<div class="modal-app-description">' + escapeHtml(app.fullDescription) + '</div>' +
        screenshotsHtml +
        '<div class="modal-meta">' +
            '<div><strong>Package:</strong> ' + escapeHtml(app.package) + '</div>' +
            '<div><strong>Category:</strong> ' + escapeHtml(app.category) + '</div>' +
            '<div><strong>Size:</strong> ' + sizeText + '</div>' +
            '<div><strong>Maintainer:</strong> ' + escapeHtml(app.maintainer) + '</div>' +
            '<div><strong>Architecture:</strong> ' + escapeHtml(app.architecture) + '</div>' +
            '<div><strong>Compatible Devices:</strong> ' + devicesHtml + '</div>' +
            (app.homepage ? '<div><strong>Homepage:</strong> <a href="' + escapeHtml(app.homepage) + '" target="_blank">' + escapeHtml(app.homepage) + '</a></div>' : '') +
            (app.license ? '<div><strong>License:</strong> ' + escapeHtml(app.license) + '</div>' : '') +
        '</div>' +
        '<div style="text-align: center; margin-top: 20px;">' +
            '<a href="' + (app.location || currentFeed + '/' + escapeHtml(app.filename)) + '" class="download-btn" style="font-size: 14px; padding: 10px 20px;">Download .ipk</a>' +
        '</div>';
    
    modal.style.display = 'block';
}

// Show screenshot in full size modal
function showScreenshot(imageSrc) {
    var screenshotModal = document.getElementById('screenshot-modal');
    var screenshotImg = document.getElementById('screenshot-full');
    screenshotImg.src = imageSrc;
    screenshotModal.style.display = 'block';
}

// Update pagination controls
function updatePagination() {
    var totalPages = Math.ceil(filteredApps.length / appsPerPage);
    var prevBtn = document.getElementById('prev-btn');
    var nextBtn = document.getElementById('next-btn');
    var pageInfo = document.getElementById('page-info');
    
    prevBtn.disabled = currentPage <= 1;
    nextBtn.disabled = currentPage >= totalPages;
    
    pageInfo.textContent = 'Page ' + currentPage + ' of ' + totalPages + ' (' + filteredApps.length + ' apps)';
}

// Utility functions
function escapeHtml(text) {
    if (!text) return '';
    var div = document.createElement('div');
    div.textContent = text;
    return div.innerHTML;
}

function truncateText(text, maxLength) {
    if (!text) return '';
    if (text.length <= maxLength) return text;
    return text.substring(0, maxLength) + '...';
}

function formatFileSize(bytes) {
    if (!bytes) return '0 B';
    var sizes = ['B', 'KB', 'MB', 'GB'];
    var i = Math.floor(Math.log(bytes) / Math.log(1024));
    return Math.round(bytes / Math.pow(1024, i) * 100) / 100 + ' ' + sizes[i];
}

// Initialize when page loads
if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', init);
} else {
    init();
}
