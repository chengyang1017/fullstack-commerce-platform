// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Shopping App';

  @override
  String get welcomeBack => 'Welcome back';

  @override
  String get loginSubtitle => 'Sign in to view your cart and orders';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get enterEmail => 'Please enter your email';

  @override
  String get invalidEmail => 'Please enter a valid email address';

  @override
  String get enterPassword => 'Please enter your password';

  @override
  String get login => 'Sign in';

  @override
  String get loginFailed => 'Sign in failed. Please try again later.';

  @override
  String get noAccountRegister => 'Don\'t have an account? Create one';

  @override
  String get createAccount => 'Create account';

  @override
  String get registerCustomerAccount => 'Create your customer account';

  @override
  String get username => 'Username';

  @override
  String get invalidUsernameLength =>
      'Username must be between 2 and 60 characters';

  @override
  String get passwordMinimumLength =>
      'Password must contain at least 8 characters';

  @override
  String get confirmPassword => 'Confirm password';

  @override
  String get passwordMismatch => 'Passwords do not match';

  @override
  String get registerAndLogin => 'Create account and sign in';

  @override
  String get registerFailed => 'Registration failed. Please try again later.';

  @override
  String get account => 'Account';

  @override
  String get unknownUser => 'Unknown user';

  @override
  String get myOrders => 'My orders';

  @override
  String get viewOrderHistory => 'View order history';

  @override
  String orderCount(int count) {
    return '$count orders';
  }

  @override
  String get appearance => 'Appearance';

  @override
  String get followSystem => 'Follow system';

  @override
  String get light => 'Light';

  @override
  String get dark => 'Dark';

  @override
  String get followSystemThemeDescription =>
      'Automatically match your device appearance';

  @override
  String get lightThemeDescription => 'Always use light appearance';

  @override
  String get darkThemeDescription => 'Always use dark appearance';

  @override
  String get language => 'Language';

  @override
  String get followSystemLanguage => 'Follow system';

  @override
  String get chinese => 'Chinese';

  @override
  String get english => 'English';

  @override
  String get followSystemLanguageDescription => 'Use your device language';

  @override
  String get chineseDescription => 'Use Chinese';

  @override
  String get englishDescription => 'Use the English interface';

  @override
  String get logout => 'Sign out';

  @override
  String get home => 'Home';

  @override
  String get me => 'Me';

  @override
  String get myAccount => 'My account';

  @override
  String get searchProductsBrands => 'Search products and brands';

  @override
  String get categoryPhone => 'Phones';

  @override
  String get categoryComputer => 'Computers';

  @override
  String get categoryCamera => 'Cameras';

  @override
  String get categoryAudio => 'Audio';

  @override
  String get categoryGaming => 'Gaming';

  @override
  String get categoryAccessory => 'Accessories';

  @override
  String get categoryHomeAppliance => 'Home appliances';

  @override
  String get categoryAll => 'All';

  @override
  String get techWeek => 'TECH WEEK';

  @override
  String get bannerDiscount => 'Up to 40% off';

  @override
  String get bannerTechDeal => 'Limited-time deals on selected tech';

  @override
  String get dailyDeals => 'Daily deals';

  @override
  String get newArrivals => 'New arrivals';

  @override
  String get bestSellers => 'Best sellers';

  @override
  String get coupons => 'Coupons';

  @override
  String get productCategories => 'Product categories';

  @override
  String get viewAll => 'View all';

  @override
  String get allProducts => 'All products';

  @override
  String get hotProducts => 'Best sellers';

  @override
  String get more => 'More';

  @override
  String get memberExclusive => 'Member exclusive';

  @override
  String get joinMemberDiscount => 'Join to enjoy more discounts';

  @override
  String get latestProducts => 'Latest products';

  @override
  String get scannerComingSoon => 'Scanner is not available yet';

  @override
  String get searchComingSoon => 'Search is not available yet';

  @override
  String soldCount(int count) {
    return 'Sold $count';
  }

  @override
  String soldAndStock(int sold, int stock) {
    return 'Sold $sold · Stock $stock';
  }

  @override
  String cartTitle(int count) {
    return 'Cart ($count)';
  }

  @override
  String get clear => 'Clear';

  @override
  String get cartEmpty => 'Your cart is empty';

  @override
  String get cartLoadFailed => 'Failed to load cart';

  @override
  String get reload => 'Reload';

  @override
  String get total => 'Total';

  @override
  String checkoutCount(int count) {
    return 'Checkout ($count)';
  }

  @override
  String get clearCart => 'Clear cart';

  @override
  String get clearCartConfirmation => 'Remove all items from your cart?';

  @override
  String get cancel => 'Cancel';

  @override
  String get cartActionFailed => 'Cart operation failed';

  @override
  String cartItemSubtotal(String amount) {
    return 'Subtotal: RM $amount';
  }

  @override
  String get delete => 'Delete';

  @override
  String get confirmOrder => 'Confirm order';

  @override
  String get shippingAddress => 'Shipping address';

  @override
  String get add => 'Add';

  @override
  String get addShippingAddress => 'Add shipping address';

  @override
  String get shippingAddressRequired =>
      'A shipping address is required before checkout';

  @override
  String get products => 'Products';

  @override
  String get shippingMethod => 'Shipping method';

  @override
  String get standardShipping => 'Standard shipping';

  @override
  String get expressShipping => 'Express shipping';

  @override
  String get standardShippingDescription => 'Estimated delivery in 3 to 5 days';

  @override
  String get expressShippingDescription => 'Estimated delivery in 1 to 2 days';

  @override
  String get paymentMethod => 'Payment method';

  @override
  String get onlineBanking => 'Online banking';

  @override
  String get creditDebitCard => 'Credit / debit card';

  @override
  String get cashOnDelivery => 'Cash on delivery';

  @override
  String get amountDetails => 'Amount details';

  @override
  String get productSubtotal => 'Product subtotal';

  @override
  String get shippingFee => 'Shipping fee';

  @override
  String get amountDue => 'Amount due';

  @override
  String get placeOrder => 'Place order';

  @override
  String get saveAddressFailed => 'Failed to save address';

  @override
  String get createOrderFailed => 'Failed to create order';

  @override
  String get defaultAddress => 'Default';

  @override
  String get recipientName => 'Recipient name';

  @override
  String get phoneNumber => 'Phone number';

  @override
  String get detailedAddress => 'Address';

  @override
  String get city => 'City';

  @override
  String get stateRegion => 'State';

  @override
  String get postcode => 'Postcode';

  @override
  String get country => 'Country';

  @override
  String get setAsDefaultAddress => 'Set as default address';

  @override
  String get saveAddress => 'Save address';

  @override
  String requiredField(String field) {
    return 'Please enter $field';
  }

  @override
  String get all => 'All';

  @override
  String get pendingPayment => 'Pending payment';

  @override
  String get processing => 'Processing';

  @override
  String get awaitingDelivery => 'To receive';

  @override
  String get completed => 'Completed';

  @override
  String get cancelled => 'Cancelled';

  @override
  String get orderStatusPaid => 'Paid';

  @override
  String get orderStatusShipped => 'Shipped';

  @override
  String get orderStatusDelivered => 'Delivered';

  @override
  String get orderStatusRefunded => 'Refunded';

  @override
  String get noOrders => 'No orders yet';

  @override
  String get orderLoadFailed => 'Failed to load orders';

  @override
  String orderNumber(String number) {
    return 'Order $number';
  }

  @override
  String orderItemQuantity(int count) {
    return '$count items';
  }

  @override
  String orderProductTypes(int count) {
    return '$count product types';
  }

  @override
  String get orderTotal => 'Total:';

  @override
  String get orderDetails => 'Order details';

  @override
  String get cancelOrder => 'Cancel order';

  @override
  String goToPayment(String amount) {
    return 'Pay now · RM $amount';
  }

  @override
  String get cancelOrderConfirmation =>
      'Cancelling this order will automatically restore the reserved stock. Are you sure you want to cancel it?';

  @override
  String get back => 'Back';

  @override
  String get confirmCancellation => 'Confirm cancellation';

  @override
  String get orderCancelledStockRestored =>
      'Order cancelled and product stock restored';

  @override
  String get cancelOrderFailed => 'Failed to cancel order';

  @override
  String get statusPendingPaymentDescription =>
      'Complete payment to continue processing your order';

  @override
  String get statusPaidDescription =>
      'Payment successful. Waiting for the seller to process your order';

  @override
  String get statusProcessingDescription =>
      'The seller is preparing your products';

  @override
  String get statusShippedDescription =>
      'Your products have been handed to the delivery service';

  @override
  String get statusDeliveredDescription =>
      'Your products have been delivered. Please confirm receipt';

  @override
  String get statusCompletedDescription => 'This order has been completed';

  @override
  String get statusCancelledDescription => 'This order has been cancelled';

  @override
  String get statusRefundedDescription => 'This order has been refunded';

  @override
  String get deliveryAndPayment => 'Delivery & payment';

  @override
  String get discount => 'Discount';

  @override
  String get orderGrandTotal => 'Order total';

  @override
  String get orderInformation => 'Order information';

  @override
  String get orderNumberLabel => 'Order number';

  @override
  String get createdAt => 'Created at';

  @override
  String get orderNotFound => 'Order not found';

  @override
  String get orderPayment => 'Order payment';

  @override
  String get paymentAutoUpdateNote =>
      'After payment, the order will be verified and updated automatically. You do not need to pay again.';

  @override
  String confirmPayment(String amount) {
    return 'Pay RM $amount';
  }

  @override
  String get orderDoesNotNeedPayment =>
      'This order does not currently require payment';

  @override
  String get paymentSuccessOrderUpdated => 'Payment successful. Order updated';

  @override
  String get paymentSubmittedAutoUpdate =>
      'Payment submitted. The order status will update automatically';

  @override
  String get orderCreatedSuccessfully => 'Order created successfully';

  @override
  String get orderCreated => 'Order created';

  @override
  String orderNumberValue(String number) {
    return 'Order number: $number';
  }

  @override
  String paymentAmount(String amount) {
    return 'Payment amount: RM $amount';
  }

  @override
  String get cartClearFailedAfterOrder =>
      'The order was created, but the cart could not be cleared.';

  @override
  String get payNow => 'Pay now';

  @override
  String get viewThisOrder => 'View this order';

  @override
  String get viewAllOrders => 'View all orders';

  @override
  String get continueShopping => 'Continue shopping';

  @override
  String get addToCart => 'Add to cart';

  @override
  String addToCartWithQuantity(int count) {
    return 'Add to cart ($count)';
  }

  @override
  String get buyNow => 'Buy now';

  @override
  String productAddedToCart(String product) {
    return '$product added to cart';
  }

  @override
  String get viewCart => 'View cart';

  @override
  String get addToCartFailed => 'Failed to add to cart';

  @override
  String categoryNoProducts(String category) {
    return 'No products in $category yet';
  }

  @override
  String get cart => 'Cart';

  @override
  String get productLoadFailed => 'Failed to load products';

  @override
  String get clearCartFailed => 'Failed to clear cart';

  @override
  String get cartUpdateFailed => 'Failed to update cart';

  @override
  String get checkoutLoadFailed => 'Failed to load checkout information';

  @override
  String get checkoutNoItems => 'There are no items to check out';

  @override
  String get checkoutSelectAddress => 'Please select a shipping address';

  @override
  String get onlyPendingPaymentCanBeCancelled =>
      'Only pending-payment orders can be cancelled';

  @override
  String get paymentCredentialMissing => 'Unable to initialize payment';

  @override
  String get paymentFailedTryAnotherMethod =>
      'Payment failed. Please try another payment method';

  @override
  String get paymentConnectionFailed =>
      'Unable to connect to the payment service';

  @override
  String get paymentSessionExpired =>
      'Your session has expired. Please sign in again';

  @override
  String get paymentInvalidResponse =>
      'The payment service returned an invalid response';

  @override
  String get paymentCreationFailed => 'Unable to create payment';

  @override
  String get paymentConfirmationFailed =>
      'Unable to confirm the payment result';

  @override
  String get paymentUnknownError => 'Payment failed. Please try again';

  @override
  String get authConnectionFailed =>
      'Unable to connect to the server. Please check your connection';

  @override
  String get authSessionExpired =>
      'Your session has expired. Please sign in again';

  @override
  String get authInvalidResponse => 'The server returned an invalid response';

  @override
  String get noProductsAvailable => 'No products are available right now';

  @override
  String get dailyDealsComingSoon => 'Daily deals are coming soon';

  @override
  String get couponsComingSoon => 'Coupons are coming soon';

  @override
  String get heroLaptopKicker => 'WORK & CREATE';

  @override
  String get heroLaptopTitle => 'Power up your workspace';

  @override
  String get heroLaptopSubtitle =>
      'Discover laptops built for study, work and creativity';

  @override
  String get heroMobileKicker => 'MOBILE WEEK';

  @override
  String get heroMobileTitle => 'Your next phone is here';

  @override
  String get heroMobileSubtitle =>
      'Explore the latest smartphones and everyday essentials';

  @override
  String get heroGamingKicker => 'LEVEL UP';

  @override
  String get heroGamingTitle => 'Built for your next game';

  @override
  String get heroGamingSubtitle =>
      'Gaming gear, audio and accessories in one place';
}
