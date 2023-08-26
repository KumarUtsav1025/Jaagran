import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:jaagran/screens/tabs_screen.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_storage/firebase_storage.dart';

import '../screens/tabs_screen.dart';
import '../models/visitor_info.dart';

class LocationDetails with ChangeNotifier {
  List<VisitorInformation> _items = [];

  List<VisitorInformation> get items {
    return [..._items];
  }

  Future<void> addLocationDetails(
    BuildContext context,
    TextEditingController detailsProviderUniqueId,
    File fetchedImg,
    String fetchedDateTime,
    String fetchedLatitude,
    String fetchedLongitude,
    String fetchedAddress,
    TextEditingController fetchedLocationDescription,
    TextEditingController sthalType,
    TextEditingController astherType,
    TextEditingController prabhagType,
    TextEditingController sambhagType,
    TextEditingController bhagType,
    TextEditingController anchalType,
    TextEditingController clusterType,
    TextEditingController sanchType,
    TextEditingController upSanchType,
    TextEditingController villageType,
  ) async {
    FirebaseFirestore db = FirebaseFirestore.instance;
    CollectionReference usersRef = db.collection("userPersonalInformation");

    var currLoggedInUser = await FirebaseAuth.instance.currentUser;
    var loggedInUserId = currLoggedInUser?.uid as String;

    final urlLink = Uri.https(
      'ekalgsrepo-db-default-rtdb.firebaseio.com',
      '/FetchedLocationDetails/${detailsProviderUniqueId.text.toString()}.json',
    );

    String imageName =
        "${loggedInUserId}_${DateTime.now().toString()}_LocationImg.jpg";
    final imageOfTheLocation = FirebaseStorage.instance
        .ref()
        .child('FetchedLocationPictures')
        .child('${imageName}');

    bool locationImgageUploaded = false;
    await imageOfTheLocation.putFile(fetchedImg).whenComplete(
      () {
        locationImgageUploaded = true;
      },
    );

    final locationImageUrl = await imageOfTheLocation.getDownloadURL();

    try {
      final responseForPartialLocationDetails = await http.post(
        urlLink,
        body: json.encode(
          {
            'detailsProviderUniqueId': detailsProviderUniqueId.text.toString(),
            'currDateTime': fetchedDateTime.toString(),
            'currLatitude': fetchedLatitude.toString(),
            'currLongitude': fetchedLongitude.toString(),
            'currAddress': fetchedAddress.toString(),
            'locationDescription': fetchedLocationDescription.text.toString(),
            'sthal': sthalType.text.toString(),
            'asther': astherType.text.toString(),

            'prabhag': prabhagType.text.toString(),
            'sambhag': sambhagType.text.toString(),
            'bhag': bhagType.text.toString(),
            'anchal': anchalType.text.toString(),
            'cluster': clusterType.text.toString(),
            'sanch': sanchType.text.toString(),
            'upSanch': upSanchType.text.toString(),
            'village': villageType.text.toString(),
            'imageLink': locationImageUrl.toString(),
          },
        ),
      );

      Navigator.of(context).pushReplacementNamed(TabsScreen.routeName);
      notifyListeners();
    } catch (errorVal) {
      print(errorVal);
    }
  }

  Future<void> fetchregisteredLocations() async {
    FirebaseFirestore db = FirebaseFirestore.instance;
    CollectionReference usersRef = db.collection("userPersonalInformation");

    var currLoggedInUser = await FirebaseAuth.instance.currentUser;
    var loggedInUserId = currLoggedInUser?.uid as String;

    final urlLink = Uri.https(
      'ekalgsrepo-db-default-rtdb.firebaseio.com',
      '/FetchedLocationDetails.json',
    );

    final urlParse = Uri.parse(
      'https://ekalgsrepo-db-default-rtdb.firebaseio.com/FetchedLocationDetails.json',
    );

    try {
      final dataBaseResponse = await http.get(urlLink);
      final extractedLocation =
          json.decode(dataBaseResponse.body) as Map<String, dynamic>;

      if (extractedLocation != Null) {
        final List<VisitorInformation> loadedPreviousLocations = [];

        extractedLocation.forEach(
          (locationId, locationData) {
            // print('In...');
            // print(classId);
            // print(classData);
            // print('Out...');

            VisitorInformation fetchedLocation = new VisitorInformation(
              visitorUniqueId: locationId,
              visitorName: locationData['name'],
              visitorMobileNumber: locationData['mobileNumber'],
              visitorDayitva: locationData['dayitva'],
              visitorAddressType: locationData['addressType'],
              visitorState: locationData['state'],
              visitorRegion: locationData['region'],
              visitorDistrict: locationData['district'],
              visitorAnchal: locationData['anchal'],
              visitorSankul: locationData['sankul'],
              visitorCluster: locationData['cluster'],
              visitorSubCluster: locationData['subCluster'],
              visitorVillage: locationData['village'],
              visitorImgFileLink: locationData['imageLink'],
              detailsProviderUniqueId: locationData['detailsProviderUniqueId'],
              fetchingDateTime: locationData['currDateTime'],
              fetchedLatitude: locationData['currLatitude'],
              fetchedLongitude: locationData['currLongitude'],
              fetchedAddress: locationData['currAddress'],
            );

            loadedPreviousLocations.add(fetchedLocation);
          },
        );

        _items = loadedPreviousLocations;
        notifyListeners();
      }
    } catch (errorVal) {
      print("Error Value");
      print(errorVal);
    }
  }
}
