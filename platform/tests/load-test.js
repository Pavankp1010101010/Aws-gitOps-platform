import http from 'k6/http';
import { check } from 'k6';
import exec from 'k6/execution';

const suppliedBaseURL = __ENV.BASE_URL ?? '';
if (!suppliedBaseURL) {
  throw new Error('BASE_URL is required and must be an HTTP loopback URL forwarded to the private application.');
}

const loopbackURL = /^http:\/\/(?:127\.0\.0\.1|localhost|\[::1\])(?::([1-9][0-9]{0,4}))?\/?$/i;
const parsedBaseURL = loopbackURL.exec(suppliedBaseURL);
const port = parsedBaseURL && parsedBaseURL[1] ? Number(parsedBaseURL[1]) : 80;
if (!parsedBaseURL || port > 65535) {
  throw new Error('BASE_URL must be an HTTP loopback URL forwarded to the private application.');
}
const baseURL = suppliedBaseURL.replace(/\/$/, '');

export const options = {
  scenarios: {
    api_mix: {
      executor: 'constant-arrival-rate',
      rate: 5,
      timeUnit: '1s',
      duration: '5m',
      preAllocatedVUs: 5,
      maxVUs: 20,
    },
  },
  thresholds: {
    'http_req_duration{phase:load}': ['p(95)<500'],
    'http_req_failed{phase:load}': ['rate<0.01'],
    'http_reqs{phase:load}': ['count==1500'],
    dropped_iterations: ['count==0'],
    iterations: ['count>=1500'],
  },
};

export function setup() {
  const runId = Date.now().toString(36);
  const ticketIds = [];

  for (let index = 0; index < 100; index += 1) {
    const response = http.post(
      `${baseURL}/api/tickets`,
      JSON.stringify({
        title: `Stage 08 load ${runId} ${String(index + 1).padStart(3, '0')}`,
        description: 'Synthetic Stage 08 load-test data; no real user information.',
      }),
      {
        headers: { 'Content-Type': 'application/json' },
        tags: { phase: 'setup' },
        timeout: '10s',
      },
    );
    if (response.status !== 201) {
      throw new Error(`Synthetic ticket creation failed with HTTP ${response.status}.`);
    }

    const ticketId = response.json('id');
    if (!Number.isInteger(ticketId) || ticketId < 1) {
      throw new Error('Synthetic ticket creation returned an invalid ticket ID.');
    }
    ticketIds.push(ticketId);
  }

  return { ticketIds };
}

export default function ({ ticketIds }) {
  const iteration = exec.scenario.iterationInTest;
  const isDetailRequest = iteration % 2 === 1;
  const ticketId = ticketIds[iteration % ticketIds.length];
  const url = isDetailRequest
    ? `${baseURL}/api/tickets/${ticketId}`
    : `${baseURL}/api/tickets?limit=20`;
  const response = http.get(url, {
    tags: {
      phase: 'load',
      request_type: isDetailRequest ? 'detail' : 'list',
    },
    timeout: '10s',
  });

  check(response, {
    'API request returned 2xx': (result) => result.status >= 200 && result.status < 300,
  });
}
