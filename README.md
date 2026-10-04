# E-Commerce App - Flutter

## Overview

A Flutter-based e-commerce mobile application connected to a Laravel REST API.

The application provides a complete shopping flow starting from authentication and product browsing, through product details and cart management, to checkout and order management.

It also includes admin-related functionality for managing products and categories.

## Main Features

- User registration and login
- Authentication token management
- User profile
- Product browsing
- Product search
- Product sorting
- Product details
- Category browsing
- Shopping cart
- Cart quantity management
- Product selection from cart
- Checkout
- Order creation
- Order history
- Order details
- Admin product management
- Admin category management
- Product image selection and upload
- Deleted product management
- Local authentication persistence

## Application Flow

```text
Register / Login
       |
       v
     Home
       |
       +------ Categories
       |
       +------ Products
       |         |
       |         v
       |    Product Details
       |         |
       |         v
       |      Add to Cart
       |
       v
      Cart
       |
       v
    Checkout
       |
       v
     Order
       |
       v
   Order Details
```

## Authentication

The application provides registration and login screens and communicates with the backend authentication API.

After a successful registration or login, the authentication token is stored locally using `SharedPreferences`.

When the application starts, it checks whether a stored token exists and uses that information to determine whether the user should enter the authenticated application or the login screen.

```text
Login / Register
       |
       v
Laravel API
       |
       v
Authentication Token
       |
       v
SharedPreferences
       |
       v
Authenticated Application
```

The API service also stores the user's admin status locally so the application can handle admin-specific functionality.

## Home and Product Browsing

The application includes a home screen and product-related tabs for browsing the available products.

Users can:

- Browse products
- Browse categories
- Search products
- Sort products
- Open product details
- Add products to the cart

Product data is retrieved from the Laravel API.

## Categories

The application includes a categories screen for displaying available product categories.

For admin users, category management functionality is also available.

Admin operations include:

- Add category
- Update category
- Delete category

These operations are performed through the API service and connected to the Laravel backend.

## Product Details

The product details screen displays information about a selected product and provides the user with access to product-related actions.

Products can be added to the shopping cart with a selected quantity.

Product information is loaded from the backend API, including product images and pricing information.

## Shopping Cart

The cart screen provides functionality for managing products selected by the user.

Users can:

- View cart items
- Select individual items
- Select all items
- Change item quantities
- Remove items
- View selected item count
- Calculate the selected total price
- Continue to checkout

The application keeps the cart count updated through a `ValueNotifier`.

```text
Product
   |
   v
Add to Cart
   |
   v
Shopping Cart
   |
   +---- Update Quantity
   |
   +---- Remove Item
   |
   +---- Select Items
   |
   v
Checkout
```

## Checkout

The checkout screen handles the final stage before creating an order.

The application sends order information to the backend, including:

- Delivery address
- Phone number
- Payment method
- Total price
- Selected items
- Cart item IDs

After the order is successfully created, the application can retrieve the order information from the backend.

## Orders

The application includes an orders screen for displaying the user's order history.

Users can open an individual order to view its details.

The order flow is connected to the Laravel API through dedicated API methods for creating and retrieving orders.

```text
Cart
 |
 v
Checkout
 |
 v
Create Order
 |
 v
Orders
 |
 v
Order Details
```

## Profile

The application includes a profile screen connected to the backend user profile endpoint.

The profile information is retrieved from the authenticated API and the user's admin status is also updated locally.

## Admin Features

The application contains functionality intended for administrator users.

Admin-related screens include:

- Dashboard
- Product Management
- Add/Edit Product
- Categories Management

The product management functionality supports:

- Adding products
- Editing products
- Deleting products
- Restoring deleted products
- Uploading product images
- Selecting product categories

The category management functionality supports:

- Adding categories
- Updating categories
- Deleting categories

## Product Management

The add/edit product screen communicates with the backend using multipart requests.

Product data can include:

- Title
- Price
- Category
- Budget Range
- Description
- Note
- Date
- Product images

Multiple image paths can be submitted with the product request.

The application uses `image_picker` to select images from the device before sending them to the backend.

## Deleted Products

The application provides access to deleted products through the API.

Admin users can retrieve deleted products and restore a previously deleted product.

```text
Active Product
      |
      v
    Delete
      |
      v
Deleted Product
      |
      v
    Restore
      |
      v
Active Product
```

## API Integration

The application uses a dedicated `ApiService` class to centralize communication with the Laravel REST API.

The service handles API operations including:

### Authentication

```text
register()
login()
logout()
```

### User

```text
getProfile()
isAdmin()
```

### Dashboard

```text
getDashboard()
```

### Categories

```text
getCategories()
addCategory()
updateCategory()
deleteCategory()
```

### Products

```text
getProducts()
addProduct()
updateProduct()
deleteProduct()
getDeletedProducts()
restoreProduct()
```

### Cart

```text
getCart()
addToCart()
updateCartItem()
removeFromCart()
```

### Orders

```text
createOrder()
getOrders()
```

## API Communication

The application uses the `http` package for communication with the Laravel backend.

Requests can include the stored authentication token using the HTTP `Authorization` header:

```text
Authorization: Bearer <token>
```

JSON is used for most API responses, while multipart requests are used when uploading product images.

The application also handles different API response status codes and displays errors when requests fail.

## Local Storage

`SharedPreferences` is used for local application data.

The application stores:

- Authentication token
- Admin status

The token is retrieved when making authenticated API requests.

## Application Structure

The main application source code is organized under `lib/`.

```text
lib/
│
├── api_service.dart
├── main.dart
│
└── screens/
    ├── add_edit_product_screen.dart
    ├── cart_screen.dart
    ├── categories_screen.dart
    ├── checkout_screen.dart
    ├── dashboard_tab.dart
    ├── home_screen.dart
    ├── home_tab.dart
    ├── login_screen.dart
    ├── order_details_screen.dart
    ├── orders_screen.dart
    ├── product_details.dart
    ├── products_tab.dart
    ├── profile_screen.dart
    └── register_screen.dart
```

## Main Screens

### Authentication

- `login_screen.dart`
- `register_screen.dart`

Responsible for user authentication and registration.

### Home

- `home_screen.dart`
- `home_tab.dart`

Provide the main application interface and navigation into the shopping experience.

### Products

- `products_tab.dart`
- `product_details.dart`

Handle product browsing and product-specific information.

### Categories

- `categories_screen.dart`

Displays available product categories and provides category management functionality for administrators.

### Cart

- `cart_screen.dart`

Handles selected products, quantities, item selection, removal, and cart totals.

### Checkout

- `checkout_screen.dart`

Collects order information and sends the order request to the backend.

### Orders

- `orders_screen.dart`
- `order_details_screen.dart`

Display order history and individual order information.

### Profile

- `profile_screen.dart`

Displays information related to the authenticated user.

### Admin

- `dashboard_tab.dart`
- `add_edit_product_screen.dart`

Provide administrative functionality for dashboard data and product management.

## Technologies Used

| Technology | Purpose |
|---|---|
| Flutter | Mobile application framework |
| Dart | Programming language |
| HTTP | REST API communication |
| SharedPreferences | Local token and user state storage |
| Intl | Data and date formatting |
| Google Fonts | Application typography |
| Flutter SVG | SVG asset support |
| Image Picker | Product image selection |
| Flutter Test | Application testing |

## Project Architecture

The application follows a simple separation between the user interface and API communication.

```text
Flutter Screens
      |
      v
   ApiService
      |
      v
 Laravel REST API
      |
      v
   Database
```

The screens are responsible for presenting data and handling user interaction, while `ApiService` handles communication with the backend.

## Error Handling

API operations check HTTP response status codes and handle unsuccessful requests.

The application also handles common situations such as:

- Invalid login information
- Registration errors
- Failed API requests
- Server connection problems
- Invalid product operations
- Failed order creation

For authentication and registration, API validation errors returned by the backend are processed and displayed to the user.

## Development Focus

This project provided practical experience with:

- Flutter mobile development
- Dart
- REST API integration
- Laravel API consumption
- Authentication
- Token-based API requests
- SharedPreferences
- HTTP requests
- JSON handling
- Multipart requests
- Image upload
- Shopping cart logic
- Checkout flow
- Order management
- Admin functionality
- API error handling
- Local application state

## Backend Integration

The Flutter application is designed to communicate with a Laravel REST API.

The API base URL changes according to the platform:

```text
Web:
http://localhost:8000/api

Android Emulator:
http://10.0.2.2:8000/api

Other Local Platforms:
http://127.0.0.1:8000/api
```

This allows the same Flutter application to communicate with a locally running Laravel backend across different development environments.

## Project Status

The application contains the main components required for an e-commerce mobile experience, including authentication, product browsing, categories, cart management, checkout, orders, profile functionality, and administrative product/category management.

## Author

Ahmed Ezzat
