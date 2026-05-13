window.ui.mol = {
  slider: ({label, labels, value = 0, min = 0, max = 3, step = 1, state}) => {
    const container = document.createElement('div');
    container.className = 'mol-slider';
    // Use explicit state if provided, otherwise fallback to value for backward compatibility
    const colorState = state !== undefined ? state : value;
    container.setAttribute('data-state', colorState);

    const header = document.createElement('div');
    header.className = 'slider-header';

    const labelEl = window.ui.atom.label(label);
    const badgeEl = window.ui.atom.badge(labels ? labels[value] : value);

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
  toggle: ({label, options, value, states, layout = 'horizontal'}) => {
    const container = document.createElement('div');
    container.className = `mol-toggle ${layout === 'horizontal' ? 'is-horizontal' : ''}`;

    if (label) container.appendChild(window.ui.atom.label(label));

    const group = document.createElement('div');
    group.className = 'toggle-group';

    const isObjectOptions = !Array.isArray(options);
    const keys = isObjectOptions ? Object.keys(options) : options;

    keys.forEach(key => {
      const displayValue = isObjectOptions ? options[key] : key;
      const btn = document.createElement('button');
      btn.className = `toggle-option ${key === value ? 'active' : ''}`;

      // Semantic states
      if (states && states[key]) {
        btn.setAttribute('data-state', states[key]);
      }

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
    if (label) container.appendChild(window.ui.atom.label(label));
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
