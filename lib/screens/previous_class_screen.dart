import 'dart:async';
// import 'dart:ffi';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:jaagran/models/class_info.dart';
import 'package:provider/provider.dart';

import '../constants/stringConst.dart';
import '../providers/class_details.dart';

import '../widgets/old_class_view.dart';

class PreviousClass extends StatefulWidget {
  static const routeName = '/previous-class-screen';
  @override
  State<PreviousClass> createState() => _PreviousClassState();
}

class _PreviousClassState extends State<PreviousClass> {
  ClassInformation nullClassInfo = ClassInformation(
      unqId: "",
      currDateTime: "",
      currTime: "",
      currDate: "",
      numOfStudents: 0,
      currLatitude: 0.0,
      currLongitude: 0.0,
      currAddress: "",
      classroomUrl: "",
      imageFile: File(""),
      eventType: "",
      maleNumber: "",
      femaleNumber: "",
      vaktaName: "",
      mobileNumber: "",
      subEventType: "",
      nameOfPerson: "",
      problemDetails: "");

  var _isInit = true;

  // @override
  //   void initState() {
  //     super.initState();

  //     // Future.delayed(Duration.zero).then((_) {
  //     //   Provider.of<ClassDetails>(context).fetchUserPrevClasses();
  //     // });
  //   }

  @override
  void didChangeDependencies() {
    if (_isInit) {
      Provider.of<ClassDetails>(context).fetchPreviousClasses();
    }
    _isInit = true;

    super.didChangeDependencies();
  }

  Future<void> _refreshPreviousClasses(BuildContext context) async {
    await Provider.of<ClassDetails>(context, listen: false)
        .fetchPreviousClasses();
  }

  @override
  Widget build(BuildContext context) {
    var screenHeight = MediaQuery.of(context).size.height;
    var screenWidth = MediaQuery.of(context).size.width;
    var topInsets = MediaQuery.of(context).viewInsets.top;
    var bottomInsets = MediaQuery.of(context).viewInsets.bottom;

    var classInfoData = Provider.of<ClassDetails>(context);

    return Container(
      child: classInfoData.items.length == 0
          ? RefreshIndicator(
              onRefresh: () => _refreshPreviousClasses(context),
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
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Container(
                        alignment: Alignment.center,
                        padding: EdgeInsets.symmetric(
                          horizontal: screenWidth * 0.1,
                        ),
                        child: Text(
                          S.prevClassBodyText,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontStyle: FontStyle.italic,
                            fontSize: screenWidth * 0.07,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          : Container(
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
                child: ListView.builder(
                  itemCount: classInfoData.items.length,
                  itemBuilder: (ctx, index) {
                    return OldClassView(
                      indexClass1: classInfoData.items.length - 1 - index,
                      indexClass2: -1,
                      infoClass1: classInfoData
                          .items[classInfoData.items.length - 1 - index],
                      infoClass2: nullClassInfo,
                    );
                  },
                ),
              ),
            ),
    );
  }
}
