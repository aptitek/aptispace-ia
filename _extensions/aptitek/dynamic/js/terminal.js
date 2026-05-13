window.ui.org.terminal = ({header, status = 'primary'} = {}) => {
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
};
