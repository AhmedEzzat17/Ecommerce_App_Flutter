import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../api_service.dart';

class CheckoutScreen extends StatefulWidget {
  final List<dynamic> cartItems;
  final double totalPrice;

  const CheckoutScreen({
    Key? key,
    required this.cartItems,
    required this.totalPrice,
  }) : super(key: key);

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  String _selectedPaymentMethod = 'card'; // 'card' or 'cod'
  
  final _cardNumberController = TextEditingController(text: '4242 4242 4242 4242');
  final _cardHolderController = TextEditingController(text: 'John Doe');
  final _cardExpiryController = TextEditingController(text: '12/28');
  final _cardCvvController = TextEditingController(text: '123');
  
  final _addressController = TextEditingController(text: '123 Gameat Al Dowal Al Arabiya St, Mohandessin, Giza');
  final _phoneController = TextEditingController(text: '+20 123 456 7890');

  bool _isLoading = false;
  bool _isSuccess = false;
  String _orderId = '';

  @override
  void initState() {
    super.initState();
    // Rebuild the card preview whenever the controllers change
    _cardNumberController.addListener(() => setState(() {}));
    _cardHolderController.addListener(() => setState(() {}));
    _cardExpiryController.addListener(() => setState(() {}));
    _cardCvvController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _cardNumberController.dispose();
    _cardHolderController.dispose();
    _cardExpiryController.dispose();
    _cardCvvController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _processPayment() async {
    if (_selectedPaymentMethod == 'card') {
      if (_cardNumberController.text.trim().isEmpty ||
          _cardHolderController.text.trim().isEmpty ||
          _cardExpiryController.text.trim().isEmpty ||
          _cardCvvController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter all credit card details'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
    }

    if (_addressController.text.trim().isEmpty ||
        _phoneController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter shipping address and phone number'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    double shippingFee = widget.totalPrice > 100 ? 0.0 : 15.0;
    double finalTotal = widget.totalPrice + shippingFee;

    final orderItems = widget.cartItems.map((item) {
      final product = item['product'] ?? {};
      return {
        'product_id': product['id'],
        'title': product['title'] ?? 'Unknown',
        'price': double.tryParse((item['price'] ?? product['price'] ?? 0).toString()) ?? 0.0,
        'quantity': item['quantity'],
      };
    }).toList();

    final cartItemIds = widget.cartItems.map<int>((item) => item['id'] as int).toList();

    try {
      final result = await ApiService.createOrder(
        address: _addressController.text.trim(),
        phone: _phoneController.text.trim(),
        paymentMethod: _selectedPaymentMethod,
        totalPrice: finalTotal,
        items: orderItems,
        cartItemIds: cartItemIds,
      );

      if (result != null && result['order'] != null) {
        // Clear the checked-out items from the cart on the server side
        for (var itemId in cartItemIds) {
          try {
            await ApiService.removeFromCart(itemId);
          } catch (_) {}
        }

        await ApiService.getCart();

        if (!mounted) return;

        setState(() {
          _isLoading = false;
          _isSuccess = true;
          _orderId = result['order']['order_number'].toString();
        });
      } else {
        throw Exception('Failed to place order');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('An error occurred during process: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isSuccess ? 'Success' : 'Checkout',
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: Directionality(
        textDirection: TextDirection.ltr,
        child: Stack(
          children: [
            _isSuccess ? _buildSuccessBody() : _buildCheckoutForm(),
            if (_isLoading) _buildLoadingOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckoutForm() {
    double shippingFee = widget.totalPrice > 100 ? 0.0 : 15.0;
    double finalTotal = widget.totalPrice + shippingFee;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Progress Steps
          _buildProgressSteps(),
          const SizedBox(height: 24),

          // Section 1: Order Summary
          _buildSectionHeader('Order Summary', Icons.shopping_bag_outlined),
          const SizedBox(height: 10),
          _buildOrderSummaryCard(),
          const SizedBox(height: 24),

          // Section 2: Delivery Details
          _buildSectionHeader('Delivery Details', Icons.local_shipping_outlined),
          const SizedBox(height: 10),
          _buildShippingAddressCard(),
          const SizedBox(height: 24),

          // Section 3: Payment Method
          _buildSectionHeader('Payment Method', Icons.payment_outlined),
          const SizedBox(height: 10),
          _buildPaymentMethodSelector(),
          const SizedBox(height: 24),

          // Credit Card Fields & Card Widget
          if (_selectedPaymentMethod == 'card') ...[
            MockCreditCard(
              cardNumber: _cardNumberController.text,
              cardHolder: _cardHolderController.text,
              cardExpiry: _cardExpiryController.text,
              cardCvv: _cardCvvController.text,
            ),
            const SizedBox(height: 20),
            _buildCreditCardFields(),
            const SizedBox(height: 24),
          ],

          // Price Breakdown
          _buildPriceBreakdown(shippingFee, finalTotal),
          const SizedBox(height: 32),

          // Checkout Button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: FilledButton(
              onPressed: _processPayment,
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                _selectedPaymentMethod == 'card' 
                    ? 'Pay & Confirm Order (\$${finalTotal.toStringAsFixed(2)})'
                    : 'Confirm Order - Cash on Delivery (\$${finalTotal.toStringAsFixed(2)})',
                style: GoogleFonts.cairo(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildProgressSteps() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildStepCircle('1', 'Cart', true),
        _buildStepLine(true),
        _buildStepCircle('2', 'Payment', true, isCurrent: true),
        _buildStepLine(false),
        _buildStepCircle('3', 'Confirmation', false),
      ],
    );
  }

  Widget _buildStepCircle(String number, String label, bool isCompleted, {bool isCurrent = false}) {
    Color primaryColor = Theme.of(context).colorScheme.primary;
    return Column(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isCurrent 
                ? primaryColor 
                : (isCompleted ? primaryColor.withOpacity(0.2) : Colors.grey.shade200),
            border: isCurrent ? null : Border.all(color: isCompleted ? primaryColor : Colors.grey.shade400, width: 1.5),
          ),
          child: Center(
            child: isCurrent 
                ? Text(number, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))
                : (isCompleted 
                    ? Icon(Icons.check, color: primaryColor, size: 18) 
                    : Text(number, style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.bold))),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: GoogleFonts.cairo(
            fontSize: 11,
            fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
            color: isCurrent ? primaryColor : (isCompleted ? Colors.black87 : Colors.grey),
          ),
        ),
      ],
    );
  }

  Widget _buildStepLine(bool isCompleted) {
    return Container(
      width: 50,
      height: 2,
      margin: const EdgeInsets.only(bottom: 20),
      color: isCompleted ? Theme.of(context).colorScheme.primary : Colors.grey.shade300,
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary, size: 22),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.cairo(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildOrderSummaryCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: widget.cartItems.map((item) {
            final product = item['product'] ?? {};
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      product['title'] ?? 'Unknown Product',
                      style: GoogleFonts.cairo(fontSize: 14, color: Colors.black87),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    '${item['quantity']} × \$${item['price'] ?? product['price']}',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                    textDirection: TextDirection.ltr,
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildShippingAddressCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _addressController,
              decoration: InputDecoration(
                labelText: 'Shipping Address',
                labelStyle: GoogleFonts.cairo(fontSize: 14),
                prefixIcon: const Icon(Icons.location_on_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'Phone Number',
                labelStyle: GoogleFonts.cairo(fontSize: 14),
                prefixIcon: const Icon(Icons.phone_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodSelector() {
    Color primaryColor = Theme.of(context).colorScheme.primary;
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _selectedPaymentMethod = 'card'),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: _selectedPaymentMethod == 'card' ? primaryColor.withOpacity(0.08) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _selectedPaymentMethod == 'card' ? primaryColor : Colors.grey.shade300,
                  width: _selectedPaymentMethod == 'card' ? 2 : 1,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.credit_card_outlined,
                    color: _selectedPaymentMethod == 'card' ? primaryColor : Colors.grey,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Credit Card',
                    style: GoogleFonts.cairo(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: _selectedPaymentMethod == 'card' ? primaryColor : Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _selectedPaymentMethod = 'cod'),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: _selectedPaymentMethod == 'cod' ? primaryColor.withOpacity(0.08) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _selectedPaymentMethod == 'cod' ? primaryColor : Colors.grey.shade300,
                  width: _selectedPaymentMethod == 'cod' ? 2 : 1,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.handshake_outlined,
                    color: _selectedPaymentMethod == 'cod' ? primaryColor : Colors.grey,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Cash on Delivery',
                    style: GoogleFonts.cairo(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: _selectedPaymentMethod == 'cod' ? primaryColor : Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCreditCardFields() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _cardNumberController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Card Number',
                labelStyle: GoogleFonts.cairo(fontSize: 14),
                prefixIcon: const Icon(Icons.payment),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _cardHolderController,
              decoration: InputDecoration(
                labelText: 'Cardholder Name',
                labelStyle: GoogleFonts.cairo(fontSize: 14),
                prefixIcon: const Icon(Icons.person_outline),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _cardExpiryController,
                    decoration: InputDecoration(
                      labelText: 'Expiry Date (MM/YY)',
                      labelStyle: GoogleFonts.cairo(fontSize: 13),
                      prefixIcon: const Icon(Icons.date_range_outlined),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _cardCvvController,
                    keyboardType: TextInputType.number,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'CVV Code',
                      labelStyle: GoogleFonts.cairo(fontSize: 13),
                      prefixIcon: const Icon(Icons.lock_outline),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceBreakdown(double shippingFee, double finalTotal) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Subtotal', style: GoogleFonts.cairo(color: Colors.grey.shade600)),
              Text('\$${widget.totalPrice.toStringAsFixed(2)}', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Shipping Fee', style: GoogleFonts.cairo(color: Colors.grey.shade600)),
              Text(
                shippingFee == 0.0 ? 'Free Shipping' : '\$${shippingFee.toStringAsFixed(2)}',
                style: GoogleFonts.cairo(
                  color: shippingFee == 0.0 ? Colors.green : Colors.black87,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total Amount', style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.bold)),
              Text(
                '\$${finalTotal.toStringAsFixed(2)}',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.55),
        child: Center(
          child: Card(
            margin: const EdgeInsets.all(32),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(
                    color: Theme.of(context).colorScheme.primary,
                    strokeWidth: 4,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Processing Payment...',
                    style: GoogleFonts.cairo(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Please do not close the app or navigate back.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.cairo(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessBody() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const AnimatedCheckmark(),
            const SizedBox(height: 28),
            Text(
              'Order Placed Successfully!',
              style: GoogleFonts.cairo(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.green.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your order has been received and mock payment was confirmed.',
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(
                fontSize: 15,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 24),

            // Order details card
            Card(
              elevation: 0,
              color: Colors.grey.shade50,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Order ID:', style: GoogleFonts.cairo(color: Colors.grey.shade600)),
                        Text(
                          _orderId,
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Payment Method:', style: GoogleFonts.cairo(color: Colors.grey.shade600)),
                        Text(
                          _selectedPaymentMethod == 'card' ? 'Credit Card' : 'Cash on Delivery',
                          style: GoogleFonts.cairo(
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Address:', style: GoogleFonts.cairo(color: Colors.grey.shade600)),
                        Expanded(
                          child: Text(
                            _addressController.text,
                            textAlign: TextAlign.left,
                            style: GoogleFonts.cairo(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 36),

            // Continue Shopping Button
            SizedBox(
              width: double.infinity,
              height: 54,
              child: FilledButton.icon(
                onPressed: () {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                icon: const Icon(Icons.shopping_bag_outlined),
                label: Text(
                  'Continue Shopping',
                  style: GoogleFonts.cairo(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Premium Interactive Mock Credit Card Widget
class MockCreditCard extends StatelessWidget {
  final String cardNumber;
  final String cardHolder;
  final String cardExpiry;
  final String cardCvv;

  const MockCreditCard({
    Key? key,
    required this.cardNumber,
    required this.cardHolder,
    required this.cardExpiry,
    required this.cardCvv,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF0F2027),
            Color(0xFF203A43),
            Color(0xFF2C5364),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Credit Card',
                style: GoogleFonts.outfit(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Icon(Icons.credit_card, color: Colors.white, size: 28),
            ],
          ),
          const SizedBox(height: 10),
          // Card Number
          Text(
            cardNumber.isEmpty ? '•••• •••• •••• ••••' : cardNumber,
            style: GoogleFonts.shareTechMono(
              color: Colors.white,
              fontSize: 22,
              letterSpacing: 2.0,
            ),
            textDirection: TextDirection.ltr,
          ),
          const SizedBox(height: 10),
          // Holder & Expiry
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CARD HOLDER',
                      style: GoogleFonts.outfit(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      cardHolder.isEmpty ? 'CARD HOLDER NAME' : cardHolder.toUpperCase(),
                      style: GoogleFonts.cairo(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'EXPIRES',
                    style: GoogleFonts.outfit(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    cardExpiry.isEmpty ? 'MM/YY' : cardExpiry,
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Animated Success Checkmark Widget
class AnimatedCheckmark extends StatefulWidget {
  const AnimatedCheckmark({Key? key}) : super(key: key);

  @override
  State<AnimatedCheckmark> createState() => _AnimatedCheckmarkState();
}

class _AnimatedCheckmarkState extends State<AnimatedCheckmark>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _checkAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
      ),
    );

    _checkAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.4, 1.0, curve: Curves.easeInOutBack),
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.green.shade100,
              border: Border.all(color: Colors.green.shade600, width: 4),
            ),
            child: Center(
              child: Transform.scale(
                scale: _checkAnimation.value,
                child: Icon(
                  Icons.check_circle,
                  color: Colors.green.shade600,
                  size: 80,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
