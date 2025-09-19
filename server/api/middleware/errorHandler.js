const logger = require('../utils/logger');

// 自定义错误类
class AppError extends Error {
  constructor(message, statusCode, code = null) {
    super(message);
    this.statusCode = statusCode;
    this.status = `${statusCode}`.startsWith('4') ? 'fail' : 'error';
    this.isOperational = true;
    this.code = code;

    Error.captureStackTrace(this, this.constructor);
  }
}

// 错误处理中间件
const errorHandler = (err, req, res, next) => {
  let error = { ...err };
  error.message = err.message;

  // 记录错误日志
  logger.error('API错误:', {
    message: err.message,
    stack: err.stack,
    url: req.originalUrl,
    method: req.method,
    ip: req.ip,
    userAgent: req.get('User-Agent'),
  });

  // MySQL错误处理
  if (err.code === 'ER_DUP_ENTRY') {
    const message = '数据重复，请检查输入';
    error = new AppError(message, 400, 'DUPLICATE_ENTRY');
  }

  if (err.code === 'ER_NO_REFERENCED_ROW_2') {
    const message = '引用的数据不存在';
    error = new AppError(message, 400, 'REFERENCE_NOT_FOUND');
  }

  if (err.code === 'ECONNREFUSED') {
    const message = '数据库连接失败';
    error = new AppError(message, 500, 'DATABASE_CONNECTION_ERROR');
  }

  // JWT错误处理
  if (err.name === 'JsonWebTokenError') {
    const message = '无效的token';
    error = new AppError(message, 401, 'INVALID_TOKEN');
  }

  if (err.name === 'TokenExpiredError') {
    const message = 'Token已过期';
    error = new AppError(message, 401, 'TOKEN_EXPIRED');
  }

  // Validation错误处理
  if (err.name === 'ValidationError') {
    const message = Object.values(err.errors)
      .map((val) => val.message)
      .join(', ');
    error = new AppError(message, 400, 'VALIDATION_ERROR');
  }

  // 发送错误响应
  sendErrorResponse(error, req, res);
};

// 发送错误响应
const sendErrorResponse = (err, req, res) => {
  const { statusCode = 500, message, code } = err;

  if (err.isOperational) {
    return res.status(statusCode).json({
      status: err.status || 'error',
      error: message,
      code: code || 'OPERATIONAL_ERROR',
      stack: err.stack,
      path: req.originalUrl,
      method: req.method,
      timestamp: new Date().toISOString(),
    });
  }

  // 未知错误不泄露详细信息
  res.status(500).json({
    status: 'error',
    error: '服务器内部错误',
    code: 'INTERNAL_ERROR',
    timestamp: new Date().toISOString(),
  });
};

// 404处理函数
const notFound = (req, res) => {
  res.status(404).json({
    status: 'fail',
    error: `路径 ${req.originalUrl} 不存在`,
    code: 'NOT_FOUND',
    timestamp: new Date().toISOString(),
  });
};

// 异步错误捕获包装器
const catchAsync = (fn) => {
  return (req, res, next) => {
    fn(req, res, next).catch(next);
  };
};

module.exports = {
  AppError,
  errorHandler,
  notFound,
  catchAsync,
};
