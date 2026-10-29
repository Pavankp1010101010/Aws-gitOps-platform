const $ = selector => document.querySelector(selector);
let selectedId;
let offset = 0;
const pageSize = 20;
const labels = { open: 'Open', in_progress: 'In Progress', resolved: 'Resolved' };

function message(text, error = false) {
  $('#message').textContent = text;
  $('#message').className = error ? 'error' : '';
}
async function api(path, options = {}) {
  const response = await fetch(path, {
    ...options, headers: { 'Content-Type': 'application/json', ...options.headers },
  });
  const data = await response.json();
  if (!response.ok) throw new Error(data.error ?? 'Request failed.');
  return data;
}
function values(form) { return Object.fromEntries(new FormData(form)); }
async function loadTickets() {
  const query = new URLSearchParams({ limit: String(pageSize), offset: String(offset) });
  for (const [key, value] of Object.entries(values($('#filter-form')))) if (value) query.set(key, value);
  const data = await api(`/api/tickets?${query}`);
  const list = $('#ticket-list');
  list.replaceChildren();
  if (!data.tickets.length) {
    const item = document.createElement('li');
    item.textContent = 'No tickets on this page.';
    list.append(item);
  }
  for (const ticket of data.tickets) {
    const item = document.createElement('li');
    const button = document.createElement('button');
    button.className = 'ticket-link';
    button.textContent = `#${ticket.id} ${ticket.title}`;
    button.addEventListener('click', () => openTicket(ticket.id).catch(error => message(error.message, true)));
    const meta = document.createElement('div');
    meta.className = 'meta';
    meta.textContent = `${labels[ticket.status]} / ${ticket.priority} / ${ticket.assignee || 'Unassigned'}`;
    item.append(button, meta);
    list.append(item);
  }
  $('#previous').disabled = offset === 0;
  $('#next').disabled = data.tickets.length < pageSize;
  $('#page-info').textContent = `Page ${offset / pageSize + 1}`;
}
async function openTicket(id) {
  const ticket = await api(`/api/tickets/${id}`);
  selectedId = id;
  $('#detail').hidden = false;
  $('#detail-heading').textContent = `#${ticket.id} ${ticket.title}`;
  $('#ticket-description').textContent = ticket.description;
  $('#ticket-dates').textContent = `Created ${new Date(ticket.created_at).toLocaleString()} / Updated ${new Date(ticket.updated_at).toLocaleString()}`;
  for (const name of ['status', 'priority', 'assignee']) $('#update-form').elements[name].value = ticket[name];
  $('#comments').replaceChildren();
  for (const comment of ticket.comments) {
    const item = document.createElement('li');
    item.textContent = `${new Date(comment.created_at).toLocaleString()} - ${comment.body}`;
    $('#comments').append(item);
  }
}
function submit(selector, handler) {
  $(selector).addEventListener('submit', async event => {
    event.preventDefault();
    const button = event.currentTarget.querySelector('button');
    button.disabled = true;
    try { await handler(event.currentTarget); }
    catch (error) { message(error.message, true); }
    finally { button.disabled = false; }
  });
}
submit('#create-form', async form => {
  const ticket = await api('/api/tickets', { method: 'POST', body: JSON.stringify(values(form)) });
  form.reset();
  $('#filter-form').reset();
  offset = 0;
  await loadTickets();
  await openTicket(ticket.id);
  message('Ticket created.');
});
submit('#filter-form', async () => { offset = 0; await loadTickets(); message('Filters applied.'); });
submit('#update-form', async form => {
  await api(`/api/tickets/${selectedId}`, { method: 'PATCH', body: JSON.stringify(values(form)) });
  await openTicket(selectedId);
  await loadTickets();
  message('Ticket updated.');
});
submit('#comment-form', async form => {
  await api(`/api/tickets/${selectedId}/comments`, { method: 'POST', body: JSON.stringify(values(form)) });
  form.reset();
  await openTicket(selectedId);
  message('Comment added.');
});
for (const [selector, delta] of [['#previous', -pageSize], ['#next', pageSize]]) {
  $(selector).addEventListener('click', async () => {
    const previous = offset;
    offset = Math.max(0, offset + delta);
    try { await loadTickets(); } catch (error) { offset = previous; message(error.message, true); }
  });
}
Promise.all([loadTickets(), api('/api/version').then(data => { $('#version').textContent = `Version: ${data.version}`; })])
  .catch(error => message(error.message, true));
