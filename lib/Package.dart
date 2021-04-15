class Package {
  int id;
  String packageCode;
  String locationCode;
  int quantity;
  String description;
  String timestamp;

  Package({required this.id, required this.packageCode,required this.locationCode,required this.quantity,required this.description,this.timestamp=""});

  factory Package.fromJson(Map<String, dynamic> json){
    return Package(
        id: int.parse(json['id'] as String),
        packageCode: json['packagecode'] as String,
        locationCode: json['locationcode'] as String,
        quantity: int.parse(json['quantity'] as String),
        description: json['description'] as String,
        timestamp: json['timestamp'] as String
    );
  }
}
