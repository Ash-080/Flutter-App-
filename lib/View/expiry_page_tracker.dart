import 'package:FreshByte/helpers/audio_helper.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:barcode_scan2/barcode_scan2.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

void main() {
  runApp(MaterialApp(home: ExpiryPage()));
}

class ExpiryPage extends StatefulWidget {
  @override
  _ExpiryPageState createState() => _ExpiryPageState();
}

class _ExpiryPageState extends State<ExpiryPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  DateTime? _selectedDate;
  String? _scannedBarcode;
  String? _imageUrl;

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
    _checkAndSendExpiryNotifications();
  }

  void _initializeNotifications() async {
    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings settings = InitializationSettings(android: androidSettings);
    await _localNotifications.initialize(settings);
    _firebaseMessaging.requestPermission();
  }

  Future<void> _checkAndSendExpiryNotifications() async {
    final now = DateTime.now();
    final snapshot = await _firestore.collection('expiry_items').get();

    for (var doc in snapshot.docs) {
      final data = doc.data();
      DateTime expiryDate = DateFormat('yyyy-MM-dd').parse(data['expiryDate']);
      int daysLeft = expiryDate.difference(now).inDays;

      // Convert daysLeft into readable text
      String dayText = (daysLeft == 0) ? "Today" : (daysLeft == 1) ? "Tomorrow" : "$daysLeft days left";

      if (daysLeft <= 2 && data['notificationSent'] == false) {
        _sendLocalNotification(data['name'], dayText);
        _firestore.collection('expiry_items').doc(doc.id).update({'notificationSent': true});
      }
    }
  }

  void _sendLocalNotification(String itemName, String dayText) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'expiry_channel', 'Expiry Notifications',
      importance: Importance.high, priority: Priority.high,
    );
    const NotificationDetails platformDetails = NotificationDetails(android: androidDetails);
    await _localNotifications.show(
      0,
      'Expiry Alert!',
      '$itemName expires $dayText!',
      platformDetails,
    );
  }

  void _addExpiryItem(String name, String quantity, DateTime expiryDate) {
    _firestore.collection('expiry_items').add({
      'name': name,
      'quantity': quantity.isNotEmpty ? quantity : 'Not specified',
      'expiryDate': DateFormat('yyyy-MM-dd').format(expiryDate),
      'imageUrl': _imageUrl ?? '',
      'notificationSent': false,
    });
    setState(() {});
  }

  Future<void> _scanBarcode() async {
    var result = await BarcodeScanner.scan();
    if (result.rawContent.isEmpty) return;

    setState(() {
      _scannedBarcode = result.rawContent;
    });
    await AudioHelper.playBeepSound();
    await _fetchProductDetails(_scannedBarcode!);
  }

  Future<void> _fetchProductDetails(String barcode) async {
    final response = await http.get(Uri.parse("https://world.openfoodfacts.org/api/v0/product/$barcode.json"));
    if (response.statusCode == 200) {
      var data = jsonDecode(response.body);
      setState(() {
        _nameController.text = data['product']['product_name'] ?? "";
        _imageUrl = data['product']['image_url'] ?? "";
      });
    }
  }

  Color _getExpiryColor(int daysLeft) {
    if (daysLeft == 0 || daysLeft == 1) return Color(0xFFF8BBBB); // Urgent (Today/Tomorrow)
    if (daysLeft <= 5) return Color(0xFFFFDDA4); // Upcoming
    return Color(0xFFCBE4C9); // Safe
  }

  IconData _getItemIcon(String name) {
    if (name.toLowerCase().contains("egg")) return Icons.egg;
    if (name.toLowerCase().contains("bread")) return Icons.bakery_dining;
    if (name.toLowerCase().contains("milk")) return Icons.local_drink;
    if (name.toLowerCase().contains("fruit")) return Icons.apple;
    return Icons.fastfood;
  }

  void _deleteItem(String docId) {
    _firestore.collection('expiry_items').doc(docId).delete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Expiry Tracker", style: TextStyle(color: Colors.white)),
        backgroundColor: Color(0xFF334463),
      ),
      body: Container(
        padding: EdgeInsets.all(12),
        color: Color(0xFFF3F3F6),
        child: Column(
          children: [
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 3,
              color: Color(0xFFD9E5ED),
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Column(
                  children: [
                    TextField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: "Item Name",
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.fastfood, color: Colors.grey),
                      ),
                    ),
                    SizedBox(height: 10),
                    TextField(
                      controller: _quantityController,
                      decoration: InputDecoration(
                        labelText: "Quantity (e.g., 2 liters)",
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.scale, color: Colors.grey),
                      ),
                    ),
                    SizedBox(height: 10),
                    ElevatedButton.icon(
                      icon: Icon(Icons.qr_code_scanner),
                      label: Text("Scan Barcode"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF6F9CCA),
                        foregroundColor: Colors.white,
                      ),
                      onPressed: _scanBarcode,
                    ),
                    SizedBox(height: 10),
                    ElevatedButton.icon(
                      icon: Icon(Icons.calendar_today),
                      label: Text(_selectedDate == null ? "Select Expiry Date" : "Selected: ${DateFormat('yyyy-MM-dd').format(_selectedDate!)}"),
                      style: ElevatedButton.styleFrom(backgroundColor: Color(
                          0xFFDDE0F1)),
                      onPressed: () async {
                        DateTime? pickedDate = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate: DateTime(2101),
                        );
                        if (pickedDate != null) {
                          setState(() => _selectedDate = pickedDate);
                        }
                      },
                    ),
                    SizedBox(height: 10),
                    ElevatedButton.icon(
                      icon: Icon(Icons.add),
                      label: Text("Add Item"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF516FAF),
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () {
                        if (_nameController.text.isNotEmpty && _selectedDate != null) {
                          _addExpiryItem(_nameController.text, _quantityController.text, _selectedDate!);
                          _nameController.clear();
                          _quantityController.clear();
                          setState(() => _selectedDate = null);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("Please enter name and expiry date")),
                          );
                        }
                      },
                    ),

                  ],
                ),
              ),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore.collection('expiry_items').snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
                  return ListView(
                    children: snapshot.data!.docs.map((doc) {
                      var item = doc.data() as Map<String, dynamic>;
                      return Card(
                        color: _getExpiryColor(DateTime.parse(item['expiryDate']).difference(DateTime.now()).inDays),
                        child: ListTile(
                          leading: item['imageUrl'] != null && item['imageUrl'].isNotEmpty
                              ? Image.network(item['imageUrl'], width: 50, height: 50, fit: BoxFit.cover)
                              : Icon(_getItemIcon(item['name']), size: 40, color: Colors.white),
                          title: Text(item['name']),
                          subtitle: Text("Expiry: ${item['expiryDate']}"),
                          trailing: IconButton(
                            icon: Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deleteItem(doc.id),
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
