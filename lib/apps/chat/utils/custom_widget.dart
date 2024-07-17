import 'package:flutter/material.dart';
import 'package:gallery/data/adaptive.dart';

void notifyBox({context, var title, var content}) {
  showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
            title: Text(title),
            content: SingleChildScrollView(
              child: ListBody(
                children: <Widget>[
                  Text(content),
                ],
              ),
            ),
            actions: <Widget>[
              TextButton(
                child: const Text('OK'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          ));
}

void showMessage(BuildContext context, String msg) {
  var _marginL = 50.0;

  if (isDisplayDesktop(context)) _marginL = 20;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      duration: Duration(milliseconds: 900),
      content: Text(msg, textAlign: TextAlign.center),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(10.0))),
      behavior: SnackBarBehavior.floating,
      margin: EdgeInsets.only(left: _marginL, right: 50),
    ),
  );
}

Widget logTextFormField(
    {BuildContext? context,
    String? hintText,
    TextEditingController? ctr,
    bool? obscure,
    IconData? icon,
    int? maxLength}) {
  return TextFormField(
      decoration: InputDecoration(
          //filled: true,
          //fillColor: AppColors.inputBoxBackground,
          labelText: hintText,
          prefixIcon: icon != null
              ? Icon(
                  icon,
                  color: Colors.blue,
                )
              : null,
          // border: OutlineInputBorder(
          //   borderRadius: BorderRadius.circular(10),
          // ),
          hintText: hintText),
      obscureText: obscure ?? false,
      maxLines: 1,
      maxLength: maxLength ?? null,
      textInputAction: TextInputAction.newline,
      controller: ctr,
      validator: (v) {
        return v == null || v.trim().isNotEmpty ? null : "$hintText不能为空";
      });
}
