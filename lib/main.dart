import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;

void main() {
  Stripe.publishableKey = 'your publishableKey';
  Stripe.merchantIdentifier = 'LingoBuzz';

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  MyApp({super.key});

  bool isProcessingPayment = false;
  Future<Map<String, dynamic>?> createPaymentIntent(
    String amount,
    String currency,
  ) async {
    try {
      // Calculate amount in cents
      int amountInCents = (double.parse(amount) * 100).toInt();

      Map<String, dynamic> body = {
        'amount': amountInCents.toString(),
        'currency': currency,
        'payment_method_types[]': 'card',
      };

      var response = await http.post(
        Uri.parse('https://api.stripe.com/v1/payment_intents'),
        headers: {
          'Authorization':
              'Bearer ${'Your secretKey'}',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: body,
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        debugPrint('❌ Error: ${response.body}');
        return null;
      }
    } catch (err) {
      debugPrint('❌ Error creating payment intent: $err');
      return null;
    }
  }

  //////////////////////////////
  ///

  // Make Stripe Payment
  Future<void> makeStripePayment({String? selectedPrice}) async {
    if (isProcessingPayment) return;

    try {
      isProcessingPayment = true;

      // Use the selected plan price or default
      String price = selectedPrice ?? "8.99";

      debugPrint('💳 Creating payment intent for \$$price');

      // Step 1: Create Payment Intent
      final paymentIntent = await createPaymentIntent(price, 'USD');

      if (paymentIntent == null) {
        throw Exception('Failed to create payment intent');
      }
      debugPrint('✅ Payment Intent created: ${paymentIntent['id']}');

      // Step 2: Initialize Payment Sheet
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: paymentIntent['client_secret'],
          merchantDisplayName: 'LingoBuzz', //StripeConfig.merchantDisplayName,
          style: ThemeMode.light,
          billingDetailsCollectionConfiguration:
              const BillingDetailsCollectionConfiguration(
                name: CollectionMode.always,
                email: CollectionMode.always,
              ),
        ),
      );

      debugPrint('✅ Payment sheet initialized');

      // Step 3: Present Payment Sheet
      await Stripe.instance.presentPaymentSheet();

      debugPrint('✅ c successful!');
      // Get.to(WelcomeProScreen());
    } on StripeException catch (e) {
      debugPrint('❌ Stripe Error: ${e.error.localizedMessage}');
      if (e.error.code != FailureCode.Canceled) {
        // Get.snackbar(
        //   'Payment Failed',
        //   e.error.localizedMessage ?? 'An error occurred',
        //   backgroundColor: Colors.red,
        //   colorText: Colors.white,
        //   snackPosition: SnackPosition.BOTTOM,
        // );
      }
    } catch (e) {
      debugPrint('❌ Payment failed: $e');
      // Get.snackbar(
      //   'Error',
      //   'Payment failed. Please try again.',
      //   backgroundColor: Colors.red,
      //   colorText: Colors.white,
      //   snackPosition: SnackPosition.BOTTOM,
      // );
    } finally {
      isProcessingPayment = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: Scaffold(
        body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Center(
              child: ElevatedButton(
                onPressed: () {
                  makeStripePayment();
                },
                child: Text("Pay Payment "),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
