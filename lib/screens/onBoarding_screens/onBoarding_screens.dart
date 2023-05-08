import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import './onBoarding_Screen1.dart';
import './onBoarding_screen2.dart';

class onBoardingScreens extends StatefulWidget {
  static const routeName = '/onBoardingScreens';

  final Function setShowOnboarding;

  onBoardingScreens(this.setShowOnboarding);
  @override
  _onBoardingScreensState createState() => _onBoardingScreensState();
}

class _onBoardingScreensState extends State<onBoardingScreens> {
  final PageController _pagesController = PageController();
  bool onLastPage = false;

  Future<void> _setOnboardingSeen() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSeenOnboarding', true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          PageView(
            controller: _pagesController,
            onPageChanged: (index) {
              setState(() {
                onLastPage = (index == 1);
              });
            },
            children: [
              onBoardingScreen1(),
              onBoardingScreen2(),
            ],
          ),
          Container(
            alignment: Alignment(0, 0.9),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                //Skip button
                GestureDetector(
                    onTap: () async {
                      await _setOnboardingSeen();
                      widget.setShowOnboarding(false);
                    },
                    child: Text("skip")),
                SmoothPageIndicator(
                    controller: _pagesController,
                    count: 2,
                    effect: const WormEffect(
                        activeDotColor: Colors.deepPurple,
                        dotColor: Colors.white)),
                //next or done when on last page
                onLastPage
                    ? GestureDetector(
                        onTap: () async {
                          await _setOnboardingSeen();
                          widget.setShowOnboarding(false);
                        },
                        child: Text('done'))
                    : GestureDetector(
                        onTap: () {
                          _pagesController.nextPage(
                              duration: Duration(microseconds: 500),
                              curve: Curves.easeIn);
                        },
                        child: Text('next'))
              ],
            ),
          )
        ],
      ),
    );
  }
}
