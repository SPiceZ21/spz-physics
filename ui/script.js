let currentPage = 1;
const TOTAL_PAGES = 3;

// Ghost trail history for G-Force
const GHOST_MAX = 20;
let ghostTrail = [];

function getTempColor(temp) {
    // Premium color mapping: Blue (Cold) -> Orange (Optimal) -> Red (Overheating)
    if (temp <= 70) {
        let pct = (temp - 20) / 50;
        return `rgba(52, 152, 219, ${0.3 + pct * 0.7})`; // Blue spectrum
    } else if (temp <= 120) {
        return `rgba(255, 98, 0, 0.9)`; // SPiceZ Orange
    } else {
        let pct = (temp - 120) / 40;
        return `rgba(231, 76, 60, ${0.9 + pct * 0.1})`; // Red spectrum
    }
}

function updateWheel(id, temp, compress) {
    const tempEl = document.getElementById(`temp-${id}`);
    const tireEl = document.querySelector(`#wheel-${id} .tire-status`);
    const suspEl = document.getElementById(`susp-${id}`);

    if (tempEl) tempEl.innerText = `${temp.toFixed(1)}°`;
    if (tireEl) tireEl.style.background = getTempColor(temp);
    if (suspEl) suspEl.style.width = `${Math.min(100, Math.max(0, compress))}%`;
}

function renderGhostTrail() {
    const container = document.getElementById('g-ghost-container');
    if (!container) return;
    
    container.innerHTML = '';
    
    ghostTrail.forEach((pt, i) => {
        const age = i / ghostTrail.length;
        const dot = document.createElement('div');
        dot.className = 'g-ghost-dot';
        dot.style.left = `${pt.x}%`;
        dot.style.top = `${pt.y}%`;
        dot.style.opacity = age * 0.4;
        dot.style.width = `${3 + age * 5}px`;
        dot.style.height = `${3 + age * 5}px`;
        container.appendChild(dot);
    });
}

window.addEventListener('message', function(event) {
    const msg = event.data;

    if (msg.action === "toggle") {
        document.getElementById('telemetry-container').classList.toggle('hidden', !msg.show);
    }

    if (msg.action === "cycle") {
        currentPage = msg.page;
        document.getElementById('page-indicator').innerText = `${currentPage}/3`;
        
        const titles = ["VEHICLE DYNAMICS", "ENGINE & POWER", "G-FORCE DYNAMICS"];
        document.getElementById('category-title').innerText = titles[currentPage - 1];

        document.querySelectorAll('.page').forEach((el, i) => {
            el.classList.toggle('hidden', (i + 1) !== currentPage);
            el.classList.toggle('active', (i + 1) !== currentPage);
        });
    }

    if (msg.action === "update") {
        const d = msg.data;

        // Page 1: Dynamics
        if (currentPage === 1) {
            updateWheel('fl', d.tempFL, d.suspFL);
            updateWheel('fr', d.tempFR, d.suspFR);
            updateWheel('rl', d.tempRL, d.suspRL);
            updateWheel('rr', d.tempRR, d.suspRR);
            
            document.getElementById('steer-val').innerText = `${d.steerAngle}°`;
            document.getElementById('surf-grip').innerText = `${d.surfGrip}%`;
            document.getElementById('wetness').innerText = `${d.wetness}%`;
        }

        // Page 2: Engine
        if (currentPage === 2) {
            document.getElementById('gear-val').innerText = d.gear === 0 ? "R" : d.gear;
            document.getElementById('rpm-val').innerText = Math.round(d.rpm * d.rpmMax);
            document.getElementById('speed-val').innerHTML = `${d.speedMph} <small>MPH</small>`;
            
            document.getElementById('throttle-bar').style.width = `${d.throttle}%`;
            document.getElementById('brake-bar').style.width = `${d.brake}%`;
            document.getElementById('boost-bar').style.width = `${Math.min(100, (d.boost / 2.0) * 100)}%`;
            
            document.getElementById('engine-hp').innerText = d.engineHP;
            document.getElementById('body-hp').innerText = d.bodyHP;
        }

        // Page 3: G-Force
        if (currentPage === 3) {
            const maxG = 2.0;
            const latPct = 50 + (d.latG / maxG) * 50;
            const lonPct = 50 - (d.longG / maxG) * 50; // Invert LonG for visual logic (forward = up)
            
            document.getElementById('g-dot').style.left = `${latPct}%`;
            document.getElementById('g-dot').style.top = `${lonPct}%`;
            
            ghostTrail.push({ x: latPct, y: lonPct });
            if (ghostTrail.length > GHOST_MAX) ghostTrail.shift();
            renderGhostTrail();
            
            document.getElementById('lat-g').innerText = d.latG.toFixed(2);
            document.getElementById('lon-g').innerText = d.longG.toFixed(2);
        }
    }
});
