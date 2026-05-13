window.ui.org.canvas = ({width = 1000, height = 600, shadow = true} = {}) => {
  const id = "canvas_" + Math.random().toString(36).substr(2, 9);
  const filterId = id + "_shadow";

  const svg = document.createElementNS("http://www.w3.org/2000/svg", "svg");
  svg.setAttribute("width", "100%");
  svg.setAttribute("height", "100%");
  svg.setAttribute("viewBox", `0 0 ${width} ${height}`);
  svg.style.maxWidth = "100%";
  svg.style.height = "auto";
  svg.style.display = "block";

  const defs = document.createElementNS("http://www.w3.org/2000/svg", "defs");
  svg.appendChild(defs);

  if (shadow) {
    const filter = document.createElementNS("http://www.w3.org/2000/svg", "filter");
    filter.setAttribute("id", filterId);
    filter.setAttribute("x", "-20%");
    filter.setAttribute("y", "-20%");
    filter.setAttribute("width", "140%");
    filter.setAttribute("height", "140%");

    const dropShadow = document.createElementNS("http://www.w3.org/2000/svg", "feDropShadow");
    dropShadow.setAttribute("dx", "0");
    dropShadow.setAttribute("dy", "2");
    dropShadow.setAttribute("stdDeviation", "3");
    dropShadow.setAttribute("flood-opacity", "0.1");

    filter.appendChild(dropShadow);
    defs.appendChild(filter);
  }

  const rect = document.createElementNS("http://www.w3.org/2000/svg", "rect");
  rect.setAttribute("width", width);
  rect.setAttribute("height", height);
  rect.setAttribute("rx", "20");
  rect.setAttribute("fill", window.theme.base3);
  svg.appendChild(rect);

  const main = document.createElementNS("http://www.w3.org/2000/svg", "g");
  if (shadow) main.setAttribute("filter", `url(#${filterId})`);
  svg.appendChild(main);

  return {
    id,
    node: svg,
    mainNode: main,
    defsNode: defs,
    width,
    height,
    cx: width / 2,
    cy: height / 2,
    legend: (items, { x = 40, y = height - 40, gap = 140 } = {}) => {
      if (typeof d3 === 'undefined') return null;
      const l = d3.select(svg).append("g")
        .attr("transform", `translate(${x}, ${y})`)
        .style("font-family", "var(--font-base)")
        .style("font-size", "11px")
        .style("font-weight", "600")
        .style("text-transform", "uppercase")
        .style("letter-spacing", "1px");

      items.forEach((item, i) => {
        const g = l.append("g").attr("transform", `translate(${i * gap}, 0)`);
        g.append("rect").attr("width", 12).attr("height", 12).attr("rx", 3).attr("y", -6).attr("fill", item.color);
        g.append("text").attr("x", 20).attr("y", 4).text(item.label).attr("fill", window.theme.base01);
      });
      return l;
    },
    // Atomic Canvas Design
    atom: {
      node: ({ x, y, radius = 25, color = window.theme.blue, label = '', aura = false, auraRadius = 40, auraOpacity = 0.2 }) => {
        if (typeof d3 === 'undefined') return null;
        const g = d3.select(main).append("g")
          .attr("transform", `translate(${x}, ${y})`);
        
        if (aura) {
          const isGradient = aura === 'gradient';
          const auraCircle = g.append("circle")
            .attr("r", auraRadius)
            .attr("class", "node-aura");
            
          if (isGradient) {
            const safeColor = color.replace(/[^a-zA-Z0-9]/g, "");
            const gradId = "grad_" + safeColor + "_" + String(auraOpacity).replace('.','_');
            const defsSel = d3.select(defs);
            let grad = defsSel.select(`#${gradId}`);
            if (grad.empty()) {
              grad = defsSel.append("radialGradient").attr("id", gradId);
              grad.append("stop").attr("offset", "0%").attr("stop-color", color).attr("stop-opacity", auraOpacity);
              grad.append("stop").attr("offset", "100%").attr("stop-color", color).attr("stop-opacity", 0);
            }
            auraCircle.attr("fill", `url(#${gradId})`);
          } else {
            auraCircle.attr("fill", color).attr("opacity", auraOpacity);
          }
        }

        const circle = g.append("circle")
          .attr("r", radius)
          .attr("fill", color)
          .attr("stroke", window.theme.base3)
          .attr("stroke-width", 2)
          .attr("class", "node-core");

        if (label) {
          g.append("text")
            .text(label)
            .attr("y", radius + 35)
            .attr("text-anchor", "middle")
            .attr("fill", window.theme.base01)
            .style("font-family", "var(--font-base)")
            .style("font-size", "18px")
            .style("font-weight", "700")
            .style("text-transform", "uppercase")
            .style("letter-spacing", "1px");
        }

        return g;
      },
      link: ({ source, target, color = window.theme.base01, width = 3, dashed = false }) => {
        if (typeof d3 === 'undefined') return null;
        const path = d3.select(main).append("path")
          .attr("d", `M ${source.x} ${source.y} L ${target.x} ${target.y}`)
          .attr("stroke", color)
          .attr("stroke-width", width)
          .attr("fill", "none");
        
        if (dashed) {
          path.attr("stroke-dasharray", "5,5");
        }
        return path;
      },
      label: ({ x, y, text, color = window.theme.base00, size = "20px", weight = "700" }) => {
        if (typeof d3 === 'undefined') return null;
        return d3.select(main).append("text")
          .attr("x", x)
          .attr("y", y)
          .text(text)
          .attr("fill", color)
          .style("font-family", "var(--font-base)")
          .style("font-size", size)
          .style("font-weight", weight)
          .attr("text-anchor", "middle");
      }
    }
  };
};
