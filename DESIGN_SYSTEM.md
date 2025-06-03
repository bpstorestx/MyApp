# FloorPlan Pro Design System

## Overview

This document outlines the organized design and component structure for FloorPlan Pro. The system has been refactored from inline styles to a modular, maintainable design system.

## File Structure

```
app/
├── assets/
│   ├── stylesheets/
│   │   ├── application.css      # Main manifest file
│   │   ├── base.css            # Base styles, variables, utilities
│   │   ├── layout.css          # Layout components (header, footer, containers)
│   │   ├── components.css      # Reusable UI components
│   │   └── pages.css           # Page-specific styles
│   └── javascripts/
│       └── components.js       # Interactive component behaviors
└── views/
    ├── layouts/
    │   └── application.html.erb # Clean main layout
    └── shared/
        ├── _header.html.erb    # Reusable header component
        └── _footer.html.erb    # Reusable footer component
```

## Design Tokens (CSS Variables)

Located in `base.css`, these tokens ensure consistency across the application:

### Colors
- `--primary-color: #4285f4` - Main brand color (Google Blue)
- `--secondary-color: #28a745` - Success/accent color
- `--danger-color: #dc3545` - Error/warning color
- `--light-color: #f8f9fa` - Light backgrounds
- `--dark-color: #333` - Text and dark elements

### Typography
- `--font-family-base: system-ui, -apple-system, "Segoe UI", Roboto, sans-serif`
- `--font-size-base: 1rem`
- `--line-height-base: 1.5`

### Spacing
- `--spacing-xs: 0.25rem` (4px)
- `--spacing-sm: 0.5rem` (8px)
- `--spacing-md: 1rem` (16px)
- `--spacing-lg: 1.5rem` (24px)
- `--spacing-xl: 2rem` (32px)
- `--spacing-xxl: 3rem` (48px)

## Component Classes

### Buttons
```html
<!-- Primary button -->
<button class="btn btn-primary">Primary Action</button>

<!-- Secondary button -->
<button class="btn btn-secondary">Secondary Action</button>

<!-- Outlined button -->
<button class="btn btn-outline">Outlined</button>

<!-- Size variations -->
<button class="btn btn-primary btn-sm">Small</button>
<button class="btn btn-primary btn-lg">Large</button>
<button class="btn btn-primary btn-block">Full Width</button>
```

### Forms
```html
<div class="form-group">
  <label class="form-label">Email</label>
  <input type="email" class="form-control" required>
  <div class="form-text">Help text goes here</div>
</div>
```

### Cards
```html
<div class="card">
  <div class="card-header">
    <h3 class="card-title">Card Title</h3>
  </div>
  <div class="card-body">
    <p class="card-text">Card content goes here.</p>
  </div>
  <div class="card-footer">
    <button class="btn btn-primary">Action</button>
  </div>
</div>
```

### Alerts
```html
<div class="alert alert-success">Success message</div>
<div class="alert alert-danger">Error message</div>
<div class="alert alert-warning">Warning message</div>
<div class="alert alert-info">Info message</div>
```

### Badges
```html
<span class="badge badge-primary">Primary</span>
<span class="badge badge-success">Success</span>
<span class="badge badge-danger">Danger</span>
```

## Layout Components

### Header (`app/views/shared/_header.html.erb`)
- Responsive navigation with mobile hamburger menu
- User authentication state handling
- Flash message display
- Accessibility features (ARIA labels, keyboard navigation)

### Footer (`app/views/shared/_footer.html.erb`)
- Company information
- Navigation links
- Legal and support links
- Social media links
- Responsive grid layout

### Main Layout (`app/views/layouts/application.html.erb`)
- Clean HTML5 semantic structure
- SEO-optimized meta tags
- Proper asset loading
- Responsive design setup

## Page-Specific Styles

### Welcome Page
- Hero section with gradient background
- Feature cards with hover effects
- Call-to-action buttons
- Responsive grid layouts

### Authentication Pages
- Centered form containers
- Consistent form styling
- Error message handling
- Responsive design

### Floorplan Pages
- Grid layouts for floorplan cards
- Status badges and indicators
- Image handling and placeholders
- Empty state designs

### Account Page
- Usage tracking components
- Subscription status displays
- Progress bars and statistics
- Action buttons and forms

## Interactive Components (JavaScript)

### Mobile Navigation
- Hamburger menu toggle
- Click outside to close
- Keyboard navigation (Escape key)
- Accessibility attributes

### Flash Messages
- Auto-dismiss for success messages (5 seconds)
- Manual close buttons
- Smooth animations
- Accessible close buttons

### Form Validation
- Real-time field validation
- Error message display
- Visual feedback (red borders)
- Email format validation
- Password confirmation matching

### Dropdowns
- Click to toggle
- Click outside to close
- Keyboard navigation
- Multiple dropdown support

### Modals
- Backdrop click to close
- Keyboard navigation (Escape key)
- Focus management
- Body scroll prevention

## Responsive Design

The design system uses a mobile-first approach with these breakpoints:

- **Mobile**: < 768px
- **Tablet**: 768px - 1200px  
- **Desktop**: > 1200px

### Key Responsive Features
- Mobile hamburger navigation
- Flexible grid layouts
- Responsive typography
- Touch-friendly interactive elements
- Optimized spacing for different screen sizes

## Accessibility Features

- Semantic HTML5 elements
- ARIA labels and attributes
- Keyboard navigation support
- Focus management
- Screen reader support
- High contrast ratios
- Touch targets ≥ 44px

## Usage Guidelines

### Adding New Components
1. Define styles in `components.css`
2. Use CSS variables for consistency
3. Follow BEM naming convention when appropriate
4. Add responsive styles
5. Include accessibility features

### Adding New Pages
1. Page-specific styles go in `pages.css`
2. Use existing component classes
3. Add proper `content_for :title` and `:description`
4. Follow responsive design patterns

### Color Usage
- Use CSS variables for all colors
- Primary color for main actions and links
- Secondary color for success states
- Danger color for errors and destructive actions
- Maintain WCAG AA contrast ratios

### Typography
- Use relative units (rem, em) for scalability
- Maintain consistent line heights
- Use the design system's font stack
- Follow hierarchical heading structure

## Browser Support

- Chrome 90+
- Firefox 88+
- Safari 14+
- Edge 90+

## Performance Considerations

- CSS is organized for efficient caching
- JavaScript is modular and only loads what's needed
- Images use responsive loading
- Minimal external dependencies

## Maintenance

- CSS variables make theme changes easy
- Modular structure allows for easy updates
- Components are reusable across pages
- Clear separation of concerns

This design system provides a solid foundation for scaling the FloorPlan Pro application while maintaining consistency and performance. 