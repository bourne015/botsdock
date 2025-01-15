import 'dart:async';
import 'dart:math';

import 'package:botsdock/apps/chat/models/pages.dart';
import 'package:botsdock/apps/chat/models/user.dart';
import 'package:botsdock/apps/chat/utils/constants.dart';
import 'package:botsdock/apps/chat/vendor/assistants_api.dart';
import 'package:botsdock/apps/chat/vendor/chat_api.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';

import '../../../data/adaptive.dart';

class SpiritCat extends StatefulWidget {
  SpiritCat({Key? key}) : super(key: key);

  @override
  SpiritCatState createState() => SpiritCatState();
}

class SpiritCatState extends State<SpiritCat>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  String _currentRestPose = '';
  bool _isMoving = true;
  bool _isMovingRight = true;
  final Random _random = Random();
  double _currentPosition = 0;
  Timer? _stateChangeTimer;
  bool isDragging = false;
  late Offset dragStart;
  String _dragImg = '';
  String _runImg = "assets/images/cat/cat11.avif";
  List<String>? _cats;
  double leftPosition = 5.0;
  double rightPosition = 240.0;
  final assistant = AssistantsAPI();
  final ChatAPI chats = ChatAPI();
  final dio = Dio();

  @override
  void initState() {
    super.initState();
    _cats = restCat.keys.toList();
    _controller = AnimationController(
      duration: const Duration(seconds: 40), // 总的动画周期
      vsync: this,
    );

    _controller.addListener(_updatePosition);
    _controller.repeat();

    // 开始随机状态变化
    _scheduleNextStateChange();
  }

  @override
  void dispose() {
    _controller.dispose();
    _stateChangeTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    User user = Provider.of<User>(context, listen: false);
    Pages pages = Provider.of<Pages>(context, listen: false);
    Property property = Provider.of<Property>(context, listen: false);
    if (!isDisplayDesktop(context)) {
      _controller.stop();
    }
    return Positioned(
      left: _currentPosition,
      top: 0,
      child: GestureDetector(
          onDoubleTap: user.isLogedin
              ? () async {
                  chat_cat(pages, user, property);
                }
              : null,
          onTap: () {
            // ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            //   content: Text('Meow!'),
            // ));
            _isMoving = false;
            _currentRestPose = clickCat[_random.nextInt(clickCat.length)];
          },
          onPanStart: (details) {
            isDragging = true;
            print("drag");
            dragStart = details.globalPosition - Offset(_currentPosition, 0);
            _dragImg = dragCat[_random.nextInt(dragCat.length)];
          },
          onPanUpdate: (details) {
            setState(() {
              var _posX = details.globalPosition.dx - dragStart.dx;
              _currentRestPose = _dragImg;
              _currentPosition = _posX > rightPosition
                  ? rightPosition
                  : _posX < leftPosition
                      ? leftPosition
                      : _posX;
            });
          },
          onPanEnd: (details) {
            isDragging = false;
          },
          child: Transform.scale(
            scaleX: _isMovingRight ? 1 : 1,
            child: CircleAvatar(
              radius: 25,
              backgroundColor: Colors.transparent,
              backgroundImage: AssetImage(
                _isMoving ? _runImg : _currentRestPose,
              ),
            ),
          )),
    );
  }

  void chat_cat(Pages pages, User user, Property property) async {
    String? ass_id = dotenv.maybeGet(
      "assistant_id_cat",
      fallback: null,
    );
    if (ass_id == null) return;
    int handlePageID = pages.checkCat(ass_id);
    if (handlePageID != -1) {
      pages.currentPageID = handlePageID;
      property.onInitPage = false;
    } else {
      if (user.cat_id == null) {
        user.cat_id = await assistant.createThread();
        var userdata = {"cat_id": user.cat_id};
        var editUser = USER_URL + "/" + "${user.id}";
        await dio.post(editUser, data: userdata);
      }

      if (user.cat_id != null) {
        handlePageID = assistant.newassistant(
            pages, property, user, user.cat_id!,
            ass_id: ass_id, chat_title: "cat");
        pages.setGeneratingState(handlePageID, true);
        pages.getPage(handlePageID).addMessage(
              role: MessageTRole.system,
              text: "我是你的主人${user.name}",
            );
        chats.submitAssistant(pages, property, handlePageID, user, {});
      }
    }
  }

  void _updatePosition() {
    setState(() {
      if (_isMoving && !isDragging) {
        if (_isMovingRight) {
          _currentPosition += 0.2;
          if (_currentPosition >= rightPosition) {
            _currentPosition = rightPosition;
            _isMovingRight = false;
            _runImg = leftRunCat[_random.nextInt(leftRunCat.length)];
          }
        } else {
          _currentPosition -= 0.2;
          if (_currentPosition <= leftPosition) {
            _currentPosition = leftPosition;
            _isMovingRight = true;
            _runImg = rightRunCat[_random.nextInt(rightRunCat.length)];
          }
        }
      }
    });
  }

  void _scheduleNextStateChange() {
    _stateChangeTimer?.cancel();
    int _dl = 1 + _random.nextInt(10);
    if (restCat.containsKey(_currentRestPose)) {
      _dl = restCat[_currentRestPose]!;
    } else if (clickCat.contains(_currentRestPose)) {
      _dl = 1;
    }
    _stateChangeTimer = Timer(Duration(seconds: _dl), () {
      _changeState();
      _scheduleNextStateChange();
    });
  }

  String getRestPose() {
    int c = Random().nextInt(restCat.length);

    return _cats![c];
  }

  void _changeState() {
    setState(() {
      _isMoving = !_isMoving;
      if (_isMoving) {
        _isMovingRight = _random.nextBool();
        _currentRestPose = '';
        _runImg = _isMovingRight
            ? rightRunCat[_random.nextInt(rightRunCat.length)]
            : leftRunCat[_random.nextInt(leftRunCat.length)];
      } else {
        _currentRestPose = getRestPose();
      }
    });
  }

  List<String> dragCat = [
    "assets/images/cat/cat13.avif",
  ];
  List<String> leftRunCat = [
    "assets/images/cat/cat4.avif",
  ];
  List<String> rightRunCat = [
    "assets/images/cat/cat11.avif",
    "assets/images/cat/cat28.avif",
  ];
  List<String> clickCat = [
    "assets/images/cat/cat12.avif",
    "assets/images/cat/cat21.avif",
  ];
  Map<String, int> restCat = {
    "assets/images/cat/cat3.avif": 20, //wag tail, slow
    "assets/images/cat/cat7.avif": 10, //click phone
    "assets/images/cat/cat17.avif": 20, //dance
    "assets/images/cat/cat20.avif": 10, //love shake
    "assets/images/cat/cat21.avif": 20, //angry
    "assets/images/cat/cat25-1.png": 30, //sleep
    "assets/images/cat/cat27.avif": 10, //ask food
    "assets/images/cat/cat30.avif": 5, //love
    "assets/images/cat/cat31.avif": 5, //play phone,sit
    "assets/images/cat/cat35.avif": 20, //eating
    "assets/images/cat/cat36.avif": 30, //play phone, lay
    "assets/images/cat/cat37.avif": 2, //draw love
    "assets/images/cat/cat41.avif": 3, //wag tail, fast
    "assets/images/cat/cat42.avif": 2, //love kiss
    "assets/images/cat/cat46.avif": 2, //shot by love arrow
    "assets/images/cat/cat48.avif": 5, //click keyboard
    "assets/images/cat/cat49.avif": 5, //play love ball
  };
}
