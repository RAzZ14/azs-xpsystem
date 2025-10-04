let currentProgress = 0;
let animationRunning = false;
let currentUIStyle = 'circular';

document.addEventListener('DOMContentLoaded', function() {
});

window.addEventListener('message', function(event) {
    const data = event.data;
    
    switch(data.action) {
        case 'show':
            showUI(data.data, data.uiStyle);
            break;
        case 'hide':
            hideUI();
            break;
        case 'setUIStyle':
            currentUIStyle = data.uiStyle;
            break;
    }
});

function showUI(xpData, uiStyle = 'circular') {
    currentUIStyle = uiStyle;
    
    document.getElementById('circular-container').classList.add('hidden');
    document.getElementById('rectangular-container').classList.add('hidden');
    
    const containerId = uiStyle === 'circular' ? 'circular-container' : 'rectangular-container';
    const container = document.getElementById(containerId);
    container.classList.remove('hidden');
    
    if (xpData) {
        updateXPDisplay(xpData, uiStyle);
    }
}

function hideUI() {
    document.getElementById('circular-container').classList.add('hidden');
    document.getElementById('rectangular-container').classList.add('hidden');
}

function updateXPDisplay(xpData, uiStyle = 'circular') {
    if (uiStyle === 'circular') {
        updateCircularUI(xpData);
    } else {
        updateRectangularUI(xpData);
    }
}

function updateCircularUI(xpData) {
    const levelElement = document.getElementById('circular-level');
    const oldLevel = parseInt(levelElement.textContent) || 1;
    
    if (xpData.leveled_up && xpData.level > oldLevel) {
        animateLevelUp(levelElement, oldLevel, xpData.level);
    } else {
        levelElement.textContent = xpData.level;
    }
    
    const progressPercent = Math.min(xpData.progress, 100);
    
    animateCircularProgress(progressPercent, xpData.gained_xp > 0);
}

function updateRectangularUI(xpData) {
    const levelElement = document.getElementById('rectangular-level');
    const oldLevel = parseInt(levelElement.textContent) || 1;
    
    if (xpData.leveled_up && xpData.level > oldLevel) {
        animateLevelUp(levelElement, oldLevel, xpData.level);
    } else {
        levelElement.textContent = xpData.level;
    }
    
    document.getElementById('rect-current-xp').textContent = xpData.current_xp.toLocaleString();
    document.getElementById('rect-needed-xp').textContent = xpData.xp_needed.toLocaleString();
    
    const progressPercent = Math.min(xpData.progress, 100);
    
    animateRectangularProgress(progressPercent, xpData.gained_xp > 0);
}

function animateLevelUp(levelElement, oldLevel, newLevel) {
    levelElement.classList.add('slide-out');
    
    setTimeout(() => {
        levelElement.textContent = newLevel;
        levelElement.classList.remove('slide-out');
        levelElement.classList.add('slide-in');
        
        setTimeout(() => {
            levelElement.classList.remove('slide-in');
        }, 400);
    }, 400);
}

function animateCircularProgress(targetPercent, hasGainedXP = false) {
    const circle = document.querySelector('.progress-ring-circle');
    const circumference = 2 * Math.PI * 50;
    
    circle.style.strokeDasharray = `${circumference} ${circumference}`;
    
    if (hasGainedXP) {
        circle.classList.add('animate');
        setTimeout(() => {
            circle.classList.remove('animate');
        }, 2500);
    }
    
    const offset = circumference - (targetPercent / 100) * circumference;
    
    setTimeout(() => {
        circle.style.strokeDashoffset = offset;
    }, hasGainedXP ? 300 : 100);
}

function animateRectangularProgress(targetPercent, hasGainedXP = false) {
    const fill = document.getElementById('rect-progress-fill');
    
    if (hasGainedXP) {
        fill.classList.add('animate');
        setTimeout(() => {
            fill.classList.remove('animate');
        }, 1200);
    }
    
    fill.style.width = `${targetPercent}%`;
}

function GetParentResourceName() {
    return window.location.hostname;
}