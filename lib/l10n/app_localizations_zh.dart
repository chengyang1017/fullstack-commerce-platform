// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => '购物平台';

  @override
  String get welcomeBack => '欢迎回来';

  @override
  String get loginSubtitle => '登录后查看购物车和订单';

  @override
  String get email => '邮箱';

  @override
  String get password => '密码';

  @override
  String get enterEmail => '请输入邮箱';

  @override
  String get invalidEmail => '请输入有效邮箱';

  @override
  String get enterPassword => '请输入密码';

  @override
  String get login => '登录';

  @override
  String get loginFailed => '登录失败，请稍后重试';

  @override
  String get noAccountRegister => '没有账号？立即注册';

  @override
  String get createAccount => '创建账号';

  @override
  String get registerCustomerAccount => '注册客户账号';

  @override
  String get username => '用户名';

  @override
  String get invalidUsernameLength => '用户名长度必须为 2 至 60 个字符';

  @override
  String get passwordMinimumLength => '密码至少需要 8 个字符';

  @override
  String get confirmPassword => '确认密码';

  @override
  String get passwordMismatch => '两次输入的密码不一致';

  @override
  String get registerAndLogin => '注册并登录';

  @override
  String get registerFailed => '注册失败，请稍后重试';

  @override
  String get account => '我的';

  @override
  String get unknownUser => '未知用户';

  @override
  String get myOrders => '我的订单';

  @override
  String get viewOrderHistory => '查看订单记录';

  @override
  String orderCount(int count) {
    return '共有 $count 笔订单';
  }

  @override
  String get appearance => '外观模式';

  @override
  String get followSystem => '跟随系统';

  @override
  String get light => '浅色';

  @override
  String get dark => '深色';

  @override
  String get followSystemThemeDescription => '根据设备的浅色或深色模式自动切换';

  @override
  String get lightThemeDescription => '始终使用浅色外观';

  @override
  String get darkThemeDescription => '始终使用深色外观';

  @override
  String get language => '语言';

  @override
  String get followSystemLanguage => '跟随系统';

  @override
  String get chinese => '中文';

  @override
  String get english => 'English';

  @override
  String get followSystemLanguageDescription => '根据设备语言自动选择';

  @override
  String get chineseDescription => '使用中文界面';

  @override
  String get englishDescription => '使用英文界面';

  @override
  String get logout => '退出登录';

  @override
  String get home => '主页';

  @override
  String get me => '我';

  @override
  String get myAccount => '我的账户';

  @override
  String get searchProductsBrands => '搜索商品、品牌';

  @override
  String get categoryPhone => '手机';

  @override
  String get categoryComputer => '电脑';

  @override
  String get categoryCamera => '相机';

  @override
  String get categoryAudio => '音频';

  @override
  String get categoryGaming => '游戏';

  @override
  String get categoryAccessory => '配件';

  @override
  String get categoryHomeAppliance => '家电';

  @override
  String get categoryAll => '全部';

  @override
  String get techWeek => 'TECH WEEK';

  @override
  String get bannerDiscount => '最高优惠 40%';

  @override
  String get bannerTechDeal => '精选科技商品限时优惠';

  @override
  String get dailyDeals => '每日优惠';

  @override
  String get newArrivals => '新品上市';

  @override
  String get bestSellers => '热销排行';

  @override
  String get coupons => '优惠券';

  @override
  String get productCategories => '商品分类';

  @override
  String get viewAll => '查看全部';

  @override
  String get allProducts => '全部商品';

  @override
  String get hotProducts => '热销商品';

  @override
  String get more => '更多';

  @override
  String get memberExclusive => '会员专属优惠';

  @override
  String get joinMemberDiscount => '加入会员享更多折扣';

  @override
  String get latestProducts => '最新商品';

  @override
  String get scannerComingSoon => '扫码功能尚未接入';

  @override
  String get searchComingSoon => '搜索页面尚未接入';

  @override
  String soldCount(int count) {
    return '已售 $count';
  }

  @override
  String soldAndStock(int sold, int stock) {
    return '已售 $sold · 库存 $stock';
  }

  @override
  String cartTitle(int count) {
    return '购物车 ($count)';
  }

  @override
  String get clear => '清空';

  @override
  String get cartEmpty => '购物车还是空的';

  @override
  String get cartLoadFailed => '购物车加载失败';

  @override
  String get reload => '重新加载';

  @override
  String get total => '总计';

  @override
  String checkoutCount(int count) {
    return '结算 ($count)';
  }

  @override
  String get clearCart => '清空购物车';

  @override
  String get clearCartConfirmation => '确定要删除购物车中的所有商品吗？';

  @override
  String get cancel => '取消';

  @override
  String get cartActionFailed => '购物车操作失败';

  @override
  String cartItemSubtotal(String amount) {
    return '小计：RM $amount';
  }

  @override
  String get delete => '删除';

  @override
  String get confirmOrder => '确认订单';

  @override
  String get shippingAddress => '收货地址';

  @override
  String get add => '新增';

  @override
  String get addShippingAddress => '新增收货地址';

  @override
  String get shippingAddressRequired => '结算前必须填写配送地址';

  @override
  String get products => '商品';

  @override
  String get shippingMethod => '配送方式';

  @override
  String get standardShipping => '标准配送';

  @override
  String get expressShipping => '快速配送';

  @override
  String get standardShippingDescription => '预计 3 至 5 天送达';

  @override
  String get expressShippingDescription => '预计 1 至 2 天送达';

  @override
  String get paymentMethod => '付款方式';

  @override
  String get onlineBanking => '网上银行';

  @override
  String get creditDebitCard => '信用卡／签账卡';

  @override
  String get cashOnDelivery => '货到付款';

  @override
  String get amountDetails => '金额明细';

  @override
  String get productSubtotal => '商品小计';

  @override
  String get shippingFee => '运费';

  @override
  String get amountDue => '应付总额';

  @override
  String get placeOrder => '提交订单';

  @override
  String get saveAddressFailed => '保存地址失败';

  @override
  String get createOrderFailed => '建立订单失败';

  @override
  String get defaultAddress => '默认';

  @override
  String get recipientName => '收件人姓名';

  @override
  String get phoneNumber => '电话号码';

  @override
  String get detailedAddress => '详细地址';

  @override
  String get city => '城市';

  @override
  String get stateRegion => '州属';

  @override
  String get postcode => '邮递区号';

  @override
  String get country => '国家';

  @override
  String get setAsDefaultAddress => '设为默认地址';

  @override
  String get saveAddress => '保存地址';

  @override
  String requiredField(String field) {
    return '请输入$field';
  }

  @override
  String get all => '全部';

  @override
  String get pendingPayment => '待付款';

  @override
  String get processing => '处理中';

  @override
  String get awaitingDelivery => '待收货';

  @override
  String get completed => '已完成';

  @override
  String get cancelled => '已取消';

  @override
  String get orderStatusPaid => '已付款';

  @override
  String get orderStatusShipped => '已出货';

  @override
  String get orderStatusDelivered => '已送达';

  @override
  String get orderStatusRefunded => '已退款';

  @override
  String get noOrders => '暂时没有订单';

  @override
  String get orderLoadFailed => '订单加载失败';

  @override
  String orderNumber(String number) {
    return '订单 $number';
  }

  @override
  String orderItemQuantity(int count) {
    return '共 $count 件商品';
  }

  @override
  String orderProductTypes(int count) {
    return '共 $count 种商品';
  }

  @override
  String get orderTotal => '总额：';

  @override
  String get orderDetails => '订单详情';

  @override
  String get cancelOrder => '取消订单';

  @override
  String goToPayment(String amount) {
    return '去付款 · RM $amount';
  }

  @override
  String get cancelOrderConfirmation => '取消后，这笔订单占用的商品库存会自动恢复。确定取消吗？';

  @override
  String get back => '返回';

  @override
  String get confirmCancellation => '确定取消';

  @override
  String get orderCancelledStockRestored => '订单已取消，商品库存已恢复';

  @override
  String get cancelOrderFailed => '取消订单失败';

  @override
  String get statusPendingPaymentDescription => '请完成付款以继续处理订单';

  @override
  String get statusPaidDescription => '付款成功，等待商家处理';

  @override
  String get statusProcessingDescription => '商家正在准备您的商品';

  @override
  String get statusShippedDescription => '商品已交给物流公司';

  @override
  String get statusDeliveredDescription => '商品已送达，请确认收货';

  @override
  String get statusCompletedDescription => '这笔订单已完成';

  @override
  String get statusCancelledDescription => '这笔订单已取消';

  @override
  String get statusRefundedDescription => '这笔订单已退款';

  @override
  String get deliveryAndPayment => '配送与付款';

  @override
  String get discount => '优惠';

  @override
  String get orderGrandTotal => '订单总额';

  @override
  String get orderInformation => '订单信息';

  @override
  String get orderNumberLabel => '订单编号';

  @override
  String get createdAt => '建立时间';

  @override
  String get orderNotFound => '找不到这笔订单';

  @override
  String get orderPayment => '订单付款';

  @override
  String get paymentAutoUpdateNote => '付款完成后会自动确认并更新订单，不需要再次点击付款。';

  @override
  String confirmPayment(String amount) {
    return '确认付款 RM $amount';
  }

  @override
  String get orderDoesNotNeedPayment => '这笔订单目前不需要付款';

  @override
  String get paymentSuccessOrderUpdated => '付款成功，订单已更新';

  @override
  String get paymentSubmittedAutoUpdate => '付款已提交，系统会自动更新订单状态';

  @override
  String get orderCreatedSuccessfully => '订单建立成功';

  @override
  String get orderCreated => '订单已建立';

  @override
  String orderNumberValue(String number) {
    return '订单编号：$number';
  }

  @override
  String paymentAmount(String amount) {
    return '付款金额：RM $amount';
  }

  @override
  String get cartClearFailedAfterOrder => '订单已建立，但购物车清理失败。';

  @override
  String get payNow => '立即付款';

  @override
  String get viewThisOrder => '查看这笔订单';

  @override
  String get viewAllOrders => '查看全部订单';

  @override
  String get continueShopping => '继续购物';

  @override
  String get addToCart => '加入购物车';

  @override
  String addToCartWithQuantity(int count) {
    return '加入购物车 ($count)';
  }

  @override
  String get buyNow => '立即购买';

  @override
  String productAddedToCart(String product) {
    return '$product 已加入购物车';
  }

  @override
  String get viewCart => '查看购物车';

  @override
  String get addToCartFailed => '加入购物车失败';

  @override
  String categoryNoProducts(String category) {
    return '$category暂时没有商品';
  }

  @override
  String get cart => '购物车';

  @override
  String get productLoadFailed => '商品加载失败';

  @override
  String get clearCartFailed => '清空购物车失败';

  @override
  String get cartUpdateFailed => '购物车更新失败';

  @override
  String get checkoutLoadFailed => '结算资料加载失败';

  @override
  String get checkoutNoItems => '没有可以结算的商品';

  @override
  String get checkoutSelectAddress => '请先选择收货地址';

  @override
  String get onlyPendingPaymentCanBeCancelled => '只有待付款订单可以取消';

  @override
  String get paymentCredentialMissing => '无法初始化付款';

  @override
  String get paymentFailedTryAnotherMethod => '付款失败，请更换付款方式后重试';

  @override
  String get paymentConnectionFailed => '无法连接付款服务';

  @override
  String get paymentSessionExpired => '登录已失效，请重新登录';

  @override
  String get paymentInvalidResponse => '付款服务返回的资料格式无效';

  @override
  String get paymentCreationFailed => '无法建立付款';

  @override
  String get paymentConfirmationFailed => '无法确认付款结果';

  @override
  String get paymentUnknownError => '付款失败，请稍后重试';

  @override
  String get authConnectionFailed => '无法连接服务器，请检查网络连接';

  @override
  String get authSessionExpired => '登录已失效，请重新登录';

  @override
  String get authInvalidResponse => '服务器返回的资料格式无效';
}
