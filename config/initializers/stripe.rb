require 'stripe'

Rails.application.configure do
  config.stripe = {
    :publishable_key => ENV['STRIPE_PUBLISHABLE_KEY'] || 'pk_test_replace_with_your_actual_key',
    :secret_key      => ENV['STRIPE_SECRET_KEY'] || 'sk_test_replace_with_your_actual_key',
    :product_id      => ENV['STRIPE_PRODUCT_ID'] || 'prod_SQpFlqjVkSaESa',
    :price_id        => ENV['STRIPE_PRICE_ID'] || 'price_1RVxbTKjVjGMkvIK2WNTb1CF'
  }

  Stripe.api_key = config.stripe[:secret_key]
end 