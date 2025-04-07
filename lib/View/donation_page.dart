import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'MyDonationsPage.dart';


class DonateFoodPage extends StatefulWidget {
  @override
  _DonateFoodPageState createState() => _DonateFoodPageState();
}

class _DonateFoodPageState extends State<DonateFoodPage> {
  final TextEditingController _foodController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  String _selectedFreshness = "Fresh";
  List<Map<String, dynamic>> _ngos = [];
  List<Map<String, dynamic>> _filteredNgos = [];
  bool _showNgos = false;
  String? _selectedNgo;

  @override
  void initState() {
    super.initState();
    _fetchNGOs();
  }

  void _fetchNGOs() async {
    FirebaseFirestore.instance.collection('ngos').get().then((snapshot) {
      List<Map<String, dynamic>> ngos = snapshot.docs.map((doc) => doc.data()).toList();
      setState(() {
        _ngos = ngos;
      });
    });
  }

  void _filterNGOs() {
    String query = _locationController.text.trim().toLowerCase();
    setState(() {
      _filteredNgos = _ngos.where((ngo) {
        String address = (ngo['address'] ?? '').toLowerCase();
        return address.contains(query);
      }).toList();
      _showNgos = true;
    });
  }

  void _openMap(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Unable to open link")));
    }
  }

  void _saveDonation() {
    if (_selectedNgo == null || _foodController.text.isEmpty || _quantityController.text.isEmpty || _locationController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Please fill all fields")));
      return;
    }

    FirebaseFirestore.instance.collection('donations').add({
      'ngo_name': _selectedNgo,
      'food_item': _foodController.text.trim(),
      'quantity': _quantityController.text.trim(),
      'location': _locationController.text.trim(),
      'memory_image':"",
      'date': DateTime.now(),
    });

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Donation saved!")));
    _foodController.clear();
    _quantityController.clear();
    _locationController.clear();
    setState(() {
      _selectedNgo = null;
      _showNgos = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Donate Food"),
        backgroundColor: Color(0xFFAF966B), // Muted Purple
        actions: [
          IconButton(
            icon: Icon(Icons.history),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => MyDonationsPage()));
            },
          ),
        ],
      ),
      backgroundColor: Color(0xFFF1E5D9), // Soft Peach
      body: SingleChildScrollView(
        padding: EdgeInsets.all(12),
        child: Column(
          children: [
            if (_ngos.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Featured NGOs", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  SizedBox(height: 5),
                  CarouselSlider(
                    options: CarouselOptions(
                      height: 230,
                      autoPlay: true,
                      autoPlayInterval: Duration(seconds: 3),
                      enlargeCenterPage: true,
                      viewportFraction: 0.85,
                    ),
                    items: _ngos.map((ngo) {
                      return Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(15),
                            child: Image.network(
                              ngo['Ngoimage'] ?? 'https://via.placeholder.com/250',
                              width: double.infinity,
                              height: 230,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.all(12),
                            alignment: Alignment.bottomLeft,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [Colors.black.withOpacity(0.0), Colors.black.withOpacity(0.7)],
                              ),
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Text(
                              ngo['name'] ?? "NGO Name",
                              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ],
              ),
            SizedBox(height: 15),

            Container(
              padding: EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Color(0xFFF4F4F4),
                borderRadius: BorderRadius.circular(15),
                boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 6)],
              ),
              child: Column(
                children: [
                  TextField(
                    controller: _foodController,
                    decoration: InputDecoration(labelText: "Food Item", prefixIcon: Icon(Icons.fastfood), border: OutlineInputBorder()),
                  ),
                  SizedBox(height: 10),
                  TextField(
                    controller: _quantityController,
                    decoration: InputDecoration(labelText: "Quantity", prefixIcon: Icon(Icons.numbers), border: OutlineInputBorder()),
                  ),
                  SizedBox(height: 10),
                  TextField(
                    controller: _locationController,
                    decoration: InputDecoration(labelText: "Location", prefixIcon: Icon(Icons.location_on), border: OutlineInputBorder()),
                  ),
                  SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: _filterNGOs,
                    style: ElevatedButton.styleFrom(backgroundColor: Color(0xFFA46379)), // Muted Purple
                    child: Text("Find NGOs", style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),

            if (_showNgos)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: _filteredNgos.map((ngo) {
                  return Card(
                    color: Color(0xFFE8D4D4),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      leading: Icon(Icons.apartment, color: Color(0xFFA46379)), // Muted Purple
                      title: Text(ngo['name'] ?? "NGO Name", style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [Icon(Icons.access_time, size: 16, color: Colors.blue), SizedBox(width: 5), Text("Hours: ${ngo['hours'] ?? 'N/A'}")]),
                          Row(children: [Icon(Icons.phone, size: 16, color: Colors.green), SizedBox(width: 5), Text("Contact: ${ngo['contact'] ?? 'N/A'}")]),
                          Row(children: [Icon(Icons.location_on, size: 16, color: Colors.red), SizedBox(width: 5), Expanded(child: Text("Address: ${ngo['address'] ?? 'N/A'}"))]),
                          TextButton.icon(
                            onPressed: () => _openMap(ngo['map'] ?? ""),
                            icon: Icon(Icons.map, size: 18, color: Colors.blue),
                            label: Text("Get Directions", style: TextStyle(color: Colors.blue)),
                          ),
                        ],
                      ),
                      onTap: () {
                        setState(() {
                          _selectedNgo = ngo['name'];
                        });
                      },
                    ),
                  );
                }).toList(),
              ),
            SizedBox(height: 20),

            ElevatedButton(
              onPressed: _saveDonation,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green), // Green donate button
              child: Text("Add", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
