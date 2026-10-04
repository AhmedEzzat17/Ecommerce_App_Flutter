# E-Commerce App - Flutter

A Flutter-based e-commerce mobile application connected to a Laravel REST API.

## Overview

The application allows users to browse products, manage their cart, place orders, and manage their account.

It also includes admin features for managing products and categories.

## Main Features

- User Registration & Login
- Token-based Authentication
- Product Browsing, Search & Sorting
- Categories Management
- Product Details
- Shopping Cart
- Checkout & Order Creation
- Orders & Order Details
- User Profile
- Admin Product Management
- Admin Category Management
- Product Image Upload
- Deleted Product Restore

## Application Flow

```text
Login / Register
       ↓
     Home
       ↓
Products → Product Details
       ↓
     Cart
       ↓
   Checkout
       ↓
     Orders
```

## API Integration

The app communicates with a Laravel REST API using HTTP requests and Bearer Token authentication.
Main API operations include:
- Authentication
- Products
- Categories
- Cart
- Orders
- User Profile
- Admin Management

## Local Storage

SharedPreferences is used to store authentication data and maintain the user's login state.

## Project Structure

lib/
├── screens/
│   ├── home_screen.dart
│   ├── login_screen.dart
│   ├── register_screen.dart
│   ├── products_tab.dart
│   ├── product_details.dart
│   ├── cart_screen.dart
│   ├── checkout_screen.dart
│   ├── orders_screen.dart
│   ├── order_details_screen.dart
│   ├── profile_screen.dart
│   └── ...
├── api_service.dart
└── main.dart

## Technologies

- Flutter
- Dart
- REST API
- HTTP
- SharedPreferences
- Provider
- Riverpod
- Google Fonts
- Flutter SVG
- Image Picker

## Architecture

Flutter App
     ↓
ApiService
     ↓
Laravel REST API
     ↓
Database

## Project Focus

This project demonstrates building a complete Flutter e-commerce application, integrating REST APIs, handling authentication, managing application data, and implementing user and admin functionality.

## Author
Ahmed Ezzat
