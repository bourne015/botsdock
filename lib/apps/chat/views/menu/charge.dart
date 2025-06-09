import 'package:botsdock/apps/chat/models/user.dart';
import 'package:botsdock/apps/chat/routes.dart' as routes;
import 'package:botsdock/apps/chat/utils/client/dio_client.dart';
import 'package:botsdock/apps/chat/utils/client/path.dart';
import 'package:botsdock/apps/chat/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:web/web.dart' as web;

class ChargePage extends StatefulWidget {
  final User user;

  ChargePage({super.key, required this.user});

  @override
  _ChargePageState createState() => _ChargePageState();
}

class _ChargePageState extends State<ChargePage> {
  String selectedAmount = '';
  String selectedPayment = 'alipay';
  bool showCustomInput = false;
  final List<String> amounts = ['10', '20', '50', '100', '300', '500'];
  final TextEditingController customAmountController = TextEditingController();
  final dio = DioClient();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('充值', style: Theme.of(context).textTheme.headlineSmall),
          SizedBox(height: 20),
          Text('支付金额', style: Theme.of(context).textTheme.bodyMedium),
          SizedBox(height: 10),
          GridView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 2.5,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: amounts.length + 1,
            itemBuilder: (context, index) {
              if (index < amounts.length) {
                return _buildAmountButton(amounts[index]);
              } else {
                return _buildCustomButton();
              }
            },
          ),
          SizedBox(height: 20),
          if (showCustomInput) ...[
            TextField(
                controller: customAmountController,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                      // borderSide: BorderSide.none,
                      borderRadius: BORDERRADIUS10),
                  focusedBorder: OutlineInputBorder(
                      // borderSide: BorderSide.none,
                      borderRadius: BORDERRADIUS10),
                  hintText: '请输入1元至1000元之间的金额',
                  hintStyle: Theme.of(context).textTheme.labelMedium,
                  prefixText: '¥ ',
                  prefixStyle: TextStyle(color: Colors.black),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  setState(() {});
                }),
            SizedBox(height: 30),
          ],
          Text('支付方式', style: Theme.of(context).textTheme.bodyMedium),
          SizedBox(height: 10),
          Container(
            margin: EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: selectedPayment == 'alipay'
                    ? Colors.blue
                    : Colors.grey[300]!,
              ),
            ),
            child: ListTile(
              leading: Image.asset(
                width: 30,
                height: 30,
                'assets/images/chat/alipay.png',
              ),
              title: Text('支付宝'),
              trailing: Radio<String>(
                value: 'alipay',
                groupValue: selectedPayment,
                onChanged: (value) {
                  setState(() {
                    selectedPayment = value!;
                  });
                },
              ),
              onTap: () {
                setState(() {
                  selectedPayment = 'alipay';
                });
              },
            ),
          ),
          SizedBox(height: 30),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: canPay
                  ? () {
                      _handlePayment();
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                elevation: canPay ? 5 : 0,
              ),
              child: Text(
                '去支付',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          SizedBox(height: 20),
          Text('提示', style: Theme.of(context).textTheme.bodyMedium),
          Text(
            '遇充值问题请联系phantasy018@gmail.com',
            style: Theme.of(context).textTheme.labelMedium,
          ),
        ],
      ),
    );
  }

  bool get canPay {
    if (showCustomInput) {
      String amount = customAmountController.text.trim();
      if (amount.isEmpty) return false;

      double amountValue = double.tryParse(amount) ?? 0;
      return amountValue >= 1 && amountValue <= 1000;
    } else {
      return selectedAmount.isNotEmpty;
    }
  }

  Widget _buildAmountButton(String amount) {
    bool isSelected = selectedAmount == amount;
    return GestureDetector(
      onTap: () {
        setState(() {
          showCustomInput = false;
          selectedAmount = amount;
          customAmountController.clear();
        });
      },
      child: Container(
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.secondaryFixed
              : Theme.of(context).colorScheme.secondaryContainer,
          borderRadius: BORDERRADIUS10,
          border: isSelected ? Border.all(color: Colors.white, width: 1) : null,
        ),
        child: Center(
          child: Text('¥${amount}'),
        ),
      ),
    );
  }

  Widget _buildCustomButton() {
    bool isSelected = showCustomInput;
    return GestureDetector(
      onTap: () {
        setState(() {
          showCustomInput = true;
          selectedAmount = '';
        });
      },
      child: Container(
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.secondaryFixed
              : Theme.of(context).colorScheme.secondaryContainer,
          borderRadius: BORDERRADIUS10,
          border: isSelected ? Border.all(color: Colors.white, width: 1) : null,
        ),
        child: Center(
          child: Text('自定义'),
        ),
      ),
    );
  }

  Future<void> _handlePayment() async {
    String _chargeVal = '';
    if (selectedAmount.isNotEmpty) {
      _chargeVal = selectedAmount;
    } else if (customAmountController.text.trim().isNotEmpty) {
      _chargeVal = customAmountController.text.trim();
    }
    var _param = {
      "name": "chat",
      "money": _chargeVal,
      "type": "alipay",
    };
    final response = await dio.get(
      ChatPath.newOrder(widget.user.id),
      queryParameters: _param,
    );
    launchUrl(Uri.parse(response["url"]!));
  }
}

Map<String, String> parseUrlParams() {
  final uri = Uri.parse(web.window.location.href);
  return uri.queryParameters;
}

void clearUrlQueryParams() {
  final path = web.window.location.pathname + web.window.location.hash;
  web.window.history.replaceState(null, '支付结果', path);
}

class PayResultPage extends StatelessWidget {
  final params;
  const PayResultPage({Key? key, required this.params}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final tradeStatus = params['trade_status'];
    final orderNo = params['out_trade_no'] ?? '';
    final money = params['money'] ?? '';
    final payType = params['type'] ?? '';
    final name = params['name'] ?? '';

    Widget resultWidget;

    if (tradeStatus == 'TRADE_SUCCESS') {
      resultWidget = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle, color: Colors.green, size: 80),
          SizedBox(height: 16),
          Text('支付成功！', style: TextStyle(fontSize: 24)),
          SizedBox(height: 12),
          if (money.isNotEmpty)
            Text('支付金额：$money 元', style: TextStyle(fontSize: 18)),
          if (orderNo.isNotEmpty)
            Text('订单号：$orderNo', style: TextStyle(fontSize: 16)),
          if (name.isNotEmpty) Text('商品：$name', style: TextStyle(fontSize: 16)),
          if (payType.isNotEmpty)
            Text(
                '支付方式：${payType == "alipay" ? "支付宝" : payType == "wxpay" ? "微信" : payType}',
                style: TextStyle(fontSize: 16)),
          SizedBox(height: 24),
          Text(
            '如支付遇到延迟，请稍后在账单中查看到账状态',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      );
    } else if (tradeStatus == null) {
      resultWidget = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.help_outline, color: Colors.orange, size: 80),
          SizedBox(height: 16),
          Text('未检测到支付信息', style: TextStyle(fontSize: 22)),
          SizedBox(height: 12),
          Text('请通过正规支付渠道访问支付结果页。', style: TextStyle(fontSize: 16)),
        ],
      );
    } else {
      resultWidget = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error, color: Colors.red, size: 80),
          SizedBox(height: 16),
          Text('支付未成功', style: TextStyle(fontSize: 24)),
          SizedBox(height: 12),
          if (orderNo.isNotEmpty)
            Text('订单号：$orderNo', style: TextStyle(fontSize: 16)),
          if (name.isNotEmpty) Text('商品：$name', style: TextStyle(fontSize: 16)),
          if (tradeStatus != null)
            Text('状态码：$tradeStatus', style: TextStyle(fontSize: 16)),
          SizedBox(height: 18),
          Text(
            '如已支付成功，请联系平台客服处理。',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('支付结果')),
      body: Center(
        child: resultWidget,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton(
        backgroundColor: Theme.of(context).colorScheme.secondaryFixed,
        child: const Text('OK'),
        onPressed: () {
          Navigator.pushNamed(context, routes.homeRoute);
        },
      ),
    );
  }
}
