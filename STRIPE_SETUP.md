# Stripe Integration Setup

## 1. Get Your Stripe Keys

1. Go to [Stripe Dashboard](https://dashboard.stripe.com/)
2. Sign up or log in to your account
3. Navigate to Developers > API Keys
4. Copy your Publishable key and Secret key (use test keys for development)

## 2. Set Environment Variables

Create a `.env` file in your project root and add:

```
STRIPE_PUBLISHABLE_KEY=pk_test_your_publishable_key_here
STRIPE_SECRET_KEY=sk_test_your_secret_key_here
STRIPE_WEBHOOK_SECRET=whsec_your_webhook_secret_here

# Your existing product ID (already configured as default)
STRIPE_PRODUCT_ID=prod_SQpFlqjVkSaESa

# Optional: If you have a pre-created price, use it instead of dynamic pricing
# STRIPE_PRICE_ID=price_your_price_id_here
```

**Note**: Your product ID `prod_SQpFlqjVkSaESa` is already configured as the default. You can override it with the environment variable if needed.

## 3. Price Configuration Options

You have two options for pricing:

### Option A: Dynamic Pricing (Current Setup)
- Uses your existing product ID: `prod_SQpFlqjVkSaESa`
- Creates the $9/month price dynamically during checkout
- This is what's currently configured and working

### Option B: Pre-created Price (Recommended for Production)
1. In Stripe Dashboard, go to Products
2. Find your product (`prod_SQpFlqjVkSaESa`)
3. Create a new price: $9.00/month recurring
4. Copy the price ID (starts with `price_`)
5. Add it to your `.env` file as `STRIPE_PRICE_ID=price_your_id_here`

## 4. Setup Webhook (for production)

1. In Stripe Dashboard, go to Developers > Webhooks
2. Click "Add endpoint"
3. Set endpoint URL to: `https://yourdomain.com/webhooks/stripe`
4. Select these events:
   - `checkout.session.completed`
   - `invoice.payment_succeeded`
   - `customer.subscription.deleted`
5. Copy the webhook signing secret to your environment variables

## 5. Test the Integration

1. Start your Rails server: `rails server`
2. Log in to your app
3. Click the "Upgrade ($9/month)" button
4. Use Stripe's test card: `4242 4242 4242 4242`
5. Complete the checkout process

## Features Included

- **Monthly Subscription**: $9/month recurring billing
- **Stripe Checkout**: Secure hosted checkout page
- **User Status Tracking**: Active/canceled subscription status
- **Webhook Handling**: Automatic subscription updates
- **UI Integration**: Upgrade button for non-subscribers
- **Success/Cancel Pages**: Proper user feedback
- **Flexible Pricing**: Works with your existing product or pre-created prices

## Usage

- Non-subscribed users see an "Upgrade ($9/month)" button in the navigation
- Clicking it redirects to Stripe Checkout
- After successful payment, users are redirected back with confirmation
- Subscribed users see a "✓ Subscribed" indicator instead
- Webhooks keep subscription status in sync automatically

## Testing

Use these test cards in Stripe's test mode:
- Success: `4242 4242 4242 4242`
- Declined: `4000 0000 0000 0002`
- Requires authentication: `4000 0025 0000 3155` 