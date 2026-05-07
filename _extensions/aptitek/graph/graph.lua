local function has_class(el, class_name)
  for _, c in ipairs(el.classes) do
    if c == class_name then
      return true
    end
  end
  return false
end

local function handle_controls(div)
  local title = div.attributes["header"] or div.attributes["title"]
  
  -- If first element is a paragraph with just strong text, use it as title (legacy support)
  if not title and #div.content > 0 and div.content[1].t == "Para" and #div.content[1].content == 1 and div.content[1].content[1].t == "Strong" then
    title = pandoc.utils.stringify(div.content[1])
    table.remove(div.content, 1)
  end

  local new_content = pandoc.List()
  local group_div = pandoc.Div(div.content, pandoc.Attr("", {"graph-controls-group"}))
  
  new_content:insert(group_div)
  
  local attr = pandoc.Attr(div.identifier, {"dynamic-graph-controls", "graph-controls"}, div.attributes)
  return pandoc.Div(new_content, attr)
end

local function transform_graph_div(el)
  if has_class(el, "graph") then
    local has_controls = false
    local components = pandoc.List()
    local header_text = el.attributes["header"]
    
    if header_text then
      local figcaption = pandoc.Div({pandoc.Plain({pandoc.Str(header_text)})}, pandoc.Attr("", {"graph-main-title"}))
      components:insert(figcaption)
    end

    for _, block in ipairs(el.content) do
      if block.t == "Div" then
        if has_class(block, "controls") then
          components:insert(handle_controls(block))
          has_controls = true
        elseif has_class(block, "render") then
          local new_classes = pandoc.List()
          new_classes:insert("dynamic-graph-canvas")
          for _, c in ipairs(block.classes) do
            if c ~= "render" then new_classes:insert(c) end
          end
          block.classes = new_classes
          components:insert(block)
        elseif has_class(block, "results") then
          block.classes:insert("dynamic-graph-results")
          local new_classes = pandoc.List()
          for _, c in ipairs(block.classes) do
            if c ~= "results" then new_classes:insert(c) end
          end
          block.classes = new_classes
          components:insert(block)
        elseif has_class(block, "separator") then
           components:insert(block)
        else
          components:insert(block)
        end
      elseif block.t == "Header" and block.level == 4 then
        -- Legacy support for #### Title inside .graph
        if not header_text then
          local figcaption = pandoc.Div({pandoc.Plain(block.content)}, pandoc.Attr("", {"graph-main-title"}))
          components:insert(figcaption)
        end
      else
        components:insert(block)
      end
    end
    
    local container_classes = {"dynamic-graph-container"}
    if has_controls then
      table.insert(container_classes, "has-controls")
    end

    for _, c in ipairs(container_classes) do
      if not has_class(el, c) then
        el.classes:insert(c)
      end
    end
    
    el.content = components
    return el
  end
end

local theme_js = [[
<script>
window.theme = (function() {
  const style = getComputedStyle(document.documentElement);
  const getVar = (name) => style.getPropertyValue(name).trim();
  return {
    blue: getVar('--sol-blue'),
    red: getVar('--sol-red'),
    green: getVar('--sol-green'),
    orange: getVar('--sol-orange'),
    yellow: getVar('--sol-yellow'),
    violet: getVar('--sol-violet'),
    cyan: getVar('--sol-cyan'),
    magenta: getVar('--sol-magenta'),
    base03: getVar('--sol-base03'),
    base02: getVar('--sol-base02'),
    base01: getVar('--sol-base01'),
    base00: getVar('--sol-base00'),
    base0: getVar('--sol-base0'),
    base1: getVar('--sol-base1'),
    base2: getVar('--sol-base2'),
    base3: getVar('--sol-base3'),
    bg: getVar('--bg-color'),
    font_code: getVar('--font-code')
  };
})();

window.ui = {
  card: (content, {title, status = 'debug'} = {}) => {
    const container = document.createElement('div');
    container.className = `card bg-${status} debug`;
    if (title) {
      const header = document.createElement('div');
      header.className = 'card-header';
      header.innerText = title;
      container.appendChild(header);
    }
    const body = document.createElement('div');
    body.className = 'card-body';
    if (content instanceof HTMLElement) {
      body.appendChild(content);
    } else {
      body.innerHTML = content;
    }
    container.appendChild(body);
    return container;
  },
  slider: ({label, labels, value = 0, min = 0, max = 3, step = 1, state}) => {
    const container = document.createElement('div');
    container.className = 'premium-slider-container';
    container.setAttribute('data-state', state !== undefined ? state : value);
    
    const header = document.createElement('div');
    header.className = 'slider-header';
    
    const labelSpan = document.createElement('span');
    labelSpan.className = 'slider-label';
    labelSpan.innerText = label;
    
    const badgeSpan = document.createElement('span');
    badgeSpan.className = 'slider-badge';
    badgeSpan.innerText = labels ? labels[value] : value;
    
    header.appendChild(labelSpan);
    header.appendChild(badgeSpan);
    
    const input = document.createElement('input');
    input.type = 'range';
    input.min = min;
    input.max = max;
    input.step = step;
    input.value = value;
    input.className = 'premium-slider';
    
    container.appendChild(header);
    container.appendChild(input);
    
    if (labels) {
      const ticks = document.createElement('div');
      ticks.className = 'slider-ticks';
      labels.forEach(l => {
        const span = document.createElement('span');
        span.innerText = l;
        ticks.appendChild(span);
      });
      container.appendChild(ticks);
    }
    
    input.oninput = () => {
      container.setAttribute('data-state', input.value);
      badgeSpan.innerText = labels ? labels[input.value] : input.value;
      container.value = step % 1 === 0 ? parseInt(input.value) : parseFloat(input.value);
      container.dispatchEvent(new CustomEvent("input"));
    };
    
    container.value = value;
    return container;
  },
  toggle: ({label, options, value, layout = 'horizontal'}) => {
    const container = document.createElement('div');
    container.className = `premium-toggle-container ${layout}`;
    
    if (label) {
      const labelSpan = document.createElement('span');
      labelSpan.className = 'toggle-label';
      labelSpan.innerText = label;
      container.appendChild(labelSpan);
    }
    
    const group = document.createElement('div');
    group.className = 'toggle-group';
    
    const isObjectOptions = !Array.isArray(options);
    const keys = isObjectOptions ? Object.keys(options) : options;
    
    keys.forEach(key => {
      const displayValue = isObjectOptions ? options[key] : key;
      const btn = document.createElement('button');
      btn.className = `toggle-option ${key === value ? 'active' : ''}`;
      btn.innerText = displayValue;
      btn.onclick = () => {
        group.querySelectorAll('.toggle-option').forEach(b => b.classList.remove('active'));
        btn.classList.add('active');
        container.value = key;
        container.dispatchEvent(new CustomEvent("input"));
      };
      group.appendChild(btn);
    });
    
    container.appendChild(group);
    container.value = value;
    return container;
  },
  checkbox: ({label, value = false}) => {
    const container = document.createElement('div');
    container.className = 'premium-checkbox-container';
    
    const btn = document.createElement('button');
    btn.className = `checkbox-toggle ${value ? 'active' : ''}`;
    
    const icon = document.createElement('span');
    icon.className = 'checkbox-icon';
    icon.innerText = value ? '✓' : '';
    
    const text = document.createElement('span');
    text.className = 'checkbox-text';
    text.innerText = label;
    
    btn.appendChild(icon);
    btn.appendChild(text);
    
    btn.onclick = () => {
      const newValue = !container.value;
      container.value = newValue;
      btn.classList.toggle('active', newValue);
      icon.innerText = newValue ? '✓' : '';
      container.dispatchEvent(new CustomEvent("input"));
    };
    
    container.appendChild(btn);
    container.value = value;
    return container;
  }
};
</script>
]]

-- Use a filter list to control execution order
return {
  {
    -- Pass 1: Transform all .graph Divs and mark if we found any
    Div = function(el)
      if has_class(el, "graph") then
        _G.has_graph_in_doc = true
        return transform_graph_div(el)
      end
    end
  },
  {
    -- Second pass: Inject theme if needed
    Pandoc = function(doc)
      if _G.has_graph_in_doc then
        doc.blocks:insert(1, pandoc.RawBlock('html', theme_js))
      end
      return doc
    end
  }
}
