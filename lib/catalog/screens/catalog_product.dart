import 'package:batikalongan_mobile/auth/screens/login.dart';
import 'package:batikalongan_mobile/catalog/models/catalog_model.dart';
import 'package:batikalongan_mobile/catalog/screens/catalog_store.dart';
import 'package:batikalongan_mobile/catalog/widgets/product_card.dart';
import 'package:batikalongan_mobile/widgets/bottom_navbar.dart'; // Import BottomNavbar widget
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:batikalongan_mobile/config/config.dart';
import 'package:batikalongan_mobile/timeline/screens/timeline_screen.dart';
import 'package:batikalongan_mobile/gallery/screens/gallery_screen.dart';
import 'package:batikalongan_mobile/article/screens/artikel_screen.dart';

import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';


class ProductCatalog extends StatefulWidget {
  const ProductCatalog({Key? key}) : super(key: key);

  @override
  State<ProductCatalog> createState() => _ProductCatalogState();
}

class _ProductCatalogState extends State<ProductCatalog> {
  Future<List<Product>> fetchProducts() async {
    const String url = Config.baseUrl + '/catalog/products/json/';
    const String storeUrl = Config.baseUrl + '/catalog/json/';

    // First fetch stores to resolve foreign keys
    final storeResponse = await http.get(Uri.parse(storeUrl));
    if (storeResponse.statusCode != 200) {
      throw Exception('Failed to load stores');
    }
    final stores = storeFromJson(storeResponse.body);

    // Then fetch products
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      return productFromJson(response.body, stores);
    } else {
      throw Exception('Failed to load products');
    }
  }

  int currentPage = 1;
  final int totalPages = 7;

  int _currentIndex = 0; // Set index sesuai dengan halaman "Product Catalog"

  @override
  Widget build(BuildContext context) {
    final request = context.watch<CookieRequest>();
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: const [
            Text(
              'Halo, ',
              style: TextStyle(color: Colors.black87),
            ),
            Text(
              'Aileen',
              style: TextStyle(color: Colors.orange),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.orange),
            onPressed: () async {
              final response = await request
                  .logout("http://127.0.0.1:8000/auth/api/logout/");
              String message = response["message"];
              if (context.mounted) {
                if (response['status']) {
                  String uname = response["username"];
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text("$message Sampai jumpa, $uname."),
                  ));
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginPage()),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(message),
                    ),
                  );
                }
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const CatalogStores()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: const BorderSide(color: Colors.orange),
                    ),
                    child: const Text(
                      'Toko Batik',
                      style: TextStyle(color: Colors.orange),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Produk Batik'),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Product>>(
              future: fetchProducts(),
              builder: (context, AsyncSnapshot<List<Product>> snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No products available.'));
                }

                final products = snapshot.data!;
                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.8,
                  ),
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    return ProductCard(product: products[index]);
                  },
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios, size: 18),
                  onPressed: currentPage > 1
                      ? () => setState(() => currentPage--)
                      : null,
                ),
                for (int i = 1; i <= totalPages; i++)
                  if (i == 1 ||
                      i == totalPages ||
                      (i >= currentPage - 1 && i <= currentPage + 1))
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color:
                              currentPage == i ? Colors.orange : Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Center(
                          child: Text(
                            '$i',
                            style: TextStyle(
                              color: currentPage == i
                                  ? Colors.white
                                  : Colors.black,
                            ),
                          ),
                        ),
                      ),
                    )
                  else if (i == currentPage - 2 || i == currentPage + 2)
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4.0),
                      child: Text('...'),
                    ),
                IconButton(
                  icon: const Icon(Icons.arrow_forward_ios, size: 18),
                  onPressed: currentPage < totalPages
                      ? () => setState(() => currentPage++)
                      : null,
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavbar(
        currentIndex: _currentIndex,
        onTap: (index) {
          if (index == 0) {
            // Navigator.pushReplacement(
            //   context,
            //   MaterialPageRoute(builder: (context) => const ProductCatalog()),
            // );
          }
          if (index == 1) {
            // Tetap di halaman ini
          }
          if (index == 2) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const GalleryScreen()),
            );
          }
          if (index == 3) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const ArtikelScreen()),
            );
          }
          if (index == 4) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const TimeLineScreen()),
            );
          }
        },
      ),
    );
  }
}
