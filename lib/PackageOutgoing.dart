class PackageOutgoing {
  int id;
  String packageID;
  String trackingNr;
  String note;
  String timestamp;

  PackageOutgoing({required this.id, required this.packageID,required this.trackingNr,required this.note,this.timestamp=""});

  factory PackageOutgoing.fromJson(Map<String, dynamic> json){
    return PackageOutgoing(
        id: int.parse(json['id'] as String),
        packageID: json['packageid'] as String,
        trackingNr: json['trackingnr'] as String,
        note: json['note'] as String,
        timestamp: json['timestamp'] as String
    );
  }
}
