window.ui.org.canvas = ({width: initialWidth, height = 400, shadow = true} = {}) => {
  const id = "canvas_" + Math.random().toString(36).substr(2, 9);

  // --- Root container ---
  const root = document.createElement("div");
  root.id = id;
  root.className = "ui-canvas-root";
  root.style.cssText = `
    position: relative;
    width: ${initialWidth ? (typeof initialWidth === 'number' ? initialWidth + 'px' : initialWidth) : '100%'};
    max-width: 100%;
    height: ${height}px;
    background: ${window.theme.base3};
    border-radius: 16px;
    overflow: hidden;
    box-sizing: border-box;
    display: block;
    margin: 10px 0;
    ${shadow ? `
      box-shadow: inset 0 2px 15px rgba(0,0,0,0.1);
    ` : ''}
  `;

  // --- SVG layer ---
  const svgNS = "http://www.w3.org/2000/svg";
  const svg = document.createElementNS(svgNS, "svg");
  svg.style.cssText = "position: absolute; top: 0; left: 0; width: 100%; height: 100%; pointer-events: none; overflow: visible;";
  
  const defs = document.createElementNS(svgNS, "defs");
  svg.appendChild(defs);
  const svgMain = document.createElementNS(svgNS, "g");
  svg.appendChild(svgMain);
  root.appendChild(svg);

  // --- HTML layer ---
  const htmlLayer = document.createElement("div");
  htmlLayer.style.cssText = "position: absolute; top: 0; left: 0; width: 100%; height: 100%; pointer-events: none;";
  root.appendChild(htmlLayer);

  // Track width reactively
  let renderedWidth = 0;
  const ro = new ResizeObserver(entries => {
    for (let entry of entries) {
      renderedWidth = entry.contentRect.width;
    }
  });
  ro.observe(root);

  const getWidth = () => renderedWidth || root.offsetWidth || 600;

  const clear = () => {
    while (svgMain.firstChild) svgMain.removeChild(svgMain.firstChild);
    htmlLayer.innerHTML = "";
  };

  const canvas = {
    id,
    node: root,
    svgMain,
    defsNode: defs,
    htmlLayer,
    height,
    getWidth,
    clear,

    atom: {
      node: ({ x, y, radius = 25, color = window.theme.blue, label = '', aura = false, auraRadius = 40, auraOpacity = 0.2 }) => {
        if (aura) {
          const isGradient = aura === 'gradient';
          const auraEl = document.createElementNS(svgNS, "circle");
          auraEl.setAttribute("cx", x);
          auraEl.setAttribute("cy", y);
          auraEl.setAttribute("r", auraRadius);
          
          if (isGradient) {
            const safeColor = color.replace(/[^a-zA-Z0-9]/g, "");
            const gradId = id + "_grad_" + safeColor;
            let grad = defs.querySelector(`#${gradId}`);
            if (!grad) {
              const g = document.createElementNS(svgNS, "radialGradient");
              g.id = gradId;
              const s1 = document.createElementNS(svgNS, "stop");
              s1.setAttribute("offset", "0%"); s1.setAttribute("stop-color", color); s1.setAttribute("stop-opacity", auraOpacity);
              const s2 = document.createElementNS(svgNS, "stop");
              s2.setAttribute("offset", "100%"); s2.setAttribute("stop-color", color); s2.setAttribute("stop-opacity", 0);
              g.appendChild(s1); g.appendChild(s2);
              defs.appendChild(g);
            }
            auraEl.setAttribute("fill", `url(#${gradId})`);
          } else {
            auraEl.setAttribute("fill", color);
            auraEl.setAttribute("opacity", auraOpacity);
          }
          svgMain.appendChild(auraEl);
        }

        const nodeDiv = document.createElement("div");
        const d = radius * 2;
        nodeDiv.style.cssText = `
          position: absolute;
          left: ${x}px; top: ${y}px;
          width: ${d}px; height: ${d}px;
          margin-left: ${-radius}px; margin-top: ${-radius}px;
          border-radius: 50%;
          background: ${color};
          pointer-events: all;
          box-shadow: 0 2px 8px rgba(0,0,0,0.1);
        `;
        htmlLayer.appendChild(nodeDiv);

        if (label) {
          const labelDiv = document.createElement("div");
          labelDiv.style.cssText = `
            position: absolute;
            left: ${x}px; top: ${y + radius + 12}px;
            transform: translateX(-50%);
            font-family: var(--font-base, sans-serif);
            font-size: 1.1rem;
            font-weight: 800;
            text-transform: uppercase;
            letter-spacing: 0.1em;
            color: ${window.theme.base01};
            white-space: nowrap;
          `;
          labelDiv.textContent = label;
          htmlLayer.appendChild(labelDiv);
        }

        return {
          _el: nodeDiv,
          style: (k, v) => { nodeDiv.style[k] = v; return this; }
        };
      },

      link: ({ source, target, color = window.theme.base01, width = 3, dashed = false }) => {
        const path = document.createElementNS(svgNS, "path");
        path.setAttribute("d", `M ${source.x} ${source.y} L ${target.x} ${target.y}`);
        path.setAttribute("stroke", color);
        path.setAttribute("stroke-width", width);
        path.setAttribute("fill", "none");
        if (dashed) path.setAttribute("stroke-dasharray", "8,6");
        svgMain.appendChild(path);
        return path;
      },

      label: ({ x, y, text, color = window.theme.base00, size = "1.2rem", weight = "800" }) => {
        const div = document.createElement("div");
        div.style.cssText = `
          position: absolute;
          left: ${x}px; top: ${y}px;
          transform: translate(-50%, -50%);
          font-family: var(--font-base, sans-serif);
          font-size: ${size};
          font-weight: ${weight};
          color: ${color};
          white-space: nowrap;
        `;
        div.textContent = text;
        htmlLayer.appendChild(div);
        return div;
      }
    }
  };
  return canvas;
};
