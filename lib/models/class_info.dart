import 'dart:io';

// part 'class_info.g.dart';

class ClassInformation {
  final String unqId;
  final String currDateTime;
  final String currTime;
  final String currDate;
  final int numOfStudents;
  final double currLatitude;
  final double currLongitude;
  final String currAddress;
  String classroomUrl;
  final File imageFile;
  final String eventType;
  final String maleNumber;
  final String femaleNumber;
  final String vaktaName;
  final String mobileNumber;
  final String subEventType;
  final String nameOfPerson;
  final String problemDetails;

  ClassInformation({
    required this.unqId,
    required this.currDateTime,
    required this.currTime,
    required this.currDate,
    required this.numOfStudents,
    required this.currLatitude,
    required this.currLongitude,
    required this.currAddress,
    required this.classroomUrl,
    required this.imageFile,
    required this.eventType,
    required this.maleNumber,
    required this.femaleNumber,
    required this.vaktaName,
    required this.mobileNumber,
    required this.subEventType,
    required this.nameOfPerson,
    required this.problemDetails
  });
}