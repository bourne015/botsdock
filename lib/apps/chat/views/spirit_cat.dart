import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

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

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 20), // 总的动画周期
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
    if (!isDisplayDesktop(context)) {
      _controller.stop();
    }
    return Positioned(
      left: _currentPosition,
      top: 0,
      child: GestureDetector(
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
              _currentPosition = _posX > 180
                  ? 180
                  : _posX < 0
                      ? 0
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

  void _updatePosition() {
    setState(() {
      if (_isMoving && !isDragging) {
        if (_isMovingRight) {
          _currentPosition += 0.25;
          if (_currentPosition >= 180) {
            _currentPosition = 180;
            _isMovingRight = false;
            _runImg = leftRunCat[_random.nextInt(leftRunCat.length)];
          }
        } else {
          _currentPosition -= 0.25;
          if (_currentPosition <= 5) {
            _currentPosition = 5;
            _isMovingRight = true;
            _runImg = rightRunCat[_random.nextInt(rightRunCat.length)];
          }
        }
      }
    });
  }

  void _scheduleNextStateChange() {
    _stateChangeTimer?.cancel();
    _stateChangeTimer = Timer(Duration(seconds: 2 + _random.nextInt(15)), () {
      _changeState();
      _scheduleNextStateChange();
    });
  }

  String getRestPose() {
    return restCat[Random().nextInt(restCat.length)];
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
  List<String> restCat = [
    "assets/images/cat/cat3.avif",
    "assets/images/cat/cat7.avif",
    "assets/images/cat/cat17.avif",
    "assets/images/cat/cat20.avif",
    "assets/images/cat/cat21.avif",
    "assets/images/cat/cat25-1.png",
    "assets/images/cat/cat27.avif",
    "assets/images/cat/cat30.avif",
    "assets/images/cat/cat31.avif",
    "assets/images/cat/cat35.avif",
    "assets/images/cat/cat36.avif",
    "assets/images/cat/cat37.avif",
    "assets/images/cat/cat41.avif",
    "assets/images/cat/cat42.avif",
    "assets/images/cat/cat46.avif",
    "assets/images/cat/cat48.avif",
    "assets/images/cat/cat49.avif",
  ];
}
