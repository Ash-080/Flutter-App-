import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class MyDonationsPage extends StatefulWidget {
  @override
  _MyDonationsPageState createState() => _MyDonationsPageState();
}

class _MyDonationsPageState extends State<MyDonationsPage> {
  final Color cardColor = Color(0xFFF4E1CC); // Soft Peach
  final Color iconColor = Color(0xFF8F774E); // Muted Purple
  final Color textColor = Color(0xFF243127); // Dark Green

  Future<void> _pickDate(DocumentSnapshot donation) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2022),
      lastDate: DateTime(2030),
    );

    if (picked != null) {
      FirebaseFirestore.instance
          .collection('donations')
          .doc(donation.id)
          .update({'donation_date': picked});
    }
  }

  Future<void> _captureImage(DocumentSnapshot donation) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera);

    if (pickedFile != null) {
      FirebaseFirestore.instance
          .collection('donations')
          .doc(donation.id)
          .update({'memory_image': pickedFile.path});
    }
  }

  Future<void> _deleteDonation(String donationId) async {
    await FirebaseFirestore.instance.collection('donations').doc(donationId).delete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("My Donations"),
        backgroundColor: iconColor,
      ),
      backgroundColor: Color(0xFFEFEBE5),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance.collection('donations').snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (!snapshot.hasData) return Center(child: CircularProgressIndicator());

          return ListView(
            padding: EdgeInsets.all(12),
            children: snapshot.data!.docs.map((doc) {
              Map<String, dynamic> donation = doc.data() as Map<String, dynamic>;
              String formattedDate = donation['donation_date'] != null
                  ? DateFormat('dd MMM yyyy').format(donation['donation_date'].toDate())
                  : "Not Set";

              return Card(
                color: cardColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                margin: EdgeInsets.symmetric(vertical: 10),
                child: Padding(
                  padding: EdgeInsets.all(15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              donation['ngo_name'] ?? "NGO Name",
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
                              softWrap: true,
                            ),
                          ),
                          IconButton(
                            onPressed: () => _deleteDonation(doc.id),
                            icon: Icon(Icons.delete, color: Colors.red),
                          ),
                        ],
                      ),
                      Divider(color: Colors.black26),
                      SizedBox(height: 5),
                      Row(
                        children: [
                          Icon(Icons.fastfood, color: iconColor),
                          SizedBox(width: 5),
                          Text("Food: ${donation['food_item'] ?? 'N/A'}"),
                        ],
                      ),
                      SizedBox(height: 5),
                      Row(
                        children: [
                          Icon(Icons.numbers, color: iconColor),
                          SizedBox(width: 5),
                          Text("Quantity: ${donation['quantity'] ?? 'N/A'}"),
                        ],
                      ),
                      SizedBox(height: 5),
                      Row(
                        children: [
                          Icon(Icons.location_on, color: Colors.red),
                          SizedBox(width: 5),
                          Text("Location: ${donation['location'] ?? 'N/A'}"),
                        ],
                      ),
                      SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.date_range, color: Colors.green),
                              SizedBox(width: 5),
                              Text(formattedDate, style: TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                          IconButton(
                            onPressed: () => _pickDate(doc),
                            icon: Icon(Icons.calendar_today, color: Colors.blue),
                          ),
                        ],
                      ),
                      SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.camera_alt, color: Colors.purple),
                              SizedBox(width: 5),
                              Text("Memory:"),
                            ],
                          ),
                          IconButton(
                            onPressed: () => _captureImage(doc),
                            icon: Icon(Icons.camera, color: Colors.blue),
                          ),
                        ],
                      ),

                      // ✅ Image Display Section
                      if (donation['memory_image'] != null)
                        Builder(
                          builder: (context) {
                            File imageFile = File(donation['memory_image']);
                            if (imageFile.existsSync()) {
                              return Padding(
                                padding: EdgeInsets.only(top: 10),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.file(
                                    imageFile,
                                    height: 150,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) =>
                                        Icon(Icons.broken_image, size: 100),
                                  ),
                                ),
                              );
                            } else {
                              return SizedBox(); // Hides if file doesn't exist
                            }
                          },
                        ),
                    ],
                  ),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
