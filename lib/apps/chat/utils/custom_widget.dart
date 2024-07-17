import 'package:flutter/material.dart';
import 'package:gallery/data/adaptive.dart';

import 'constants.dart';

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

void showMaterialBanner(BuildContext context, String message) {
  final scaffoldMessenger = ScaffoldMessenger.maybeOf(context);

  if (scaffoldMessenger != null) {
    scaffoldMessenger.showMaterialBanner(
      MaterialBanner(
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              scaffoldMessenger.hideCurrentMaterialBanner();
            },
            child: Text('关闭'),
          ),
        ],
      ),
    );
  }
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
      maxLength: maxLength,
      textInputAction: TextInputAction.newline,
      controller: ctr,
      validator: (v) {
        return v == null || v.trim().isNotEmpty ? null : "$hintText不能为空";
      });
}

Widget botTextFormField(
    {BuildContext? context,
    String? hintText,
    TextEditingController? ctr,
    int? maxLength,
    int? maxLines,
    String? Function(String?)? validator}) {
  return Container(
    margin: EdgeInsets.fromLTRB(0, 10, 0, 5),
    child: TextFormField(
        controller: ctr,
        maxLines: maxLines,
        maxLength: maxLength,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(fontSize: 14),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
        validator: (v) {
          return v == null || v.trim().isNotEmpty ? null : "不能为空";
        }),
  );
}

PopupMenuItem<String> buildPopupMenuItem(BuildContext context,
    {String? value, IconData? icon, String? title}) {
  return PopupMenuItem<String>(
    padding: EdgeInsets.symmetric(horizontal: 0, vertical: 0),
    value: value,
    child: Material(
      color: AppColors.drawerBackground,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(15),
          onTap: () {
            Navigator.pop(context, value);
          },
          //onHover: (hovering) {},
          child: ListTile(
              contentPadding: EdgeInsets.symmetric(horizontal: 5),
              leading: icon != null ? Icon(size: 20, icon) : null,
              title: Text(title ?? "")),
        ),
      ),
    ),
  );
}

Widget localImages(
    BuildContext context, List images, void Function(int) onClickImage) {
  return ListBody(
    children: [
      GridView.builder(
        shrinkWrap: true,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 6,
          childAspectRatio: 1,
        ),
        itemCount: images.length, //BotImages.length,
        itemBuilder: (BuildContext context, int index) {
          return Container(
              margin: EdgeInsets.all(5),
              child: InkWell(
                  onTap: () async {
                    onClickImage(index);
                    Navigator.of(context).pop();
                  },
                  hoverColor: Colors.grey.withOpacity(0.3),
                  splashColor: Colors.brown.withOpacity(0.5),
                  child: Ink(
                    height: 80,
                    width: 80,
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage(images[index]),
                        fit: BoxFit.cover,
                      ),
                    ),
                  )));
        },
      ),
    ],
  );
}

void showCustomBottomSheet(BuildContext context,
    {List? images,
    void Function(BuildContext)? pickFile,
    void Function(int)? onClickImage}) {
  showModalBottomSheet(
    context: context,
    elevation: 5,
    isScrollControlled: true,
    shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(15))),
    builder: (BuildContext context) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (pickFile != null)
              ListTile(
                leading: Icon(Icons.upload),
                title: Text('上传本地图片'),
                onTap: () {
                  Navigator.pop(context);
                  pickFile(context);
                },
              ),
            Divider(),
            Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('选择图片'),
              ),
            ),
            localImages(context, images ?? [], onClickImage ?? (v) {}),
          ],
        ),
      );
    },
  );
}
