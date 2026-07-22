function errorHandler(err, req, res, next) {
  console.error('Error:', err.message);
  if (res.headersSent) return next(err);

  if (err.code === '23505') {
    return res.status(409).json({ status: 'error', message: 'Duplicate entry — resource already exists', detail: err.detail });
  }
  if (err.code === '23503') {
    return res.status(400).json({ status: 'error', message: 'Referenced resource not found', detail: err.detail });
  }
  if (err.code === '23502') {
    return res.status(400).json({ status: 'error', message: 'Missing required field', detail: err.detail });
  }
  if (err.code === '22P02') {
    return res.status(400).json({ status: 'error', message: 'Invalid input format', detail: err.detail });
  }
  if (err.code === '42703') {
    return res.status(400).json({ status: 'error', message: 'Unknown column referenced', detail: err.detail });
  }

  const status = err.status || err.statusCode || 500;
  res.status(status).json({
    status: 'error',
    message: err.message || 'Internal server error',
    ...(process.env.NODE_ENV !== 'production' && { stack: err.stack }),
  });
}

function notFoundHandler(req, res) {
  res.status(404).json({ status: 'error', message: `Route not found: ${req.method} ${req.originalUrl}` });
}

function validateBody(requiredFields) {
  return (req, res, next) => {
    const missing = requiredFields.filter((f) => req.body[f] === undefined || req.body[f] === null);
    if (missing.length > 0) {
      return res.status(400).json({ status: 'error', message: `Missing required fields: ${missing.join(', ')}` });
    }
    next();
  };
}

function asyncHandler(fn) {
  return (req, res, next) => Promise.resolve(fn(req, res, next)).catch(next);
}

module.exports = { errorHandler, notFoundHandler, validateBody, asyncHandler };
