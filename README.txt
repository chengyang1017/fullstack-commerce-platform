取消未付款订单并恢复库存补丁

覆盖到项目根目录：
C:\Users\USER\Documents\Flutter\flutter_application_1

修改文件：
- server/src/services/customer_order_service.ts
- server/src/routes/customer_order_routes.ts
- lib/services/order_service.dart
- lib/repositories/order_repository.dart
- lib/providers/order_provider.dart
- lib/screens/order_details_page.dart

功能：
1. 只有 PENDING_PAYMENT 订单可以由所属用户取消。
2. 已付款、处理中、已发货等订单不能通过这个接口取消。
3. 如果订单已经建立 Stripe PaymentIntent，后端会先取消该 PaymentIntent。
4. PostgreSQL 事务内把订单设为 CANCELLED，并写入 cancelledAt。
5. 按订单商品数量恢复 Product.stock。
6. 每件商品写入一条 STOCK_IN 库存流水。
7. 重复请求取消同一订单不会重复恢复库存。
8. Flutter 订单详情页增加“取消订单”按钮和确认弹窗。

不需要 Prisma migration，现有 Order.cancelledAt 和库存流水结构已经足够。

运行：

后端：
cd C:\Users\USER\Documents\Flutter\flutter_application_1\server
npm run typecheck
npm run dev

Flutter：
cd C:\Users\USER\Documents\Flutter\flutter_application_1
dart format lib\services\order_service.dart lib\repositories\order_repository.dart lib\providers\order_provider.dart lib\screens\order_details_page.dart
flutter analyze

测试：
1. 建立一笔在线付款订单，但不要完成付款。
2. 进入订单详情，点击“取消订单”。
3. 确认订单进入“已取消”。
4. 后台商品库存恢复。
5. 再次刷新或重复请求，不应再次增加库存。
