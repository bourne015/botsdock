import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:botsdock/data/adaptive.dart';

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
              FilledButton.tonalIcon(
                label: const Text('OK'),
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
  return Container(
    padding: EdgeInsets.only(top: 15),
    child: TextFormField(
        decoration: InputDecoration(
          // filled: true,
          // fillColor: AppColors.inputBoxBackground,
          labelText: hintText,
          prefixIcon: icon != null ? Icon(icon, color: Colors.blue) : null,
          // border: OutlineInputBorder(
          //   borderRadius: BorderRadius.circular(10),
          // ),
          hintText: hintText,
          hintStyle: Theme.of(context!).textTheme.labelMedium,
        ),
        obscureText: obscure ?? false,
        maxLines: 1,
        maxLength: maxLength,
        textInputAction: TextInputAction.newline,
        controller: ctr,
        validator: (v) {
          return v == null || v.trim().isNotEmpty ? null : "$hintText不能为空";
        }),
  );
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
          hintStyle: Theme.of(context!).textTheme.labelMedium,
          // border: OutlineInputBorder(borderRadius: BORDERRADIUS10),
        ),
        validator: (v) {
          return v == null || v.trim().isNotEmpty ? null : "不能为空";
        }),
  );
}

PopupMenuItem<dynamic> buildPopupMenuItem(BuildContext context,
    {dynamic value, IconData? icon, String? title}) {
  return PopupMenuItem<dynamic>(
    padding: EdgeInsets.symmetric(horizontal: 0, vertical: 0),
    value: value,
    child: Material(
      // color: AppColors.drawerBackground,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10),
        // decoration: BoxDecoration(
        //   borderRadius: BORDERRADIUS15,
        // ),
        child: InkWell(
          borderRadius: BORDERRADIUS15,
          onTap: () {
            Navigator.pop(context, value);
          },
          //onHover: (hovering) {},
          child: ListTile(
            contentPadding: EdgeInsets.symmetric(horizontal: 5),
            leading: icon != null ? Icon(size: 20, icon) : null,
            title: Text(
              title ?? "",
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ),
      ),
    ),
  );
}

Widget localImages(
    BuildContext context, List images, void Function(String) onClickImage) {
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
                    onClickImage(images[index]);
                    Navigator.of(context).pop();
                  },
                  hoverColor: Colors.grey.withValues(alpha: 0.3),
                  splashColor: Colors.brown.withValues(alpha: 0.5),
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
    void Function(String)? onClickImage}) {
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

Widget image_show(String img_path, double radius) {
  return img_path.startsWith("http")
      ? ClipRRect(
          borderRadius: BorderRadius.circular(80),
          child: Image.network(
            img_path,
            width: radius * 2,
            height: radius * 2,
            errorBuilder: (BuildContext context, Object exception,
                StackTrace? stackTrace) {
              return Container(
                width: radius * 2,
                height: radius * 2,
                decoration: BoxDecoration(
                    color: Colors.grey,
                    borderRadius: BorderRadius.circular(80)),
              );
            },
          ))
      : CircleAvatar(
          radius: radius,
          backgroundImage: AssetImage(img_path),
        );
}

/**
 * animation for loading
 */
void showLoading(BuildContext context, {String? text}) {
  showDialog(
    context: context,
    builder: (context) => Center(
      child: Container(
        // height: 55,
        // color: Colors.black54,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SpinKitPulsingGrid(
              color: const Color.fromARGB(255, 127, 180, 224),
            ),
            if (text != null) SizedBox(width: 10),
            if (text != null) Text(text, style: TextStyle(color: Colors.white)),
          ],
        ),
      ),
    ),
  );
}

class ThinkingIndicator extends StatelessWidget {
  const ThinkingIndicator({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 10),
      child: const SpinKitThreeBounce(
        color: Color.fromARGB(255, 140, 198, 247),
        size: AppSize.generatingAnimation,
      ),
    );
  }
}
