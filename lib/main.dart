// @dart=2.9
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'package:http/http.dart' as http;
import 'package:numberpicker/numberpicker.dart';
import 'Package.dart';
import 'PackageOutgoing.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  final String title = "Barcode Scan";

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with TickerProviderStateMixin {
  String _titleProgress;
  String _scanBarcode = '';
  String _scanLocation = '';

  String _scanPackageID = '';
  String _scanTrackingNr = '';

  int _currentValue = 1;
  int _currentTab;

  bool _isUpdating;
  bool _isUpdating2;

  Package _selectedPackage;
  PackageOutgoing _selectedPackageOutgoing;
  List<Package> _packages;
  List<PackageOutgoing> _packagesOutgoing;

  TabController tabController;

  TextEditingController _packageCodeController;
  TextEditingController _locationCodeController;
  TextEditingController _descriptionCodeController;
  TextEditingController _quantityCodeController;

  TextEditingController _packageIdController;
  TextEditingController _trackingNoController;
  TextEditingController _noteController;

  final selectedColor = Colors.white;
  final _descriptionController = TextEditingController();
  final _noteInputController = TextEditingController();

  @override
  void dispose() {
    // Clean up the controller when the widget is disposed.
    _descriptionController.dispose();
    super.dispose();
  }

  // Initialize controllers and variables and fetch existing data
  @override
  void initState() {
    super.initState();
    //scanBarcode(true).then((value) => scanBarcode(false));
    tabController = TabController(length: 4, vsync: this);
    _currentTab = 0;
    _packages = [];
    _packagesOutgoing = [];
    _isUpdating = false;
    _isUpdating2 = false;
    _titleProgress = "Barcode Scan";
    _packageCodeController = TextEditingController();
    _locationCodeController = TextEditingController();
    _descriptionCodeController = TextEditingController();
    _quantityCodeController = TextEditingController();
    _packageIdController = TextEditingController();
    _trackingNoController = TextEditingController();
    _noteController = TextEditingController();
    fetchData(0);
    fetchData(1);
    //testInternet();
  }

  /*
  Future<void> testInternet() async{
    try {
      final result = await InternetAddress.lookup('google.com');
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        print('connected');
        _packageCodeController.text = "YES";
      }
    } on SocketException catch (_) {
      print('not connected');
      _packageCodeController.text = "NO";
    }
  }*/

  // Display progress in the app title
  _showProgress(String message) {
    setState(() {
      _titleProgress = message;
    });
  }

  // Set input fields to the values of the selected package
  _setValues(Package package) {
    _packageCodeController.text = package.packageCode;
    _locationCodeController.text = package.locationCode;
    _descriptionCodeController.text = package.description;
    _quantityCodeController.text = package.quantity.toString();
    setState(() {
      _isUpdating = true;
    });
  }

  // Set input fields to the values of the selected outgoing package
  _setValuesOutgoing(PackageOutgoing packageOutgoing) {
    _packageIdController.text = packageOutgoing.packageID;
    _trackingNoController.text = packageOutgoing.trackingNr;
    _noteController.text = packageOutgoing.note;
    setState(() {
      _isUpdating2 = true;
    });
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> scanBarcode(int mode) async {
    String barcodeScanRes;
    // Platform messages may fail, so we use a try/catch PlatformException.
    try {
      barcodeScanRes = await FlutterBarcodeScanner.scanBarcode(
          '#ff6666', 'Cancel', true, ScanMode.BARCODE);
      print(barcodeScanRes);
    } on PlatformException {
      barcodeScanRes = 'Failed to get platform version.';
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    // Save result in corresponding variable
    setState(() {
      switch (mode) {
        case 0:
          _scanBarcode = barcodeScanRes;
          break;
        case 1:
          _scanLocation = barcodeScanRes;
          break;
        case 2:
          _scanPackageID = barcodeScanRes;
          break;
        case 3:
          _scanTrackingNr = barcodeScanRes;
          break;
      }
    });
  }

  // Encode results to JSON and request a "Create" action
  // Creates a SQL entry on the server side
  // Mode 0: Create entry for Tab 2 (Package Inventory)
  // Mode 1: Create entry for Tab 4 (Sent Packages)
  Future<String> sendData(int mode) async {
    String bodyJson;

    switch (mode) {
      case 0:
        if (_scanBarcode == "") return "Package Code missing!";
        if (_scanLocation == "") return "Location Code missing!";
        bodyJson = json.encode({
          "action": "create",
          "mode": "inventory",
          "package": _scanBarcode,
          "location": _scanLocation,
          "quantity": _currentValue,
          "description": _descriptionController.text
        });
        break;
      case 1:
        if (_scanPackageID == "") return "Package ID missing!";
        if (_scanTrackingNr == "") return "Tracking NR missing!";
        bodyJson = json.encode({
          "action": "create",
          "mode": "outgoing",
          "packageid": _scanPackageID,
          "trackingnr": _scanTrackingNr,
          "note": _noteInputController.text
        });
        break;
    }

    _showProgress('Adding Package...');
    var result = await http.post(
        Uri.encodeFull("http://192.168.178.74//handleapp.php"),
        body: bodyJson);

    if (!mounted) return '';

    // If successful fetch new table data
    if (result.body == "Package successfully submitted!") {
      fetchData(mode);
      setState(() {
        _scanBarcode = "";
        _scanLocation = "";
      });
    }
    return result.body;
  }

  // Requests a "Read" action on the SQL tables via JSON
  // Updates list variables and refreshes state to display changes
  Future<String> fetchData(int mode) async {
    String bodyJson;
    switch (mode) {
      case 0:
        bodyJson = json.encode({"action": "read", "mode": "inventory"});
        break;
      case 1:
        bodyJson = json.encode({"action": "read", "mode": "outgoing"});
        break;
    }
    _showProgress('Loading Packages...');
    var result = await http.post(
        Uri.encodeFull("http://192.168.178.74//handleapp.php"),
        body: bodyJson);
    if (result.statusCode == 200 && result.body != "error") {
      if (mode == 0) {
        List<Package> list = parseResult(result.body);
        setState(() {
          _packages = list;
        });
        _showProgress(widget.title);
        return list.toString();
      } else if (mode == 1) {
        List<PackageOutgoing> list = parseResultOutgoing(result.body);
        setState(() {
          _packagesOutgoing = list;
        });
        _showProgress(widget.title);
        return list.toString();
      }
    } else
      return List.empty().toString();
    return "";
  }

  // Requests an "Update" action on a existing "inventory package" via JSON
  Future<void> updateData(Package package) async {
    _showProgress('Updating Package...');
    var result =
        await http.post(Uri.encodeFull("http://192.168.178.74//handleapp.php"),
            body: json.encode({
              "action": "update",
              "mode": "inventory",
              "id": package.id,
              "package": _packageCodeController.text,
              "location": _locationCodeController.text,
              "quantity": _quantityCodeController.text,
              "description": _descriptionCodeController.text
            }));

    if (!mounted) return '';

    if (result.body == "Package successfully updated") {
      fetchData(0);
      setState(() {
        _isUpdating = false;
        _packageCodeController.text = '';
        _locationCodeController.text = '';
        _descriptionCodeController.text = '';
        _quantityCodeController.text = '';
      });

    }
    return result.body;
  }

  // Requests an "Update" action on a existing "sent package" via JSON
  Future<void> updateDataOutgoing(PackageOutgoing packageOutgoing) async {
    _showProgress('Updating Package...');
    var result =
        await http.post(Uri.encodeFull("http://192.168.178.74//handleapp.php"),
            body: json.encode({
              "action": "update",
              "mode": "outgoing",
              "id": packageOutgoing.id,
              "packageid": _packageIdController.text,
              "trackingnr": _trackingNoController.text,
              "note": _noteController.text
            }));

    if (!mounted) return '';

    if (result.body == "Package successfully updated") {
      fetchData(1);
      setState(() {
        _isUpdating2 = false;
        _packageIdController.text = '';
        _trackingNoController.text = '';
        _noteController.text = '';
      });
    }
    return result.body;
  }

  // Requests "Deletion" of a existing "inventory package" via JSON
  Future<void> deleteData(Package package) async {
    _showProgress('Deleting Package...');
    var result = await http.post(
        Uri.encodeFull("http://192.168.178.74//handleapp.php"),
        body: json.encode(
            {"action": "delete", "mode": "inventory", "id": package.id}));

    if (!mounted) return '';
    print(result.body);
    if (result.body == "Package successfully deleted") {
      setState(() {
        _packages.remove(package);
      });
      fetchData(0);
    }
    return result.body;
  }

  // Requests "Deletion" of existing "outgoing package" via JSON
  Future<void> deleteDataOutgoing(PackageOutgoing packageOutgoing) async {
    _showProgress('Deleting Package...');
    var result = await http.post(
        Uri.encodeFull("http://192.168.178.74//handleapp.php"),
        body: json.encode({
          "action": "delete",
          "mode": "outgoing",
          "id": packageOutgoing.id
        }));

    if (!mounted) return '';
    print(result.body);
    if (result.body == "Package successfully deleted") {
      setState(() {
        _packagesOutgoing.remove(_packagesOutgoing);
      });
      fetchData(1);
    }
    return result.body;
  }

  // Create and populate table view on Tab 2
  // Tapping an entry sets up input fields to allow updating the entry
  // Additionally add a "Delete button" to each table row
  SingleChildScrollView _dataBody() {
    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: [
            DataColumn(
                label: Text("QUANTITY"),
                numeric: false,
                tooltip: "This is the Quantity"),
            DataColumn(
                label: Text("PACKAGE"),
                numeric: false,
                tooltip: "This is the Package Code"),
            DataColumn(
                label: Text("LOCATION"),
                numeric: false,
                tooltip: "This is the Location Code"),
            DataColumn(
                label: Text("DESCRIPTION"),
                numeric: false,
                tooltip: "This is the Description"),
            DataColumn(
                label: Text("TIMESTAMP"),
                numeric: false,
                tooltip: "This is the Timestamp"),
            DataColumn(
                label: Text("DELETE"),
                numeric: false,
                tooltip: "Delete Action"),
          ],
          rows: _packages
              .map(
                (package) => DataRow(
                  cells: [
                    DataCell(
                      Text(package.quantity.toString()),
                      onTap: () {
                        print("Tapped " + package.packageCode);
                        _setValues(package);
                        _selectedPackage = package;
                      },
                    ),
                    DataCell(
                      Text(
                        package.packageCode,
                      ),
                      onTap: () {
                        print("Tapped " + package.packageCode);
                        _setValues(package);
                        _selectedPackage = package;
                      },
                    ),
                    DataCell(
                      Text(
                        package.locationCode,
                      ),
                      onTap: () {
                        print("Tapped " + package.packageCode);
                        _setValues(package);
                        _selectedPackage = package;
                      },
                    ),
                    DataCell(
                      Text(
                        package.description,
                      ),
                      onTap: () {
                        print("Tapped " + package.packageCode);
                        _setValues(package);
                        _selectedPackage = package;
                      },
                    ),
                    DataCell(
                      Text(
                        package.timestamp,
                      ),
                      onTap: () {
                        print("Tapped " + package.timestamp);
                        _setValues(package);
                        _selectedPackage = package;
                      },
                    ),
                    DataCell(
                      IconButton(
                        icon: Icon(Icons.delete),
                        onPressed: () {
                          deleteData(package);
                        },
                      ),
                      onTap: () {
                        print("Tapped " + package.packageCode);
                      },
                    ),
                  ],
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  // Create and populate table view on Tab 4
  // Tapping an entry sets up input fields to allow updating the entry
  // Additionally add a "Delete button" to each table row
  SingleChildScrollView _dataBodyOutgoing() {
    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: [
            DataColumn(
                label: Text("PACKAGE ID"),
                numeric: false,
                tooltip: "This is the Package Code"),
            DataColumn(
                label: Text("TRACKING #"),
                numeric: false,
                tooltip: "This is the Location Code"),
            DataColumn(
                label: Text("NOTE"),
                numeric: false,
                tooltip: "This is the Description"),
            DataColumn(
                label: Text("TIMESTAMP"),
                numeric: false,
                tooltip: "This is the Timestamp"),
            DataColumn(
                label: Text("DELETE"),
                numeric: false,
                tooltip: "Delete Action"),
          ],
          rows: _packagesOutgoing
              .map(
                (packageOutgoing) => DataRow(
                  cells: [
                    DataCell(
                      Text(
                        packageOutgoing.packageID,
                      ),
                      onTap: () {
                        print("Tapped " + packageOutgoing.packageID);
                        _setValuesOutgoing(packageOutgoing);
                        _selectedPackageOutgoing = packageOutgoing;
                      },
                    ),
                    DataCell(
                      Text(
                        packageOutgoing.trackingNr,
                      ),
                      onTap: () {
                        print("Tapped " + packageOutgoing.trackingNr);
                        _setValuesOutgoing(packageOutgoing);
                        _selectedPackageOutgoing = packageOutgoing;
                      },
                    ),
                    DataCell(
                      Text(
                        packageOutgoing.note,
                      ),
                      onTap: () {
                        print("Tapped " + packageOutgoing.note);
                        _setValuesOutgoing(packageOutgoing);
                        _selectedPackageOutgoing = packageOutgoing;
                      },
                    ),
                    DataCell(
                      Text(
                        packageOutgoing.timestamp,
                      ),
                      onTap: () {
                        print("Tapped " + packageOutgoing.timestamp);
                        _setValuesOutgoing(packageOutgoing);
                        _selectedPackageOutgoing = packageOutgoing;
                      },
                    ),
                    DataCell(
                      IconButton(
                        icon: Icon(Icons.delete),
                        onPressed: () {
                          //deleteData("package");TODO
                          deleteDataOutgoing((packageOutgoing));
                        },
                      ),
                      onTap: () {
                        print("Tapped " + packageOutgoing.packageID);
                      },
                    ),
                  ],
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  //Parse fetched JSON results into Package Objects
  static List<Package> parseResult(String resultBody) {
    final parsed = json.decode(resultBody).cast<Map<String, dynamic>>();
    return parsed.map<Package>((json) => Package.fromJson(json)).toList();
  }

  //Parse fetched JSON results into Outgoing Package Objects
  static List<PackageOutgoing> parseResultOutgoing(String resultBody) {
    final parsed = json.decode(resultBody).cast<Map<String, dynamic>>();
    return parsed
        .map<PackageOutgoing>((json) => PackageOutgoing.fromJson(json))
        .toList();
  }

  // Alert dialog for SQL query results
  void showAlertDialog(String result, BuildContext context, int mode) {
    // Set up button
    Widget nextScanButton = TextButton(
        child: Text("NEXT"),
        onPressed: () {
          Navigator.of(context).pop();
          scanBarcode(mode).then((value) => scanBarcode(mode + 1));
        });

    Widget stopButton = TextButton(
        child: Text("STOP"),
        onPressed: () {
          Navigator.of(context).pop();
        });

    // set up the AlertDialog
    AlertDialog alert = AlertDialog(
      title: Text("SQL QUERY"),
      content: Text(result.toString()),
      actions: [
        stopButton,
        nextScanButton,
      ],
    );

    // show the dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }

  // Change Tabs when top bar buttons are pressed
  void goTo(int index) {
    this.tabController.animateTo(index);
    setState(() {
      this._currentTab = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        home: Scaffold(
            //Top bar with buttons for each Tab
            appBar: AppBar(title: const Text('Barcode scan'), actions: [
              IconButton(
                icon: Icon(
                  Icons.add_location_alt,
                  color: _currentTab == 0 ? selectedColor : Colors.white,
                ),
                onPressed: () {
                  goTo(0);
                },
              ),
              IconButton(
                icon: Icon(
                  Icons.track_changes,
                  color: _currentTab == 1 ? selectedColor : Colors.white,
                ),
                onPressed: () {
                  goTo(1);
                },
              ),
              IconButton(
                icon: Icon(
                  Icons.local_shipping,
                  color: _currentTab == 2 ? selectedColor : Colors.white,
                ),
                onPressed: () {
                  goTo(2);
                },
              ),
              IconButton(
                icon: Icon(
                  Icons.storage,
                  color: _currentTab == 3 ? selectedColor : Colors.white,
                ),
                onPressed: () {
                  goTo(3);
                },
              ),
            ]),
            body: TabBarView(controller: tabController,
                //physics: NeverScrollableScrollPhysics(),
                children: <Widget>[
                  //Tab 1: Scan Package Data for invetory database
                  Container(child: Builder(builder: (BuildContext context) {
                    return Container(
                        alignment: Alignment.center,
                        child: Flex(
                            direction: Axis.vertical,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              Padding(
                                padding: EdgeInsets.only(bottom: 10),
                                child: MaterialButton(
                                    height: 80.0,
                                    minWidth: 300.0,
                                    color: Theme.of(context).primaryColor,
                                    splashColor: Colors.blueAccent,
                                    onPressed: () => scanBarcode(0),
                                    child: Text('Edit Package Code',
                                        style: TextStyle(fontSize: 30))),
                              ),
                              Padding(
                                padding: EdgeInsets.zero,
                                child: MaterialButton(
                                    height: 80.0,
                                    minWidth: 300.0,
                                    color: Theme.of(context).primaryColor,
                                    splashColor: Colors.blueAccent,
                                    onPressed: () => scanBarcode(1),
                                    child: Text('Edit Location Code',
                                        style: TextStyle(fontSize: 30))),
                              ),
                              Container(
                                width: 300.0,
                                height: 100.0,
                                margin: EdgeInsets.all(10.0),
                                padding: EdgeInsets.all(10.0),
                                decoration: BoxDecoration(
                                    border:
                                        Border.all(color: Colors.blueAccent)),
                                child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: [
                                      Padding(
                                          padding: EdgeInsets.only(bottom: 10),
                                          child: Container(
                                              width: 200.0,
                                              child: TextFormField(
                                                controller:
                                                    _descriptionController,
                                                decoration: InputDecoration(
                                                    labelText:
                                                        'Enter description'),
                                              ))),
                                      Padding(
                                          padding: EdgeInsets.zero,
                                          child: new NumberPicker.integer(
                                              listViewWidth: 50.0,
                                              itemExtent: 30.0,
                                              highlightSelectedValue: true,
                                              initialValue: _currentValue,
                                              minValue: 1,
                                              maxValue: 100,
                                              onChanged: (newValue) => setState(
                                                  () => _currentValue =
                                                      newValue))),
                                    ]),
                              ),
                              Text('Package Code : $_scanBarcode\n',
                                  style: TextStyle(fontSize: 20)),
                              Text('Location Code : $_scanLocation\n',
                                  style: TextStyle(fontSize: 20)),
                              Padding(
                                padding: EdgeInsets.zero,
                                child: MaterialButton(
                                    height: 100.0,
                                    minWidth: 300.0,
                                    color: Colors.red,
                                    splashColor: Colors.blueAccent,
                                    onPressed: () {
                                      sendData(0).then((s) {
                                        showAlertDialog(s, context, 0);
                                        FocusScope.of(context).unfocus();
                                      });
                                    },
                                    child: Text('Send Data',
                                        style: TextStyle(fontSize: 30))),
                              ),
                            ]));
                  })),
                  //Tab 2: Data table for Packages
                  Container(
                      child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                        Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Padding(
                                padding: EdgeInsets.all(20.0),
                                child: Container(
                                    width: 100.0,
                                    child: TextField(
                                      controller: _packageCodeController,
                                      decoration: InputDecoration.collapsed(
                                        hintText: "Package Code",
                                      ),
                                    )),
                              ),
                              Padding(
                                  padding: EdgeInsets.all(20.0),
                                  child: Container(
                                    width: 100.0,
                                    child: TextField(
                                      controller: _locationCodeController,
                                      decoration: InputDecoration.collapsed(
                                        hintText: "Location Code",
                                      ),
                                    ),
                                  )),
                            ]),
                        Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Padding(
                                padding: EdgeInsets.all(20.0),
                                child: Container(
                                    width: 100.0,
                                    child: TextField(
                                      controller: _descriptionCodeController,
                                      decoration: InputDecoration.collapsed(
                                        hintText: "Description",
                                      ),
                                    )),
                              ),
                              Padding(
                                  padding: EdgeInsets.all(20.0),
                                  child: Container(
                                    width: 100.0,
                                    child: TextField(
                                      keyboardType: TextInputType.number,
                                      controller: _quantityCodeController,
                                      decoration: InputDecoration.collapsed(
                                        hintText: "Quantity",
                                      ),
                                    ),
                                  )),
                            ]),
                        _isUpdating
                            ? Row(
                                children: <Widget>[
                                  OutlinedButton(
                                    child: Text('UPDATE'),
                                    onPressed: () {
                                      updateData(_selectedPackage);
                                    },
                                  ),
                                  OutlinedButton(
                                    child: Text('CANCEL'),
                                    onPressed: () {
                                      setState(() {
                                        _isUpdating = false;
                                      });
                                      //_clearValues();
                                    },
                                  ),
                                ],
                              )
                            : Container(),
                        Expanded(
                          child: _dataBody(),
                        )
                      ])),
                  //Tab 3: Scan Package Data for Outoging Packages database
                  Container(child: Builder(builder: (BuildContext context) {
                    return Container(
                        alignment: Alignment.center,
                        child: Flex(
                            direction: Axis.vertical,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              Padding(
                                padding: EdgeInsets.only(bottom: 10),
                                child: MaterialButton(
                                    height: 80.0,
                                    minWidth: 300.0,
                                    color: Theme.of(context).primaryColor,
                                    splashColor: Colors.blueAccent,
                                    onPressed: () => scanBarcode(2),
                                    //TODO Modes
                                    child: Text('Edit Package ID',
                                        style: TextStyle(fontSize: 30))),
                              ),
                              Padding(
                                padding: EdgeInsets.zero,
                                child: MaterialButton(
                                    height: 80.0,
                                    minWidth: 300.0,
                                    color: Theme.of(context).primaryColor,
                                    splashColor: Colors.blueAccent,
                                    onPressed: () => scanBarcode(3),
                                    //TODO MODES
                                    child: Text('Edit Tracking NR',
                                        style: TextStyle(fontSize: 30))),
                              ),
                              Container(
                                width: 300.0,
                                height: 100.0,
                                margin: EdgeInsets.all(10.0),
                                padding: EdgeInsets.all(10.0),
                                decoration: BoxDecoration(
                                    border:
                                        Border.all(color: Colors.blueAccent)),
                                child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: [
                                      Padding(
                                          padding: EdgeInsets.only(bottom: 10),
                                          child: Container(
                                              width: 200.0,
                                              child: TextFormField(
                                                controller:
                                                    _noteInputController,
                                                decoration: InputDecoration(
                                                    labelText: 'Enter note'),
                                              ))),
                                    ]),
                              ),
                              Text('Package ID : $_scanPackageID\n',
                                  style: TextStyle(fontSize: 20)),
                              Text('Tracking NR : $_scanTrackingNr\n',
                                  style: TextStyle(fontSize: 20)),
                              Padding(
                                padding: EdgeInsets.zero,
                                child: MaterialButton(
                                    height: 100.0,
                                    minWidth: 300.0,
                                    color: Colors.red,
                                    splashColor: Colors.blueAccent,
                                    onPressed: () {
                                      sendData(1).then((s) {
                                        showAlertDialog(s, context, 2);
                                        FocusScope.of(context).unfocus();
                                      });
                                    },
                                    child: Text('Send Data',
                                        style: TextStyle(fontSize: 30))),
                              ),
                            ]));
                  })),
                  //Tab 4: Data table for Outgoing Packages
                  Container(
                      child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                        Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Padding(
                                padding: EdgeInsets.all(20.0),
                                child: Container(
                                    width: 100.0,
                                    child: TextField(
                                      controller: _packageIdController,
                                      decoration: InputDecoration.collapsed(
                                        hintText: "Package ID",
                                      ),
                                    )),
                              ),
                              Padding(
                                  padding: EdgeInsets.all(20.0),
                                  child: Container(
                                    width: 100.0,
                                    child: TextField(
                                      controller: _trackingNoController,
                                      decoration: InputDecoration.collapsed(
                                        hintText: "Tracking #",
                                      ),
                                    ),
                                  )),
                            ]),
                        Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Padding(
                                padding: EdgeInsets.all(20.0),
                                child: Container(
                                    width: 100.0,
                                    child: TextField(
                                      controller: _noteController,
                                      decoration: InputDecoration.collapsed(
                                        hintText: "Note",
                                      ),
                                    )),
                              ),
                            ]),
                        _isUpdating2
                            ? Row(
                                children: <Widget>[
                                  OutlinedButton(
                                    child: Text('UPDATE'),
                                    onPressed: () {
                                      updateData(_selectedPackage);
                                    },
                                  ),
                                  OutlinedButton(
                                    child: Text('CANCEL'),
                                    onPressed: () {
                                      setState(() {
                                        _isUpdating2 = false;
                                      });
                                      //_clearValues();
                                    },
                                  ),
                                ],
                              )
                            : Container(),
                        Expanded(
                          child: _dataBodyOutgoing(),
                        )
                      ])),
                ])));

    /*Container(
            child: Icon(Icons.storage),
          ),*/
  }
}
