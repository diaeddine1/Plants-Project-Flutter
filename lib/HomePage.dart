import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_plants/PlantDetail.dart';

class Plant {
  final String name;
  final String category;
  final String properties;
  final String precautions;
  final String uses;
  final String imageUrl;
  final String interactions;

  Plant({
    required this.name,
    required this.category,
    required this.properties,
    required this.precautions,
    required this.uses,
    required this.imageUrl,
    required this.interactions,
  });

  factory Plant.fromFirestore(Map<String, dynamic> data) {
    return Plant(
      name: data['name'] ?? '',
      category: data['category'] ?? '',
      properties: data['properties'] ?? '',
      precautions: data['precautions'] ?? '',
      uses: data['uses'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      interactions: data['interactions'] ?? '',
    );
  }
}

class PlantsPage extends StatefulWidget {
  @override
  _PlantsPageState createState() => _PlantsPageState();
}

class _PlantsPageState extends State<PlantsPage> {
  List<String> _categories = ['All Plants'];
  String _selectedCategory = 'All Plants';

  TextEditingController _searchController = TextEditingController();

  Future<List<Plant>> _filteredPlantsFuture = Future.value([]);

  @override
  void initState() {
    super.initState();
    _fetchCategories();
    _filterPlantsByCategory(_selectedCategory);
  }

  Future<void> _fetchCategories() async {
    try {
      var categories = Set<String>();
      var querySnapshot = await FirebaseFirestore.instance.collection('plants').get();

      querySnapshot.docs.forEach((doc) {
        categories.add(doc['category']);
      });

      setState(() {
        _categories = ['All Plants', ...categories.toList()];
      });
    } catch (error) {
      print('Error fetching categories: $error');
    }
  }

  Future<List<Plant>> _getAllPlants() async {
    try {
      var plantsSnapshot = await FirebaseFirestore.instance.collection('plants').get();
      return plantsSnapshot.docs
          .map((doc) => Plant.fromFirestore(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (error) {
      print('Error fetching plants: $error');
      return [];
    }
  }

  void _filterPlantsByCategory(String category) {
    setState(() {
      _selectedCategory = category;
      _filteredPlantsFuture = _getAllPlants().then((allPlants) {
        return _selectedCategory == 'All Plants'
            ? allPlants
            : allPlants.where((plant) => plant.category == _selectedCategory).toList();
      });
    });
  }

  void _filterPlantsByNameOrUses(String searchTerm) {
    setState(() {
      _filteredPlantsFuture = _getAllPlants().then((allPlants) {
        return allPlants.where((plant) {
          return (plant.category == _selectedCategory || _selectedCategory == 'All Plants') &&
              (plant.name.toLowerCase().contains(searchTerm.toLowerCase()) ||
                  plant.uses.toLowerCase().contains(searchTerm.toLowerCase()));
        }).toList();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Plants'),
        backgroundColor: Colors.teal,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                _filterPlantsByNameOrUses(value);
              },
              decoration: InputDecoration(
                labelText: 'Search by Name or Uses',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Container(
            padding: EdgeInsets.all(16.0),
            child: Wrap(
              spacing: 8.0,
              children: _categories.map((category) {
                return ElevatedButton(
                  onPressed: () {
                    _filterPlantsByCategory(category);
                  },
                  style: ElevatedButton.styleFrom(
                    primary: _selectedCategory == category ? Colors.teal : null,
                  ),
                  child: Text(category),
                );
              }).toList(),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Plant>>(
              future: _filteredPlantsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(),
                  );
                }

                var plants = snapshot.data ?? [];

                if (plants.isEmpty) {
                  return Center(
                    child: Text('No plants found.'),
                  );
                }

                return ListView.builder(
                  itemCount: plants.length,
                  itemBuilder: (context, index) {
                    return Card(
                      elevation: 5.0,
                      margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                      child: ListTile(
                        title: Text(
                          plants[index].name,
                          style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Category: ${plants[index].category}'),
                            SizedBox(height: 4.0),
                            Text('Uses: ${plants[index].uses}'),
                          ],
                        ),
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8.0),
                          child: CachedNetworkImage(
                            imageUrl: plants[index].imageUrl,
                            placeholder: (context, url) => CircularProgressIndicator(),
                            errorWidget: (context, url, error) => Icon(Icons.error),
                            width: 80.0,
                            height: 80.0,
                            fit: BoxFit.cover,
                          ),
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PlantDetailPage(plant: plants[index]),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

void main() {
  runApp(MaterialApp(
    home: PlantsPage(),
  ));
}
