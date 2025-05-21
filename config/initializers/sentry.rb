Sentry.init do |config|
  config.dsn = 'https://58ccc204baf6ed864eb8414200b074df@o4509362174689280.ingest.us.sentry.io/4509362396659712'
  config.breadcrumbs_logger = [:active_support_logger, :http_logger]

  # Add data like request headers and IP for users,
  # see https://docs.sentry.io/platforms/ruby/data-management/data-collected/ for more info
  config.send_default_pii = true
end 