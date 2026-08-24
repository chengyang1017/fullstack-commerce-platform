import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Shopping App'**
  String get appTitle;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get welcomeBack;

  /// No description provided for @loginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to view your cart and orders'**
  String get loginSubtitle;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @enterEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter your email'**
  String get enterEmail;

  /// No description provided for @invalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email address'**
  String get invalidEmail;

  /// No description provided for @enterPassword.
  ///
  /// In en, this message translates to:
  /// **'Please enter your password'**
  String get enterPassword;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get login;

  /// No description provided for @loginFailed.
  ///
  /// In en, this message translates to:
  /// **'Sign in failed. Please try again later.'**
  String get loginFailed;

  /// No description provided for @noAccountRegister.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account? Create one'**
  String get noAccountRegister;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get createAccount;

  /// No description provided for @registerCustomerAccount.
  ///
  /// In en, this message translates to:
  /// **'Create your customer account'**
  String get registerCustomerAccount;

  /// No description provided for @username.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get username;

  /// No description provided for @invalidUsernameLength.
  ///
  /// In en, this message translates to:
  /// **'Username must be between 2 and 60 characters'**
  String get invalidUsernameLength;

  /// No description provided for @passwordMinimumLength.
  ///
  /// In en, this message translates to:
  /// **'Password must contain at least 8 characters'**
  String get passwordMinimumLength;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get confirmPassword;

  /// No description provided for @passwordMismatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordMismatch;

  /// No description provided for @registerAndLogin.
  ///
  /// In en, this message translates to:
  /// **'Create account and sign in'**
  String get registerAndLogin;

  /// No description provided for @registerFailed.
  ///
  /// In en, this message translates to:
  /// **'Registration failed. Please try again later.'**
  String get registerFailed;

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// No description provided for @unknownUser.
  ///
  /// In en, this message translates to:
  /// **'Unknown user'**
  String get unknownUser;

  /// No description provided for @myOrders.
  ///
  /// In en, this message translates to:
  /// **'My orders'**
  String get myOrders;

  /// No description provided for @viewOrderHistory.
  ///
  /// In en, this message translates to:
  /// **'View order history'**
  String get viewOrderHistory;

  /// No description provided for @orderCount.
  ///
  /// In en, this message translates to:
  /// **'{count} orders'**
  String orderCount(int count);

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @followSystem.
  ///
  /// In en, this message translates to:
  /// **'Follow system'**
  String get followSystem;

  /// No description provided for @light.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get light;

  /// No description provided for @dark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get dark;

  /// No description provided for @followSystemThemeDescription.
  ///
  /// In en, this message translates to:
  /// **'Automatically match your device appearance'**
  String get followSystemThemeDescription;

  /// No description provided for @lightThemeDescription.
  ///
  /// In en, this message translates to:
  /// **'Always use light appearance'**
  String get lightThemeDescription;

  /// No description provided for @darkThemeDescription.
  ///
  /// In en, this message translates to:
  /// **'Always use dark appearance'**
  String get darkThemeDescription;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @followSystemLanguage.
  ///
  /// In en, this message translates to:
  /// **'Follow system'**
  String get followSystemLanguage;

  /// No description provided for @chinese.
  ///
  /// In en, this message translates to:
  /// **'Chinese'**
  String get chinese;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @followSystemLanguageDescription.
  ///
  /// In en, this message translates to:
  /// **'Use your device language'**
  String get followSystemLanguageDescription;

  /// No description provided for @chineseDescription.
  ///
  /// In en, this message translates to:
  /// **'Use Chinese'**
  String get chineseDescription;

  /// No description provided for @englishDescription.
  ///
  /// In en, this message translates to:
  /// **'Use the English interface'**
  String get englishDescription;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get logout;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @me.
  ///
  /// In en, this message translates to:
  /// **'Me'**
  String get me;

  /// No description provided for @myAccount.
  ///
  /// In en, this message translates to:
  /// **'My account'**
  String get myAccount;

  /// No description provided for @searchProductsBrands.
  ///
  /// In en, this message translates to:
  /// **'Search products and brands'**
  String get searchProductsBrands;

  /// No description provided for @categoryPhone.
  ///
  /// In en, this message translates to:
  /// **'Phones'**
  String get categoryPhone;

  /// No description provided for @categoryComputer.
  ///
  /// In en, this message translates to:
  /// **'Computers'**
  String get categoryComputer;

  /// No description provided for @categoryCamera.
  ///
  /// In en, this message translates to:
  /// **'Cameras'**
  String get categoryCamera;

  /// No description provided for @categoryAudio.
  ///
  /// In en, this message translates to:
  /// **'Audio'**
  String get categoryAudio;

  /// No description provided for @categoryGaming.
  ///
  /// In en, this message translates to:
  /// **'Gaming'**
  String get categoryGaming;

  /// No description provided for @categoryAccessory.
  ///
  /// In en, this message translates to:
  /// **'Accessories'**
  String get categoryAccessory;

  /// No description provided for @categoryHomeAppliance.
  ///
  /// In en, this message translates to:
  /// **'Home appliances'**
  String get categoryHomeAppliance;

  /// No description provided for @categoryAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get categoryAll;

  /// No description provided for @techWeek.
  ///
  /// In en, this message translates to:
  /// **'TECH WEEK'**
  String get techWeek;

  /// No description provided for @bannerDiscount.
  ///
  /// In en, this message translates to:
  /// **'Up to 40% off'**
  String get bannerDiscount;

  /// No description provided for @bannerTechDeal.
  ///
  /// In en, this message translates to:
  /// **'Limited-time deals on selected tech'**
  String get bannerTechDeal;

  /// No description provided for @dailyDeals.
  ///
  /// In en, this message translates to:
  /// **'Daily deals'**
  String get dailyDeals;

  /// No description provided for @newArrivals.
  ///
  /// In en, this message translates to:
  /// **'New arrivals'**
  String get newArrivals;

  /// No description provided for @bestSellers.
  ///
  /// In en, this message translates to:
  /// **'Best sellers'**
  String get bestSellers;

  /// No description provided for @coupons.
  ///
  /// In en, this message translates to:
  /// **'Coupons'**
  String get coupons;

  /// No description provided for @productCategories.
  ///
  /// In en, this message translates to:
  /// **'Product categories'**
  String get productCategories;

  /// No description provided for @viewAll.
  ///
  /// In en, this message translates to:
  /// **'View all'**
  String get viewAll;

  /// No description provided for @allProducts.
  ///
  /// In en, this message translates to:
  /// **'All products'**
  String get allProducts;

  /// No description provided for @hotProducts.
  ///
  /// In en, this message translates to:
  /// **'Best sellers'**
  String get hotProducts;

  /// No description provided for @more.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get more;

  /// No description provided for @memberExclusive.
  ///
  /// In en, this message translates to:
  /// **'Member exclusive'**
  String get memberExclusive;

  /// No description provided for @joinMemberDiscount.
  ///
  /// In en, this message translates to:
  /// **'Join to enjoy more discounts'**
  String get joinMemberDiscount;

  /// No description provided for @latestProducts.
  ///
  /// In en, this message translates to:
  /// **'Latest products'**
  String get latestProducts;

  /// No description provided for @scannerComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Scanner is not available yet'**
  String get scannerComingSoon;

  /// No description provided for @searchComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Search is not available yet'**
  String get searchComingSoon;

  /// No description provided for @soldCount.
  ///
  /// In en, this message translates to:
  /// **'Sold {count}'**
  String soldCount(int count);

  /// No description provided for @soldAndStock.
  ///
  /// In en, this message translates to:
  /// **'Sold {sold} · Stock {stock}'**
  String soldAndStock(int sold, int stock);

  /// No description provided for @cartTitle.
  ///
  /// In en, this message translates to:
  /// **'Cart ({count})'**
  String cartTitle(int count);

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @cartEmpty.
  ///
  /// In en, this message translates to:
  /// **'Your cart is empty'**
  String get cartEmpty;

  /// No description provided for @cartLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load cart'**
  String get cartLoadFailed;

  /// No description provided for @reload.
  ///
  /// In en, this message translates to:
  /// **'Reload'**
  String get reload;

  /// No description provided for @total.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get total;

  /// No description provided for @checkoutCount.
  ///
  /// In en, this message translates to:
  /// **'Checkout ({count})'**
  String checkoutCount(int count);

  /// No description provided for @clearCart.
  ///
  /// In en, this message translates to:
  /// **'Clear cart'**
  String get clearCart;

  /// No description provided for @clearCartConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Remove all items from your cart?'**
  String get clearCartConfirmation;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @cartActionFailed.
  ///
  /// In en, this message translates to:
  /// **'Cart operation failed'**
  String get cartActionFailed;

  /// No description provided for @cartItemSubtotal.
  ///
  /// In en, this message translates to:
  /// **'Subtotal: RM {amount}'**
  String cartItemSubtotal(String amount);

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @confirmOrder.
  ///
  /// In en, this message translates to:
  /// **'Confirm order'**
  String get confirmOrder;

  /// No description provided for @shippingAddress.
  ///
  /// In en, this message translates to:
  /// **'Shipping address'**
  String get shippingAddress;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @addShippingAddress.
  ///
  /// In en, this message translates to:
  /// **'Add shipping address'**
  String get addShippingAddress;

  /// No description provided for @shippingAddressRequired.
  ///
  /// In en, this message translates to:
  /// **'A shipping address is required before checkout'**
  String get shippingAddressRequired;

  /// No description provided for @products.
  ///
  /// In en, this message translates to:
  /// **'Products'**
  String get products;

  /// No description provided for @shippingMethod.
  ///
  /// In en, this message translates to:
  /// **'Shipping method'**
  String get shippingMethod;

  /// No description provided for @standardShipping.
  ///
  /// In en, this message translates to:
  /// **'Standard shipping'**
  String get standardShipping;

  /// No description provided for @expressShipping.
  ///
  /// In en, this message translates to:
  /// **'Express shipping'**
  String get expressShipping;

  /// No description provided for @standardShippingDescription.
  ///
  /// In en, this message translates to:
  /// **'Estimated delivery in 3 to 5 days'**
  String get standardShippingDescription;

  /// No description provided for @expressShippingDescription.
  ///
  /// In en, this message translates to:
  /// **'Estimated delivery in 1 to 2 days'**
  String get expressShippingDescription;

  /// No description provided for @paymentMethod.
  ///
  /// In en, this message translates to:
  /// **'Payment method'**
  String get paymentMethod;

  /// No description provided for @onlineBanking.
  ///
  /// In en, this message translates to:
  /// **'Online banking'**
  String get onlineBanking;

  /// No description provided for @creditDebitCard.
  ///
  /// In en, this message translates to:
  /// **'Credit / debit card'**
  String get creditDebitCard;

  /// No description provided for @cashOnDelivery.
  ///
  /// In en, this message translates to:
  /// **'Cash on delivery'**
  String get cashOnDelivery;

  /// No description provided for @amountDetails.
  ///
  /// In en, this message translates to:
  /// **'Amount details'**
  String get amountDetails;

  /// No description provided for @productSubtotal.
  ///
  /// In en, this message translates to:
  /// **'Product subtotal'**
  String get productSubtotal;

  /// No description provided for @shippingFee.
  ///
  /// In en, this message translates to:
  /// **'Shipping fee'**
  String get shippingFee;

  /// No description provided for @amountDue.
  ///
  /// In en, this message translates to:
  /// **'Amount due'**
  String get amountDue;

  /// No description provided for @placeOrder.
  ///
  /// In en, this message translates to:
  /// **'Place order'**
  String get placeOrder;

  /// No description provided for @saveAddressFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to save address'**
  String get saveAddressFailed;

  /// No description provided for @createOrderFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to create order'**
  String get createOrderFailed;

  /// No description provided for @defaultAddress.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get defaultAddress;

  /// No description provided for @recipientName.
  ///
  /// In en, this message translates to:
  /// **'Recipient name'**
  String get recipientName;

  /// No description provided for @phoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone number'**
  String get phoneNumber;

  /// No description provided for @detailedAddress.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get detailedAddress;

  /// No description provided for @city.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get city;

  /// No description provided for @stateRegion.
  ///
  /// In en, this message translates to:
  /// **'State'**
  String get stateRegion;

  /// No description provided for @postcode.
  ///
  /// In en, this message translates to:
  /// **'Postcode'**
  String get postcode;

  /// No description provided for @country.
  ///
  /// In en, this message translates to:
  /// **'Country'**
  String get country;

  /// No description provided for @setAsDefaultAddress.
  ///
  /// In en, this message translates to:
  /// **'Set as default address'**
  String get setAsDefaultAddress;

  /// No description provided for @saveAddress.
  ///
  /// In en, this message translates to:
  /// **'Save address'**
  String get saveAddress;

  /// No description provided for @requiredField.
  ///
  /// In en, this message translates to:
  /// **'Please enter {field}'**
  String requiredField(String field);

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @pendingPayment.
  ///
  /// In en, this message translates to:
  /// **'Pending payment'**
  String get pendingPayment;

  /// No description provided for @processing.
  ///
  /// In en, this message translates to:
  /// **'Processing'**
  String get processing;

  /// No description provided for @awaitingDelivery.
  ///
  /// In en, this message translates to:
  /// **'To receive'**
  String get awaitingDelivery;

  /// No description provided for @completed.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completed;

  /// No description provided for @cancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get cancelled;

  /// No description provided for @orderStatusPaid.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get orderStatusPaid;

  /// No description provided for @orderStatusShipped.
  ///
  /// In en, this message translates to:
  /// **'Shipped'**
  String get orderStatusShipped;

  /// No description provided for @orderStatusDelivered.
  ///
  /// In en, this message translates to:
  /// **'Delivered'**
  String get orderStatusDelivered;

  /// No description provided for @orderStatusRefunded.
  ///
  /// In en, this message translates to:
  /// **'Refunded'**
  String get orderStatusRefunded;

  /// No description provided for @noOrders.
  ///
  /// In en, this message translates to:
  /// **'No orders yet'**
  String get noOrders;

  /// No description provided for @orderLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load orders'**
  String get orderLoadFailed;

  /// No description provided for @orderNumber.
  ///
  /// In en, this message translates to:
  /// **'Order {number}'**
  String orderNumber(String number);

  /// No description provided for @orderItemQuantity.
  ///
  /// In en, this message translates to:
  /// **'{count} items'**
  String orderItemQuantity(int count);

  /// No description provided for @orderProductTypes.
  ///
  /// In en, this message translates to:
  /// **'{count} product types'**
  String orderProductTypes(int count);

  /// No description provided for @orderTotal.
  ///
  /// In en, this message translates to:
  /// **'Total:'**
  String get orderTotal;

  /// No description provided for @orderDetails.
  ///
  /// In en, this message translates to:
  /// **'Order details'**
  String get orderDetails;

  /// No description provided for @cancelOrder.
  ///
  /// In en, this message translates to:
  /// **'Cancel order'**
  String get cancelOrder;

  /// No description provided for @goToPayment.
  ///
  /// In en, this message translates to:
  /// **'Pay now · RM {amount}'**
  String goToPayment(String amount);

  /// No description provided for @cancelOrderConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Cancelling this order will automatically restore the reserved stock. Are you sure you want to cancel it?'**
  String get cancelOrderConfirmation;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @confirmCancellation.
  ///
  /// In en, this message translates to:
  /// **'Confirm cancellation'**
  String get confirmCancellation;

  /// No description provided for @orderCancelledStockRestored.
  ///
  /// In en, this message translates to:
  /// **'Order cancelled and product stock restored'**
  String get orderCancelledStockRestored;

  /// No description provided for @cancelOrderFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to cancel order'**
  String get cancelOrderFailed;

  /// No description provided for @statusPendingPaymentDescription.
  ///
  /// In en, this message translates to:
  /// **'Complete payment to continue processing your order'**
  String get statusPendingPaymentDescription;

  /// No description provided for @statusPaidDescription.
  ///
  /// In en, this message translates to:
  /// **'Payment successful. Waiting for the seller to process your order'**
  String get statusPaidDescription;

  /// No description provided for @statusProcessingDescription.
  ///
  /// In en, this message translates to:
  /// **'The seller is preparing your products'**
  String get statusProcessingDescription;

  /// No description provided for @statusShippedDescription.
  ///
  /// In en, this message translates to:
  /// **'Your products have been handed to the delivery service'**
  String get statusShippedDescription;

  /// No description provided for @statusDeliveredDescription.
  ///
  /// In en, this message translates to:
  /// **'Your products have been delivered. Please confirm receipt'**
  String get statusDeliveredDescription;

  /// No description provided for @statusCompletedDescription.
  ///
  /// In en, this message translates to:
  /// **'This order has been completed'**
  String get statusCompletedDescription;

  /// No description provided for @statusCancelledDescription.
  ///
  /// In en, this message translates to:
  /// **'This order has been cancelled'**
  String get statusCancelledDescription;

  /// No description provided for @statusRefundedDescription.
  ///
  /// In en, this message translates to:
  /// **'This order has been refunded'**
  String get statusRefundedDescription;

  /// No description provided for @deliveryAndPayment.
  ///
  /// In en, this message translates to:
  /// **'Delivery & payment'**
  String get deliveryAndPayment;

  /// No description provided for @discount.
  ///
  /// In en, this message translates to:
  /// **'Discount'**
  String get discount;

  /// No description provided for @orderGrandTotal.
  ///
  /// In en, this message translates to:
  /// **'Order total'**
  String get orderGrandTotal;

  /// No description provided for @orderInformation.
  ///
  /// In en, this message translates to:
  /// **'Order information'**
  String get orderInformation;

  /// No description provided for @orderNumberLabel.
  ///
  /// In en, this message translates to:
  /// **'Order number'**
  String get orderNumberLabel;

  /// No description provided for @createdAt.
  ///
  /// In en, this message translates to:
  /// **'Created at'**
  String get createdAt;

  /// No description provided for @orderNotFound.
  ///
  /// In en, this message translates to:
  /// **'Order not found'**
  String get orderNotFound;

  /// No description provided for @orderPayment.
  ///
  /// In en, this message translates to:
  /// **'Order payment'**
  String get orderPayment;

  /// No description provided for @paymentAutoUpdateNote.
  ///
  /// In en, this message translates to:
  /// **'After payment, the order will be verified and updated automatically. You do not need to pay again.'**
  String get paymentAutoUpdateNote;

  /// No description provided for @confirmPayment.
  ///
  /// In en, this message translates to:
  /// **'Pay RM {amount}'**
  String confirmPayment(String amount);

  /// No description provided for @orderDoesNotNeedPayment.
  ///
  /// In en, this message translates to:
  /// **'This order does not currently require payment'**
  String get orderDoesNotNeedPayment;

  /// No description provided for @paymentSuccessOrderUpdated.
  ///
  /// In en, this message translates to:
  /// **'Payment successful. Order updated'**
  String get paymentSuccessOrderUpdated;

  /// No description provided for @paymentSubmittedAutoUpdate.
  ///
  /// In en, this message translates to:
  /// **'Payment submitted. The order status will update automatically'**
  String get paymentSubmittedAutoUpdate;

  /// No description provided for @orderCreatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Order created successfully'**
  String get orderCreatedSuccessfully;

  /// No description provided for @orderCreated.
  ///
  /// In en, this message translates to:
  /// **'Order created'**
  String get orderCreated;

  /// No description provided for @orderNumberValue.
  ///
  /// In en, this message translates to:
  /// **'Order number: {number}'**
  String orderNumberValue(String number);

  /// No description provided for @paymentAmount.
  ///
  /// In en, this message translates to:
  /// **'Payment amount: RM {amount}'**
  String paymentAmount(String amount);

  /// No description provided for @cartClearFailedAfterOrder.
  ///
  /// In en, this message translates to:
  /// **'The order was created, but the cart could not be cleared.'**
  String get cartClearFailedAfterOrder;

  /// No description provided for @payNow.
  ///
  /// In en, this message translates to:
  /// **'Pay now'**
  String get payNow;

  /// No description provided for @viewThisOrder.
  ///
  /// In en, this message translates to:
  /// **'View this order'**
  String get viewThisOrder;

  /// No description provided for @viewAllOrders.
  ///
  /// In en, this message translates to:
  /// **'View all orders'**
  String get viewAllOrders;

  /// No description provided for @continueShopping.
  ///
  /// In en, this message translates to:
  /// **'Continue shopping'**
  String get continueShopping;

  /// No description provided for @addToCart.
  ///
  /// In en, this message translates to:
  /// **'Add to cart'**
  String get addToCart;

  /// No description provided for @addToCartWithQuantity.
  ///
  /// In en, this message translates to:
  /// **'Add to cart ({count})'**
  String addToCartWithQuantity(int count);

  /// No description provided for @buyNow.
  ///
  /// In en, this message translates to:
  /// **'Buy now'**
  String get buyNow;

  /// No description provided for @productAddedToCart.
  ///
  /// In en, this message translates to:
  /// **'{product} added to cart'**
  String productAddedToCart(String product);

  /// No description provided for @viewCart.
  ///
  /// In en, this message translates to:
  /// **'View cart'**
  String get viewCart;

  /// No description provided for @addToCartFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to add to cart'**
  String get addToCartFailed;

  /// No description provided for @categoryNoProducts.
  ///
  /// In en, this message translates to:
  /// **'No products in {category} yet'**
  String categoryNoProducts(String category);

  /// No description provided for @cart.
  ///
  /// In en, this message translates to:
  /// **'Cart'**
  String get cart;

  /// No description provided for @productLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load products'**
  String get productLoadFailed;

  /// No description provided for @clearCartFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to clear cart'**
  String get clearCartFailed;

  /// No description provided for @cartUpdateFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to update cart'**
  String get cartUpdateFailed;

  /// No description provided for @checkoutLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load checkout information'**
  String get checkoutLoadFailed;

  /// No description provided for @checkoutNoItems.
  ///
  /// In en, this message translates to:
  /// **'There are no items to check out'**
  String get checkoutNoItems;

  /// No description provided for @checkoutSelectAddress.
  ///
  /// In en, this message translates to:
  /// **'Please select a shipping address'**
  String get checkoutSelectAddress;

  /// No description provided for @onlyPendingPaymentCanBeCancelled.
  ///
  /// In en, this message translates to:
  /// **'Only pending-payment orders can be cancelled'**
  String get onlyPendingPaymentCanBeCancelled;

  /// No description provided for @paymentCredentialMissing.
  ///
  /// In en, this message translates to:
  /// **'Unable to initialize payment'**
  String get paymentCredentialMissing;

  /// No description provided for @paymentFailedTryAnotherMethod.
  ///
  /// In en, this message translates to:
  /// **'Payment failed. Please try another payment method'**
  String get paymentFailedTryAnotherMethod;

  /// No description provided for @paymentConnectionFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to connect to the payment service'**
  String get paymentConnectionFailed;

  /// No description provided for @paymentSessionExpired.
  ///
  /// In en, this message translates to:
  /// **'Your session has expired. Please sign in again'**
  String get paymentSessionExpired;

  /// No description provided for @paymentInvalidResponse.
  ///
  /// In en, this message translates to:
  /// **'The payment service returned an invalid response'**
  String get paymentInvalidResponse;

  /// No description provided for @paymentCreationFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to create payment'**
  String get paymentCreationFailed;

  /// No description provided for @paymentConfirmationFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to confirm the payment result'**
  String get paymentConfirmationFailed;

  /// No description provided for @paymentUnknownError.
  ///
  /// In en, this message translates to:
  /// **'Payment failed. Please try again'**
  String get paymentUnknownError;

  /// No description provided for @authConnectionFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to connect to the server. Please check your connection'**
  String get authConnectionFailed;

  /// No description provided for @authSessionExpired.
  ///
  /// In en, this message translates to:
  /// **'Your session has expired. Please sign in again'**
  String get authSessionExpired;

  /// No description provided for @authInvalidResponse.
  ///
  /// In en, this message translates to:
  /// **'The server returned an invalid response'**
  String get authInvalidResponse;

  /// No description provided for @noProductsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No products are available right now'**
  String get noProductsAvailable;

  /// No description provided for @dailyDealsComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Daily deals are coming soon'**
  String get dailyDealsComingSoon;

  /// No description provided for @couponsComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coupons are coming soon'**
  String get couponsComingSoon;

  /// No description provided for @heroLaptopKicker.
  ///
  /// In en, this message translates to:
  /// **'WORK & CREATE'**
  String get heroLaptopKicker;

  /// No description provided for @heroLaptopTitle.
  ///
  /// In en, this message translates to:
  /// **'Power up your workspace'**
  String get heroLaptopTitle;

  /// No description provided for @heroLaptopSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Discover laptops built for study, work and creativity'**
  String get heroLaptopSubtitle;

  /// No description provided for @heroMobileKicker.
  ///
  /// In en, this message translates to:
  /// **'MOBILE WEEK'**
  String get heroMobileKicker;

  /// No description provided for @heroMobileTitle.
  ///
  /// In en, this message translates to:
  /// **'Your next phone is here'**
  String get heroMobileTitle;

  /// No description provided for @heroMobileSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Explore the latest smartphones and everyday essentials'**
  String get heroMobileSubtitle;

  /// No description provided for @heroGamingKicker.
  ///
  /// In en, this message translates to:
  /// **'LEVEL UP'**
  String get heroGamingKicker;

  /// No description provided for @heroGamingTitle.
  ///
  /// In en, this message translates to:
  /// **'Built for your next game'**
  String get heroGamingTitle;

  /// No description provided for @heroGamingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Gaming gear, audio and accessories in one place'**
  String get heroGamingSubtitle;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
