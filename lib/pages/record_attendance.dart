import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';

class RecordAttendance extends StatelessWidget {
  final Map<String, dynamic>? qrData;

  const RecordAttendance({super.key, this.qrData});

  @override
  Widget build(BuildContext context) {
    print(qrData);
    return Scaffold(
      appBar: AppBar(),
      body: Padding(
        padding: EdgeInsets.all(10),
        child: Center(
          child: PrettyQrView.data(data: jsonEncode(qrData)),
        ),
      ),
    );
  }
}
