// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:jaagran/providers/user_details.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:location/location.dart' as loc;
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart' as sysPaths;
import 'package:image_picker/image_picker.dart';
import 'package:geocoding/geocoding.dart';
import 'package:get/get.dart';
import 'dart:ui' as ui;
// import 'package:firebase_ml_vision/firebase_ml_vision.dart';

import '../constants/stringConst.dart';

import '../models/class_info.dart';

import '../providers/class_details.dart';

class NewClassScreen extends StatefulWidget {
  static const routeName = '/new-class-screen';

  const NewClassScreen({super.key});
  @override
  State<NewClassScreen> createState() => _NewClassScreenState();
}

enum probSolSelectionList { Samasya, Sujhaav }

class _NewClassScreenState extends State<NewClassScreen> {
  bool _isFloatingButtonActive = true;
  bool _isSpinnerLoading = false;
  bool _isCurrentLocationAccessGiven = false;
  bool _isCurrentLocationTaken = false;
  bool _isCameraOpened = false;
  bool _isClassPictureTaken = false;
  bool _isSubmitLoadingSpinner = false;
  bool _getAddressFunc = false;
  bool _isClassCreated = false;

  bool _numberStudents = false;
  TextEditingController maleNumber = new TextEditingController();
  TextEditingController femaleNumber = new TextEditingController();
  TextEditingController numStudents = new TextEditingController();
  TextEditingController _categorySelected = TextEditingController();
  TextEditingController _vaktaName = TextEditingController();
  TextEditingController _userPhoneNumber = TextEditingController();
  TextEditingController _problemDesc = TextEditingController();
  TextEditingController _problemType = TextEditingController();
  TextEditingController _probCategory = TextEditingController();

  final loc.Location location = loc.Location();
  final ekalCategorySelectionList = [
    "Hanuman Pariwar",
    "Sabha",
    "Samasya/Sujhaav",
  ];
  final probCategorySelectionList = [
    "NA",
    "NA",
    "NA",
  ];

  StreamSubscription<loc.LocationData>? _locationSubscription;
  var latitudeValue = 'Getting Latitude...'.obs;
  var longitudeValue = 'Getting Longitude...'.obs;
  var addressValue = 'Getting Address...'.obs;
  late StreamSubscription<Position> streamSubscription;

  late File _storedImage;
  var _picTiming;
  var _savedImageFilePath = "";
  var _numberOfStudents = 0;

  late File _imageFile;
  List<Face> _faces = [];
  bool isLoading = false;
  late ui.Image _image;
  final picker = ImagePicker();

  // Define a boolean flag to indicate if the widget is still mounted
  bool _isMounted = false;

  @override
  void initState() {
    super.initState();
    _isMounted = true;
    _requestPermission();
  }

  @override
  void dispose() {
    // Set the flag to false when the widget is being disposed
    _isMounted = false;
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    try {
      setState(() {
        if (_isCurrentLocationTaken == true) {
          _stopListening();
        }
      });
    } catch (error) {
      print("MEMERR1");
    }
  }

  Future<void> _checkForError(
      BuildContext context, String titleText, String contextText,
      {bool popVal = false}) async {
    return showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(titleText),
        content: Text(contextText),
        actions: <Widget>[
          ElevatedButton(
            child: const Text('OK'),
            onPressed: () {
              Navigator.of(ctx).pop(false);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _checkLocatoinService(
    BuildContext context,
    String titleText,
    String contextText,
  ) async {
    return showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${titleText}'),
        content: Text('${contextText}'),
        actions: <Widget>[
          ElevatedButton(
            child: const Text('OK'),
            onPressed: () {
              Navigator.of(ctx).pop(false);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _submitTheClassInformation(
    BuildContext context,
    GlobalKey<ScaffoldState> sKey,
  ) async {
    ClassInformation classInfo = ClassInformation(
        unqId: DateTime.now().toString() + _picTiming.toString(),
        currDateTime: _picTiming.toString(),
        currTime: DateFormat.jm().format(_picTiming).toString(),
        currDate: DateFormat.yMMMd('en_US').format(_picTiming).toString(),
        numOfStudents: _numberOfStudents,
        currLatitude: double.parse(latitudeValue.value),
        currLongitude: double.parse(longitudeValue.value),
        currAddress: addressValue.value,
        classroomUrl: "",
        imageFile: _storedImage,
        eventType: _categorySelected.text,
        maleNumber: maleNumber.text,
        femaleNumber: femaleNumber.text,
        vaktaName: _vaktaName.text,
        mobileNumber: _userPhoneNumber.text,
        subEventType: _categorySelected.text == "Samasya/Sujhaav" ? "test" : "",
        nameOfPerson:
            _categorySelected.text == "Samasya/Sujhaav" ? _vaktaName.text : "",
        problemDetails: _problemDesc.text);

    if (_categorySelected.text == "Sabha") {
      if (maleNumber.text == "" ||
          femaleNumber.text == "" ||
          _vaktaName.text == "" ||
          _userPhoneNumber.text == "") {
        _checkForError(context, "Missing Details",
            "Please fill all the above details\nकृपया उपरोक्त सभी विवरण भरें");
        return;
      }
      if (_userPhoneNumber.text.length < 10) {
        _checkForError(context, "Invalid Phone Number",
            "Please enter a valid phone number\nकृपया एक मान्य फ़ोन नंबर दर्ज करे");
        return;
      }
    } else if (_categorySelected.text == "Hanuman Pariwar") {
      print("1");
      return;
    } else if (_categorySelected.text == "Samasya/Sujhaav") {
      print("2");
      return;
    } else {
      _checkForError(context, "Missing Details",
          "Please select an event type\nकृपया एक इवेंट प्रकार चुनें");
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(S.classSubmitText),
      ),
    );

    try {
      setState(() {
        _isSubmitLoadingSpinner = true;
      });
    } catch (error) {
      print("MEMERR2");
    }

    try {
      Provider.of<ClassDetails>(context, listen: false)
          .addNewClass(classInfo, _storedImage, numStudents)
          .catchError((onError) {
        print(onError);
        _checkForError(
          context,
          S.errorTitle,
          S.errorSub,
          popVal: true,
        );
      }).then((_) {
        // Scaffold.of(context).showSnackBar(
        //     SnackBar(content: Text('Class Submitted Successfully!')));
        try {
          setState(() {
            _isFloatingButtonActive = true;
            _isSpinnerLoading = false;
            _isCurrentLocationAccessGiven = false;
            _isCurrentLocationTaken = false;
            _isCameraOpened = false;
            _isClassPictureTaken = false;
            _isSubmitLoadingSpinner = false;
            _getAddressFunc = false;

            _isSubmitLoadingSpinner = false;
          });
        } catch (error) {
          print("MEMERR3");
        }

        // Navigator.of(context).pushReplacementNamed(TabsScreen.routeName);
        Navigator.of(context)
            .pushNamedAndRemoveUntil("/tab-screen", (route) => false);
      });
    } catch (errorVal) {
      _checkForError(context, S.errorTitle, S.errorSub);
    }
  }

  Widget TextFieldContainer(
    BuildContext context,
    String textLabel,
    int maxLgt,
    TextEditingController _textCtr,
    TextInputType keyBoardType,
  ) {
    var screenHeight = MediaQuery.of(context).size.height;
    var screenWidth = MediaQuery.of(context).size.width;
    var topInsets = MediaQuery.of(context).viewInsets.top;
    var bottomInsets = MediaQuery.of(context).viewInsets.bottom;
    var useableHeight = screenHeight - topInsets - bottomInsets;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: Colors.grey.shade100,
      ),
      margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.02),
      padding: EdgeInsets.symmetric(
        vertical: screenHeight * 0.008,
        horizontal: screenWidth * 0.03,
      ),
      child: TextField(
        maxLength: maxLgt,
        decoration: InputDecoration(
            labelText: '${textLabel}: ',
            hintStyle: TextStyle(fontWeight: FontWeight.bold)),
        controller: _textCtr,
        keyboardType: keyBoardType,
        onSubmitted: (_) {},
      ),
    );
  }

  final GlobalKey<ScaffoldState> scaffoldKey = new GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    var screenHeight = MediaQuery.of(context).size.height;
    var screenWidth = MediaQuery.of(context).size.width;
    var topInsets = MediaQuery.of(context).viewInsets.top;
    var bottomInsets = MediaQuery.of(context).viewInsets.bottom;
    var useableHeight = screenHeight - topInsets - bottomInsets;

    return Scaffold(
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Container(
          margin: EdgeInsets.only(
            left: screenWidth * 0.0125,
            right: screenWidth * 0.0125,
            top: screenHeight * 0.00625,
            bottom: screenHeight * 0.025,
          ),
          child: Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            elevation: 10,
            child: ListView(
              children: <Widget>[
                _isFloatingButtonActive
                    ? Container(
                        margin: EdgeInsets.symmetric(
                          vertical: useableHeight * 0.35,
                        ),
                        alignment: Alignment.center,
                        width: double.infinity,
                        child: const Text(
                          S.newClassScreenBodyText,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    : (!_isCurrentLocationTaken || !_isClassPictureTaken)
                        ? const SizedBox(
                            height: 0,
                          )
                        : SizedBox(
                            height: screenHeight * 1.5,
                            width: screenWidth * 0.9,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: <Widget>[
                                SizedBox(
                                  height: useableHeight * 0.015,
                                ),
                                const Text(
                                  S.newClassPicText,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Card(
                                  elevation: 5,
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: screenWidth * 0.01,
                                      vertical: useableHeight * 0.005,
                                    ),
                                    height: useableHeight * 0.45,
                                    width: screenWidth * 0.95,
                                    child: Image.file(
                                      _storedImage,
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                    ),
                                  ),
                                ),
                                dropDownMenu(
                                  context,
                                  ekalCategorySelectionList,
                                  _categorySelected,
                                  "Event Type/ प्रकार *",
                                  true,
                                  () => {},
                                ),
                                SizedBox(
                                  height: useableHeight * 0.02,
                                ),
                                optionDependMenu(context),
                                SizedBox(
                                  height: useableHeight * 0.01,
                                ),
                                SizedBox(
                                  height: useableHeight * 0.02,
                                ),
                                Container(
                                  height: useableHeight * 0.075,
                                  padding: EdgeInsets.symmetric(
                                    vertical: useableHeight * 0.001,
                                    horizontal: screenWidth * 0.01,
                                  ),
                                  margin: EdgeInsets.symmetric(
                                    vertical: useableHeight * 0.001,
                                    horizontal: screenWidth * 0.0075,
                                  ),
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    child: !_isSubmitLoadingSpinner
                                        ? const Text(
                                            S.newClassSubmitText,
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          )
                                        : const CircularProgressIndicator(
                                            color: Colors.white,
                                          ),
                                    onPressed: () {
                                      _submitTheClassInformation(
                                        context,
                                        scaffoldKey,
                                      );
                                    },
                                  ),
                                ),
                                SizedBox(
                                  height: useableHeight * 0.02,
                                ),
                                Container(
                                  child: Text(
                                    "Date/दिनांक: ${DateFormat.yMMMd('en_US').format(_picTiming)}.",
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  height: useableHeight * 0.02,
                                ),
                                Container(
                                  child: Text(
                                    "Time/समय: ${DateFormat.jm().format(_picTiming)}.",
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  height: useableHeight * 0.02,
                                ),
                                // Container(
                                //   child: Text(
                                //     "Number o $_numberOfStudents",
                                //     textAlign: TextAlign.center,
                                //     style: const TextStyle(
                                //       fontWeight: FontWeight.bold,
                                //     ),
                                //   ),
                                // ),
                                // SizedBox(
                                //   height: useableHeight * 0.02,
                                // ),
                                Container(
                                  child: Text(
                                    "--------------------------------------------\n${S.newClassAddressTitle} \n\n${addressValue.value}",
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  height: useableHeight * 0.1,
                                ),
                              ],
                            ),
                          ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        elevation: 20,
        onPressed: _isFloatingButtonActive
            ? () {
                try {
                  setState(
                    () {
                      _isSpinnerLoading = true;
                      _isFloatingButtonActive = false;
                      _getLocation(
                        context,
                        Provider.of<UserDetails>(context, listen: false)
                            .getLoggedInUserUniqueId()
                            .toString(),
                      );
                    },
                  );
                } catch (error) {
                  print("MEMERR4");
                }
              }
            : null,
        label: !_isSpinnerLoading
            ? Text(
                S.newClassPicClickText,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color:
                        _isFloatingButtonActive ? Colors.white : Colors.black),
              )
            : const CircularProgressIndicator(
                color: Color.fromARGB(255, 225, 176, 176),
              ),
        icon: Icon(
          Icons.class_,
          color: _isFloatingButtonActive ? Colors.white : Colors.black,
        ),
        backgroundColor:
            _isFloatingButtonActive ? Colors.blueAccent : Colors.grey.shade200,
      ),
    );
  }

  Widget optionDependMenu(BuildContext context) {
    if (_categorySelected.text == "Hanuman Pariwar")
      return hanumanParivar(context);
    if (_categorySelected.text == "Sabha") return samitiCategory(context);
    if (_categorySelected.text == "Samasya/Sujhaav")
      return samasyaCategory(context);
    return Container();
  }

  //hanumanParivar DropdownMenu
  Widget hanumanParivar(BuildContext context) {
    return TextFieldContainer(
      context,
      "Mobile Number/मोबाइल नंबर *",
      10,
      _userPhoneNumber,
      TextInputType.number,
    );
  }

  //Sabha DropdownMenu
  Widget samitiCategory(BuildContext context) {
    var screenHeight = MediaQuery.of(context).size.height;
    var screenWidth = MediaQuery.of(context).size.width;
    var topInsets = MediaQuery.of(context).viewInsets.top;
    var bottomInsets = MediaQuery.of(context).viewInsets.bottom;
    var useableHeight = screenHeight - topInsets - bottomInsets;
    return Column(
      children: [
        TextFieldContainer(
          context,
          S.newClassMaleNumText,
          5,
          maleNumber,
          TextInputType.number,
        ),
        SizedBox(
          height: useableHeight * 0.02,
        ),
        TextFieldContainer(
          context,
          S.newClassFemaleNumText,
          5,
          femaleNumber,
          TextInputType.number,
        ),
        SizedBox(
          height: useableHeight * 0.02,
        ),
        TextFieldContainer(
          context,
          "Name of Vakta/वक्ता का नाम *",
          30,
          _vaktaName,
          TextInputType.text,
        ),
        SizedBox(
          height: useableHeight * 0.02,
        ),
        TextFieldContainer(
          context,
          "Vakta's Mobile Number/वक्ता का मोबाइल नंबर *",
          10,
          _userPhoneNumber,
          TextInputType.number,
        )
      ],
    );
  }

  // Samasya/Sujhav dropdownlist
  Widget samasyaCategory(BuildContext context) {
    var screenHeight = MediaQuery.of(context).size.height;
    var screenWidth = MediaQuery.of(context).size.width;
    var topInsets = MediaQuery.of(context).viewInsets.top;
    var bottomInsets = MediaQuery.of(context).viewInsets.bottom;
    var useableHeight = screenHeight - topInsets - bottomInsets;

    probSolSelectionList? _character = probSolSelectionList.Samasya;
    _problemType.text = _character.name;

    return Column(
      children: [
        ListTile(
          title: const Text('Samasya'),
          leading: Radio<probSolSelectionList>(
            value: probSolSelectionList.Samasya,
            groupValue: _character,
            onChanged: (probSolSelectionList? value) {
              setState(() {
                _character = value;
                _problemType.text = _character!.name;
              });
            },
          ),
        ),
        ListTile(
          title: const Text('Sujhaav'),
          leading: Radio<probSolSelectionList>(
            value: probSolSelectionList.Sujhaav,
            groupValue: _character,
            onChanged: (probSolSelectionList? value) {
              setState(() {
                _character = value;
                _problemType.text = _character!.name;
              });
            },
          ),
        ),
        SizedBox(
          height: useableHeight * 0.02,
        ),
        TextFieldContainer(
          context,
          "Name of Person*",
          30,
          _vaktaName,
          TextInputType.text,
        ),
        SizedBox(
          height: useableHeight * 0.02,
        ),
        TextFieldContainer(
          context,
          "Mobile Number/मोबाइल नंबर*",
          10,
          _userPhoneNumber,
          TextInputType.number,
        ),
        SizedBox(
          height: useableHeight * 0.02,
        ),
        dropDownMenu(
          context,
          probCategorySelectionList,
          _probCategory,
          "Samasya/Sujhaav Category*",
          true,
          () => {},
        ),
        SizedBox(
          height: useableHeight * 0.02,
        ),
        TextFieldContainer(
          context,
          "Detail of Problem*",
          300,
          _problemDesc,
          TextInputType.text,
        )
      ],
    );
  }
  /////////////////////////////////// Location Services ///////////////////////////////////

  _getLocation(BuildContext context, String userUniqueId) async {
    try {
      final loc.LocationData _locationResult = await location.getLocation();

      await FirebaseFirestore.instance
          .collection('location')
          .doc(userUniqueId)
          .set(
        {
          'latitude': _locationResult.latitude,
          'lontitude': _locationResult.longitude,
          'name': 'Latitude / Longitude',
        },
        SetOptions(merge: true),
      );

      _getLocationList(context);
    } catch (errorVal) {}
  }

  _stopListening() {
    _locationSubscription?.cancel();
    try {
      setState(() {
        _locationSubscription = null;
      });
    } catch (error) {
      print("MEMERR5");
    }
  }

  _requestPermission() async {
    var status = await Permission.location.request();

    if (status.isGranted) {
      print('Live Location status checking!');
    } else if (status.isDenied) {
      _requestPermission();
    } else if (status.isPermanentlyDenied) {
      openAppSettings();
    }
  }

  _getLocationList(BuildContext context) async {
    bool serviceEnabled;

    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await Geolocator.openLocationSettings();

      String titleText = S.locationErrText;
      String contextText = S.locationErrSubText1;
      _checkLocatoinService(context, titleText, contextText);
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();

      String titleText = S.locationErrText;
      String contextText = S.locationErrSubText2;
      if (permission == LocationPermission.denied) {
        _checkLocatoinService(context, titleText, contextText);
      }
    }

    String titleText = S.locationErrText;
    String contextText = S.locationErrSubText3;

    if (permission == LocationPermission.deniedForever) {
      _checkLocatoinService(context, titleText, contextText);
    }

    if (!_isCameraOpened) {
      try {
        setState(() {
          _isCameraOpened = true;
        });
      } catch (error) {
        print("MEMERR6");
      }
      _takePicture(context);
    }

    streamSubscription =
        Geolocator.getPositionStream().listen((Position position) {
      latitudeValue.value = '${position.latitude}';
      longitudeValue.value = '${position.longitude}';

      if (!_getAddressFunc) {
        _getAddressFunc = true;
        getAddressFromLatLang(position);
      }
    });
  }

  Future<void> getAddressFromLatLang(Position position) async {
    List<Placemark> placemarkUserLocationList = await placemarkFromCoordinates(
      position.latitude,
      position.longitude,
    );

    if (_isMounted) {
      try {
        setState(() {
          _isCurrentLocationAccessGiven = true;
          Placemark place = placemarkUserLocationList[0];

          latitudeValue.value = position.latitude.toString();
          longitudeValue.value = position.longitude.toString();

          addressValue.value =
              'Place Name/No: ${place.name},\nStreet: ${place.street},\nArea: ${place.subLocality},\nDistrict: ${place.locality},\nState: ${place.administrativeArea},\nPostal Code: ${place.postalCode},\nAdm. Area: ${place.subAdministrativeArea},\nCountry: ${place.country}.';

          _isCurrentLocationTaken = true;
        });
      } catch (error) {
        print("MEMERR7");
        print(error);
      }
    }
  }

  ////////////////////////// Class Image ///////////////////////////

  Future<void> _takePicture(BuildContext context) async {
    _picTiming = DateTime.now();
    print(_picTiming);
    final picker = ImagePicker();
    final imageFile = await picker.pickImage(
      source: ImageSource.camera,
      maxHeight: 480,
      maxWidth: 640,
    );

    if (imageFile == null) {
      String titleText = S.cameraErrText;
      String contextText = S.cameraSubText;
      _checkForError(context, titleText, contextText);
      try {
        setState(() {
          _isFloatingButtonActive = true;
          _isSpinnerLoading = false;
        });
      } catch (error) {
        print("MEMERR8");
      }
      return;
    }
    try {
      setState(() {
        _storedImage = File(imageFile.path);
        _isClassPictureTaken = true;
        _isSpinnerLoading = false;
        _isClassCreated = true;
      });
    } catch (error) {
      print("MEMERR9");
    }

    final appDir = await sysPaths.getApplicationDocumentsDirectory();
    final fileName = path.basename(imageFile.path);
    final _savedImageFile =
        await File(imageFile.path).copy('${appDir.path}/${fileName}');

    _savedImageFilePath = _savedImageFile.toString();
    _getImage(context);
  }

  ////////////////////////// Number of Faces in the Image ///////////////////////////

  _getImage(BuildContext context) async {
    print("Get image called");
    final imageFile = _storedImage;
    try {
      setState(() {
        isLoading = true;
      });
    } catch (error) {
      print("MEMERR10");
    }

    final image = InputImage.fromFilePath(imageFile.path);
    final options = FaceDetectorOptions();
    final faceDetector = FaceDetector(options: options);
    final List<Face> faces = await faceDetector.processImage(image);
    faceDetector.close();

    if (mounted) {
      try {
        setState(() {
          _imageFile = File(imageFile.path);
          _faces = faces;
          _loadImage(File(imageFile.path));
        });
      } catch (error) {
        print("MEMERR11");
      }
    }
  }

  _loadImage(File file) async {
    final data = await file.readAsBytes();
    try {
      await decodeImageFromList(data).then(
        (value) => setState(
          () {
            _image = value;
            isLoading = false;
            _numberOfStudents = _faces.length;
            // _numberOfStudents = 0;
          },
        ),
      );
    } catch (error) {
      print("MEMERR12");
    }
  }

  Widget dropDownMenu(
    BuildContext context,
    List<String> dropDownList,
    TextEditingController _textCtr,
    String hintText,
    bool callFunction,
    functionCall(),
  ) {
    var screenHeight = MediaQuery.of(context).size.height;
    var screenWidth = MediaQuery.of(context).size.width;
    var topInsets = MediaQuery.of(context).viewInsets.top;
    var bottomInsets = MediaQuery.of(context).viewInsets.bottom;
    var useableHeight = screenHeight - topInsets - bottomInsets;

    if (callFunction) {
      functionCall();
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: Colors.grey.shade100,
      ),
      margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.02),
      padding: EdgeInsets.symmetric(
        vertical: screenHeight * 0.02,
        horizontal: screenWidth * 0.03,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          hint: Align(
            alignment: Alignment.centerLeft,
            child: _textCtr.text.length == 0
                ? Text("${hintText}")
                : Text(
                    "${_textCtr.text}",
                    style: TextStyle(color: Colors.black),
                  ),
          ),
          isDense: true,
          isExpanded: true,
          iconSize: 35,
          icon: Icon(
            Icons.arrow_drop_down,
            color: Colors.black,
          ),
          onTap: () {},
          items: dropDownList.map(buildMenuItem).toList(),
          onChanged: (value) => setState(() {
            _textCtr.text = value!;
          }),
        ),
      ),
    );
  }

  DropdownMenuItem<String> buildMenuItem(String item) => DropdownMenuItem(
        value: item,
        child: Text(
          item,
          style: TextStyle(
            fontWeight: FontWeight.normal,
          ),
        ),
      );
}

class FacePainter extends CustomPainter {
  final ui.Image image;
  final List<Face> faces;
  final List<Rect> rects = [];

  FacePainter(this.image, this.faces) {
    for (var i = 0; i < faces.length; i++) {
      rects.add(faces[i].boundingBox);
    }
  }

  @override
  void paint(ui.Canvas canvas, ui.Size size) {
    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..color = Colors.yellow;

    canvas.drawImage(image, Offset.zero, Paint());
    for (var i = 0; i < faces.length; i++) {
      canvas.drawRect(rects[i], paint);
    }
  }

  @override
  bool shouldRepaint(FacePainter old) {
    return image != old.image || faces != old.faces;
  }
}
