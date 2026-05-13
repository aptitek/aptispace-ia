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
  local group_div = pandoc.Div(div.content, pandoc.Attr("", {"org-controls-group"}))
  
  new_content:insert(group_div)
  
  local attr = pandoc.Attr(div.identifier, {"org-controls"}, div.attributes)
  return pandoc.Div(new_content, attr)
end

local function transform_dynamic_div(el)
  if has_class(el, "dynamic") then
    local has_controls = false
    local components = pandoc.List()
    local header_text = el.attributes["header"]
    
    if header_text then
      local figcaption = pandoc.Div({pandoc.Plain({pandoc.Str(header_text)})}, pandoc.Attr("", {"tpl-main-title"}))
      components:insert(figcaption)
    end

    for _, block in ipairs(el.content) do
      if block.t == "Div" then
        if has_class(block, "controls") then
          components:insert(handle_controls(block))
          has_controls = true
        elseif has_class(block, "render") then
          local new_classes = pandoc.List()
          new_classes:insert("org-render")
          for _, c in ipairs(block.classes) do
            if c ~= "render" then new_classes:insert(c) end
          end
          block.classes = new_classes
          components:insert(block)
        elseif has_class(block, "results") then
          local new_classes = pandoc.List()
          new_classes:insert("org-results")
          for _, c in ipairs(block.classes) do
            if c ~= "results" then new_classes:insert(c) end
          end
          block.classes = new_classes
          components:insert(block)
        elseif has_class(block, "separator") then
           block.classes = pandoc.List({"mol-separator"})
           components:insert(block)
        else
          components:insert(block)
        end
      elseif block.t == "Header" and block.level == 4 then
        -- Legacy support for #### Title inside .dynamic
        if not header_text then
          local figcaption = pandoc.Div({pandoc.Plain(block.content)}, pandoc.Attr("", {"tpl-main-title"}))
          components:insert(figcaption)
        end
      else
        components:insert(block)
      end
    end
    
    local container_classes = {"tpl-dynamic"}
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

window.ui = (function() {
  const atom = {
    button: (content, {status = 'primary', icon} = {}) => {
      const btn = document.createElement('button');
      btn.className = `atom-btn ${status === 'secondary' ? 'is-secondary' : ''}`;
      if (icon) {
        const iconSpan = document.createElement('span');
        iconSpan.innerText = icon;
        btn.appendChild(iconSpan);
      }
      const text = document.createElement('span');
      text.innerText = content;
      btn.appendChild(text);
      return btn;
    },
    label: (text) => {
      const label = document.createElement('span');
      label.className = 'atom-label';
      label.innerText = text;
      return label;
    },
    badge: (text) => {
      const badge = document.createElement('span');
      badge.className = 'atom-badge';
      badge.innerText = text;
      return badge;
    },
    input: ({value = '', placeholder = '', type = 'text'} = {}) => {
      const input = document.createElement('input');
      input.className = 'atom-input';
      input.type = type;
      input.value = value;
      input.placeholder = placeholder;
      return input;
    },
    textarea: ({value = '', rows = 3, placeholder = ''} = {}) => {
      const textarea = document.createElement('textarea');
      textarea.className = 'atom-textarea';
      textarea.rows = rows;
      textarea.value = value;
      textarea.placeholder = placeholder;
      return textarea;
    },
    select: ({options, value} = {}) => {
      const select = document.createElement('select');
      select.className = 'atom-select';
      const isObjectOptions = !Array.isArray(options);
      const keys = isObjectOptions ? Object.keys(options) : options;
      keys.forEach(key => {
        const option = document.createElement('option');
        option.value = key;
        option.innerText = isObjectOptions ? options[key] : key;
        if (key == value) option.selected = true;
        select.appendChild(option);
      });
      return select;
    }
  };

  const mol = {
    slider: ({label, labels, value = 0, min = 0, max = 3, step = 1, state}) => {
      const container = document.createElement('div');
      container.className = 'mol-slider';
      // Use explicit state if provided, otherwise fallback to value for backward compatibility
      const colorState = state !== undefined ? state : value;
      container.setAttribute('data-state', colorState);
      
      const header = document.createElement('div');
      header.className = 'slider-header';
      
      const labelEl = atom.label(label);
      const badgeEl = atom.badge(labels ? labels[value] : value);
      
      header.appendChild(labelEl);
      header.appendChild(badgeEl);
      
      const input = document.createElement('input');
      input.type = 'range';
      input.min = min;
      input.max = max;
      input.step = step;
      input.value = value;
      input.className = 'premium-slider'; // Keep for track styling
      
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
        // Maintain the color state even when value changes
        container.setAttribute('data-state', state !== undefined ? state : input.value);
        badgeEl.innerText = labels ? labels[input.value] : input.value;
        container.value = step % 1 === 0 ? parseInt(input.value) : parseFloat(input.value);
        container.dispatchEvent(new CustomEvent("input"));
      };
      
      container.value = value;
      return container;
    },
    toggle: ({label, options, value, layout = 'horizontal'}) => {
      const container = document.createElement('div');
      container.className = `mol-toggle ${layout === 'horizontal' ? 'is-horizontal' : ''}`;
      
      if (label) container.appendChild(atom.label(label));
      
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
      container.className = 'mol-checkbox';
      
      const btn = document.createElement('button');
      btn.className = `checkbox-toggle ${value ? 'is-active' : ''}`;
      
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
        btn.classList.toggle('is-active', newValue);
        icon.innerText = newValue ? '✓' : '';
        container.dispatchEvent(new CustomEvent("input"));
      };
      
      container.appendChild(btn);
      container.value = value;
      return container;
    },
    field: ({label, element}) => {
      const container = document.createElement('div');
      container.className = 'mol-field';
      if (label) container.appendChild(atom.label(label));
      container.appendChild(element);
      
      // Mirror value and events
      element.oninput = () => {
        container.value = element.value;
        container.dispatchEvent(new CustomEvent("input"));
      };
      container.value = element.value;
      return container;
    }
  };

  const org = {
    card: (content, {title, status = 'debug'} = {}) => {
      const container = document.createElement('div');
      container.className = `org-card is-${status}`;
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
    terminal: ({header, status = 'primary'} = {}) => {
      const container = document.createElement('div');
      container.className = 'org-terminal';
      
      const head = document.createElement('div');
      head.className = 'terminal-header';
      
      ['red', 'yellow', 'green'].forEach(c => {
        const dot = document.createElement('span');
        dot.className = `terminal-dot is-${c}`;
        head.appendChild(dot);
      });
      
      if (header) {
        const title = document.createElement('span');
        title.className = 'terminal-title';
        title.style.marginLeft = '10px';
        title.innerText = header;
        head.appendChild(title);
      }
      
      const body = document.createElement('div');
      body.className = 'terminal-body';
      
      container.appendChild(head);
      container.appendChild(body);
      container.body = body;
      return container;
    }
  };

  return {
    atom, mol, org,
    // Backward Compatibility
    slider: (args) => mol.slider(args),
    toggle: (args) => mol.toggle(args),
    checkbox: (args) => mol.checkbox(args),
    text_area: (args) => mol.field({label: args.label, element: atom.textarea(args)}),
    select: (args) => mol.field({label: args.label, element: atom.select(args)}),
    card: (content, args) => org.card(content, args)
  };
})();
</script>
]]

-- Use a filter list to control execution order
return {
  {
    -- Pass 1: Transform all .dynamic Divs and mark if we found any
    Div = function(el)
      if has_class(el, "dynamic") then
        _G.has_dynamic_in_doc = true
        return transform_dynamic_div(el)
      end
    end
  },
  {
    -- Second pass: Inject theme if needed
    Pandoc = function(doc)
      if _G.has_dynamic_in_doc then
        doc.blocks:insert(pandoc.RawBlock('html', theme_js))
      end
      return doc
    end
  }
}
