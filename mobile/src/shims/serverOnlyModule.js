const noop = () => undefined;

const span = {
  addEvent() {
    return this;
  },
  end: noop,
  isRecording: () => false,
  recordException() {
    return this;
  },
  setAttribute() {
    return this;
  },
  setAttributes() {
    return this;
  },
  setStatus() {
    return this;
  },
  updateName() {
    return this;
  },
};

const tracer = {
  startActiveSpan(...args) {
    const callback = args.find((arg) => typeof arg === "function");
    return callback ? callback(span) : span;
  },
  startSpan: () => span,
};

const meter = {
  createCounter: () => ({ add: noop }),
  createHistogram: () => ({ record: noop }),
  createObservableGauge: () => ({ addCallback: noop, removeCallback: noop }),
  createUpDownCounter: () => ({ add: noop }),
};

const api = {
  SpanKind: {
    INTERNAL: 0,
    SERVER: 1,
    CLIENT: 2,
    PRODUCER: 3,
    CONSUMER: 4,
  },
  SpanStatusCode: {
    UNSET: 0,
    OK: 1,
    ERROR: 2,
  },
  context: {
    active: () => ({}),
    bind: (_context, target) => target,
    with: (_context, fn, thisArg, ...args) => fn.apply(thisArg, args),
  },
  default: {},
  diag: {
    debug: noop,
    disable: noop,
    error: noop,
    info: noop,
    setLogger: noop,
    warn: noop,
  },
  isWrapped: () => false,
  metrics: {
    getMeter: () => meter,
  },
  propagation: {
    extract: (context) => context,
    fields: () => [],
    inject: noop,
  },
  register: noop,
  registerOTel: noop,
  safeExecuteInTheMiddle: (fn, onFinish) => {
    try {
      const result = fn();
      if (onFinish) {
        onFinish();
      }
      return result;
    } catch (error) {
      if (onFinish) {
        onFinish(error);
      }
      throw error;
    }
  },
  trace: {
    getActiveSpan: () => undefined,
    getSpan: () => undefined,
    getTracer: () => tracer,
    setSpan: (context) => context,
    setSpanContext: (context) => context,
  },
};

module.exports = new Proxy(api, {
  get(target, property) {
    if (property === "__esModule") {
      return true;
    }

    if (property in target) {
      return target[property];
    }

    return noop;
  },
});
