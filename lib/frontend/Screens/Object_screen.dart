import 'package:avto/Core/Theme.dart';
import 'package:avto/Widget/choice_Theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';

class ObjectsInfoPage extends StatefulWidget {
  final String calendarId;

  const ObjectsInfoPage({super.key, required this.calendarId});

  @override
  State<ObjectsInfoPage> createState() => _ObjectsInfoPageState();
}

class _ObjectsInfoPageState extends State<ObjectsInfoPage> {
  List<Map<String, dynamic>> objects = [];
  Map<String, dynamic>? selectedObject;
  Future<String> getAddress(double lat, double lon) async {
    final url = Uri.parse(
      "https://nominatim.openstreetmap.org/reverse"
      "?format=json"
      "&lat=$lat"
      "&lon=$lon",
    );

    final response = await http.get(
      url,
      headers: {"User-Agent": "avto-calendar-app"},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      final address = data["address"];

      final road = address["road"] ?? "";
      final house = address["house_number"] ?? "";
      final city =
          address["city"] ?? address["town"] ?? address["village"] ?? "";
      final country = address["country"] ?? "";

      return "$road $house, $city, $country";
    }

    return "Ошибка загрузки адреса";
  }

  String currentUserRole = "observer";

  bool get canEdit =>
      currentUserRole == "admin" || currentUserRole == "manager";

  String? selectedObjectId;
  String? pendingImageUrl;
  final TextEditingController descriptionController = TextEditingController();

  String name = '';
  String? imageUrl;
  double? latitude;
  double? longitude;

  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadRole();
    loadObjects();
  }

  Future<void> loadObjects() async {
    final doc = await FirebaseFirestore.instance
        .collection('calendars')
        .doc(widget.calendarId)
        .get();

    final data = doc.data();

    if (data == null) return;

    setState(() {
      objects = (data['objects'] as List? ?? [])
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
      loading = false;
    });
  }

  Future<void> loadRole() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    final doc = await FirebaseFirestore.instance
        .collection('calendars')
        .doc(widget.calendarId)
        .collection('members')
        .doc(uid)
        .get();

    if (!mounted) return;

    setState(() {
      currentUserRole = doc.data()?['role'] ?? 'observer';
    });
  }

  Future<String?> uploadToCloudinary() async {
    final picker = ImagePicker();

    final XFile? file = await picker.pickImage(source: ImageSource.gallery);

    if (file == null) return null;

    final bytes = await file.readAsBytes();

    final uri = Uri.parse(
      'https://api.cloudinary.com/v1_1/dbpwoxlm2/image/upload',
    );

    final request = http.MultipartRequest('POST', uri);

    request.fields['upload_preset'] = 'objects_upload';

    request.files.add(
      http.MultipartFile.fromBytes('file', bytes, filename: file.name),
    );

    final response = await request.send();

    final responseBody = await response.stream.bytesToString();

    final data = jsonDecode(responseBody);

    return data['secure_url'];
  }

  Future<void> deletePhoto() async {
    setState(() {
      imageUrl = null;
      pendingImageUrl = '';
    });
  }

  Future<void> pickImage() async {
    if (selectedObject == null) return;

    final url = await uploadToCloudinary();

    if (url == null) return;

    setState(() {
      pendingImageUrl = url;
      imageUrl = url;
    });
  }

  Future<void> saveObject() async {
    if (selectedObject == null) return;

    final index = objects.indexOf(selectedObject!);

    objects[index]['description'] = descriptionController.text;

    objects[index]['imageUrl'] = pendingImageUrl ?? imageUrl;

    await FirebaseFirestore.instance
        .collection('calendars')
        .doc(widget.calendarId)
        .update({'objects': objects});

    setState(() {
      selectedObject = objects[index];
      pendingImageUrl = null;
    });

    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Изменения сохранены")));
  }

  @override
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: ThemeDataChoice.value == White_ThemeData
                ? const AssetImage("assets/images/seaback.jpg")
                : const AssetImage("assets/images/greyback.jpg"),
            fit: BoxFit.cover,
          ),
        ),

        child: Center(
          child: Container(
            width: 900,
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.all(25),

            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.25),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(color: Colors.white54),
            ),

            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// ШАПКА
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () {
                          Navigator.pop(context);
                        },
                      ),

                      const Expanded(
                        child: Text(
                          "Объекты календаря",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                      const Icon(
                        Icons.location_city,
                        color: Colors.white,
                        size: 35,
                      ),
                    ],
                  ),

                  const SizedBox(height: 25),

                  /// ВЫБОР ОБЪЕКТА
                  const Text(
                    "Выберите объект",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 10),

                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 15),

                    decoration: BoxDecoration(
                      color: Colors.white70,
                      borderRadius: BorderRadius.circular(15),
                    ),

                    child: DropdownButtonFormField<Map<String, dynamic>>(
                      value: selectedObject,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                      ),

                      items: objects.map((obj) {
                        return DropdownMenuItem(
                          value: obj,
                          child: Text(obj['name'] ?? "Без названия"),
                        );
                      }).toList(),

                      onChanged: (value) {
                        if (value == null) return;

                        setState(() {
                          selectedObject = value;

                          name = value['name'] ?? "";
                          imageUrl = value['imageUrl'];

                          latitude = (value['latitude'] as num?)?.toDouble();

                          longitude = (value['longitude'] as num?)?.toDouble();

                          descriptionController.text =
                              value['description'] ?? "";
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 20),

                  if (selectedObject != null) ...[
                    /// НАЗВАНИЕ
                    Center(
                      child: Text(
                        name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    /// ФОТО ОБЪЕКТА
                    Container(
                      width: double.infinity,
                      height: 280,

                      clipBehavior: Clip.antiAlias,

                      decoration: BoxDecoration(
                        color: Colors.white70,
                        borderRadius: BorderRadius.circular(20),
                      ),

                      child: imageUrl != null && imageUrl!.isNotEmpty
                          ? Image.network(imageUrl!, fit: BoxFit.cover)
                          : const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.image,
                                    size: 90,
                                    color: Colors.grey,
                                  ),

                                  SizedBox(height: 10),

                                  Text(
                                    "Фото отсутствует",
                                    style: TextStyle(fontSize: 18),
                                  ),
                                ],
                              ),
                            ),
                    ),

                    const SizedBox(height: 15),

                    /// КНОПКИ ФОТО
                    if (canEdit)
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.upload),

                              label: const Text("Загрузить фото"),

                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                minimumSize: const Size(0, 50),
                              ),

                              onPressed: pickImage,
                            ),
                          ),

                          const SizedBox(width: 15),

                          Expanded(
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.delete),

                              label: const Text("Удалить фото"),

                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                minimumSize: const Size(0, 50),
                              ),

                              onPressed: deletePhoto,
                            ),
                          ),
                        ],
                      ),

                    const SizedBox(height: 25),

                    /// КАРТА
                    const Text(
                      "📍 Местоположение",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 10),
                    
                    if (latitude != null && longitude != null)
                      FutureBuilder<String>(
                        future: getAddress(latitude!, longitude!),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return const CircularProgressIndicator();
                          }

                          return Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(15),
                            decoration: BoxDecoration(
                              color: Colors.white70,
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Text(
                              snapshot.data!,
                              style: const TextStyle(fontSize: 16),
                            ),
                          );
                        },
                      ),
                      
                    const SizedBox(height: 10),
                    
                    if (latitude != null && longitude != null)
                      Container(
                        height: 320,

                        clipBehavior: Clip.antiAlias,

                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                        ),

                        child: FlutterMap(
                          options: MapOptions(
                            initialCenter: LatLng(latitude!, longitude!),

                            initialZoom: 15,
                          ),

                          children: [
                            TileLayer(
                              urlTemplate:
                                  "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                            ),

                            MarkerLayer(
                              markers: [
                                Marker(
                                  point: LatLng(latitude!, longitude!),

                                  width: 45,
                                  height: 45,

                                  child: const Icon(
                                    Icons.location_on,
                                    color: Colors.red,
                                    size: 45,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      )
                    else
                      const Text(
                        "Координаты отсутствуют",
                        style: TextStyle(color: Colors.white),
                      ),
                    const SizedBox(height: 25),

                    /// ОПИСАНИЕ
                    const Text(
                      "📝 Описание объекта",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 10),

                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white70,
                        borderRadius: BorderRadius.circular(20),
                      ),

                      child: TextField(
                        controller: descriptionController,

                        readOnly: !canEdit,

                        maxLines: 8,

                        style: const TextStyle(fontSize: 16),

                        decoration: InputDecoration(
                          hintText: canEdit
                              ? "Введите описание объекта, инструкции, ссылки..."
                              : "Описание объекта",

                          contentPadding: const EdgeInsets.all(18),

                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),

                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 25),

                    /// КНОПКА СОХРАНЕНИЯ
                    if (canEdit)
                      SizedBox(
                        width: double.infinity,
                        height: 55,

                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.save, size: 24),

                          label: const Text(
                            "Сохранить изменения",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),

                          onPressed: saveObject,
                        ),
                      ),

                    const SizedBox(height: 10),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
