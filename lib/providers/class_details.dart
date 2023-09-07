import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_storage/firebase_storage.dart';
import '../models/class_info.dart';

class ClassDetails with ChangeNotifier {
  List<ClassInformation> _items = [];

  List<ClassInformation> get items {
    return [..._items];
  }

  int numberOfClassesTaken() {
    int numOfclass = _items.length / 2 as int;

    print(numOfclass);
    return numOfclass;
  }

  Future<void> clearClassDetails(BuildContext context) async {
    this._items = [];
  }

  Future<void> addNewClass(
    ClassInformation classInfo,
    File classroomImage,
    TextEditingController cntStudents,
  ) async {
    FirebaseFirestore db = FirebaseFirestore.instance;
    CollectionReference usersRef = db.collection("userPersonalInformation");

    var currLoggedInUser = await FirebaseAuth.instance.currentUser;
    var loggedInUserId = currLoggedInUser?.uid as String;

    final urlLink = Uri.https(
      'ekalgsrepo-db-default-rtdb.firebaseio.com',
      '/Events/${loggedInUserId}.json',
    );

    final urlLinkForCompleteClassDetails = Uri.https(
      'ekalgsrepo-db-default-rtdb.firebaseio.com',
      '/CompleteClassDetails/${loggedInUserId}/${DateFormat.jm().format(DateTime.now()).toString()}.json',
    );

    String imageName =
        "${loggedInUserId}_${DateTime.now().toString()}_classImg.jpg";
    final imageOfTheClass = FirebaseStorage.instance
        .ref()
        .child(
            'ClassroomPictures/${loggedInUserId}/${classInfo.currDate.toString()}')
        .child('${imageName}');

    bool classImgageUploaded = false;
    await imageOfTheClass.putFile(classroomImage).whenComplete(
      () {
        classImgageUploaded = true;
      },
    );

    final classroomImageUrl = await imageOfTheClass.getDownloadURL();

    try {
      classInfo.classroomUrl = classroomImageUrl.toString();
      final responseForPartialClassDetails = await http.post(
        urlLink,
        body: json.encode(
          {
            'uniqueInfo': classInfo.unqId.toString(),
            'currDateTime': classInfo.currDateTime.toString(),
            'currTime': classInfo.currTime.toString(),
            'currDate': classInfo.currDate.toString(),
            'numberOfHeads': classInfo.numOfStudents.toString(),
            'enteredStudnets': cntStudents.text.toString(),
            'currLatitude': classInfo.currLatitude.toString(),
            'currLongitude': classInfo.currLongitude.toString(),
            'currAddress': classInfo.currAddress.toString(),
            'imageLink': classroomImageUrl.toString(),
            'eventType': classInfo.eventType.toString(),
            'maleNumber': classInfo.maleNumber.toString(),
            'femaleNumber': classInfo.femaleNumber.toString(),
            'vaktaName': classInfo.vaktaName.toString(),
            'mobileNumber': classInfo.mobileNumber.toString(),
            'subEventType': classInfo.subEventType.toString(),
            'nameOfPerson': classInfo.nameOfPerson.toString(),
            'problemDetails': classInfo.problemDetails.toString()
          },
        ),
      );
      notifyListeners();
    } catch (errorVal) {
      print(errorVal);
    }
  }

  Future<void> fetchPreviousClasses() async {
    FirebaseFirestore db = FirebaseFirestore.instance;
    CollectionReference usersRef = db.collection("userPersonalInformation");

    var currLoggedInUser = await FirebaseAuth.instance.currentUser;
    var loggedInUserId = currLoggedInUser?.uid as String;

    final urlLink = Uri.https(
      'ekalgsrepo-db-default-rtdb.firebaseio.com',
      '/Events/${loggedInUserId}.json',
    );

    try {
      final dataBaseResponse = await http.get(urlLink);
      final extractedClass =
          json.decode(dataBaseResponse.body) as Map<String, dynamic>;

      if (extractedClass != Null) {
        final List<ClassInformation> loadedPreviousClasses = [];

        extractedClass.forEach(
          (classId, classData) {
            // print('In...');
            // print(classId);
            // print(classData);
            // print('Out...');

            ClassInformation prevClass = ClassInformation(
              unqId: classId,
              currDateTime: classData['currDateTime'],
              currTime: classData['currTime'],
              currDate: classData['currDate'],
              numOfStudents: int.parse(classData['numberOfHeads']),
              currLatitude: double.parse(classData['currLatitude']),
              currLongitude: double.parse(classData['currLongitude']),
              currAddress: classData['currAddress'],
              classroomUrl: classData['imageLink'],
              imageFile: File(""),
              eventType: classData['eventType'],
              maleNumber: classData['maleNumber'],
              femaleNumber: classData['femaleNumber'],
              vaktaName: classData['vaktaName'],
              mobileNumber: classData['mobileNumber'],
              subEventType: classData['subEventType'],
              nameOfPerson: classData['nameOfPerson'],
              problemDetails: classData['problemDetails']
            );

            loadedPreviousClasses.add(prevClass);
          },
        );

        _items = loadedPreviousClasses;
        notifyListeners();
      }
    } catch (errorVal) {
      print("Error Value");
      print(errorVal);
    }
  }
}
