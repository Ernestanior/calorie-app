import 'dart:async';

import 'package:calorie/common/circlePainter/new.dart';
import 'package:calorie/common/icon/index.dart';
import 'package:calorie/components/actionSheets/stepAuth.dart';
import 'package:calorie/components/actionSheets/weight.dart';
import 'package:calorie/page/profile/premiumCard.dart';
import 'package:calorie/page/profile/stepCard.dart';
import 'package:calorie/page/profile/weightCard.dart';
import 'package:calorie/page/step/healthService.dart';
import 'package:calorie/store/store.dart';
import 'package:calorie/store/user.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile>
    with RouteAware, WidgetsBindingObserver {
  final HealthService _healthService = HealthService();
  bool stepPermission = false;
  int todaySteps = 0;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadSteps();
    _stepPermission();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      _stepPermission();
      _loadSteps();
    }
  }

  Future<void> _stepPermission() async {
    try {
      bool p = await _healthService.checkStepPermission();
      setState(() {
        stepPermission = p;
      });
    } catch (e) {
      print('error $e');
    }
  }

  Future<void> _loadSteps() async {
    try {
      final steps = await _healthService.getTodaySteps();
      setState(() {
        todaySteps = steps;
      });
    } catch (e) {
      print('error $e');
    }
  }

  @override
  void didPopNext() {
    // 从页面B返回后触发
    UserInfo().getUserInfo();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [
                Color.fromARGB(255, 238, 251, 255),
                Color.fromARGB(255, 255, 250, 250),
                Color.fromARGB(255, 241, 252, 255)
              ],
            ),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 25),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 15),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () async {
                          Navigator.pushNamed(context, '/weight');
                        },
                        child: Obx(() => WeightCard(
                              currentWeight: Controller.c.user['currentWeight'],
                              type: Controller.c.user['targetType'],
                              initWeight: Controller.c.user['initWeight'],
                              targetWeight: Controller.c.user['targetWeight'],
                              onAdd: () {
                                Get.bottomSheet(WeightSheet(
                                  weight: Controller.c.user['currentWeight']
                                      .toDouble(),
                                  onChange: () => {},
                                ));
                                // Get.bottomSheet(StepSheet());
                              },
                              onMore: () {
                                // 跳转到体重记录页
                              },
                            )),
                      ),
                      GestureDetector(
                        onTap: () async {
                          if (stepPermission) {
                            Navigator.pushNamed(context, '/step');
                          } else {
                            // 等待 bottomSheet 关闭并接收返回值
                            await Get.bottomSheet(const StepAuthSheet())
                                .then((e) {
                              _stepPermission();
                            });
                          }
                        },
                        child: Obx(() => StepCard(
                              todaySteps: todaySteps,
                              targetSteps: Controller.c.user['targetStep'],
                              permission: stepPermission,
                            )),
                      ),
                    ],
                  ),
                  _buildBMICircle(),
                  PremiumCard(),
                  _buildCalorieGoal(),
                  _buildOptionsList(),
                  const SizedBox(
                    height: 60,
                  )
                ],
              ),
            ),
          )),
    );
  }

  Widget _buildHeader() {
    return Row(children: [
Text(
      'MINE'.tr,
      style: const TextStyle(
          fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black),
    ),
    Text(
      '${Controller.c.user['id']}',
      style: const TextStyle(
          fontSize: 11,  color: Color.fromARGB(255, 157, 157, 157)),
    )
    ],) ;
  }

  List weightList = [
    {'title': 'CURRENT'.tr, 'weight': 67, 'icon': AliIcon.fitness},
    {'title': 'TARGET'.tr, 'weight': 64, 'icon': AliIcon.fitness}
  ];

  Widget _buildBMICircle() {
    return Container(
        margin: const EdgeInsets.symmetric(vertical: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
              color: Color.fromARGB(31, 146, 154, 218),
              blurRadius: 5,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Obx(() => BMICard(
            bmi: Controller.c.user['unitType'] == 0
                ? double.parse((Controller.c.user['currentWeight'] /
                        (Controller.c.user['height'] *
                            Controller.c.user['height'] /
                            10000))
                    .toStringAsFixed(2))
                : double.parse((Controller.c.user['currentWeight'] /
                        (Controller.c.user['height'] *
                            Controller.c.user['height']) *
                        703)
                    .toStringAsFixed(2)))));
  }

  Widget _buildCalorieGoal() {
    return Container(
        margin: const EdgeInsets.symmetric(vertical: 10),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Color.fromARGB(31, 146, 154, 218),
              blurRadius: 5,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          children: [
            _OptionItem(
                title: 'ADJUST_CALORIE_GOAL'.tr,
                icon: AliIcon.edit2,
                url: '/survey'),
          ],
        ));
  }

  Widget _buildOptionsList() {
    return Container(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Color.fromARGB(31, 146, 154, 218),
              blurRadius: 5,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          children: [
            _OptionItem(
                title: 'PERSONAL_DETAIL'.tr,
                icon: AliIcon.setting1,
                url: '/profileDetail'),
            _OptionItem(
                title: 'DIET_PLAN'.tr,
                icon: AliIcon.dinner,
                url: '/recipeCollect'),
            _OptionItem(
                title: 'SETTING'.tr, icon: AliIcon.setting, url: '/setting'),
            //             _OptionItem(
            // title: 'Testing'.tr, icon: AliIcon.email, url: '/guide'),
          ],
        ));
  }
}

class _OptionItem extends StatelessWidget {
  final String title;
  final String url;
  final IconData icon;

  const _OptionItem(
      {required this.title, required this.icon, required this.url});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 0.0),
      title: Row(
        children: [
          Icon(
            icon,
            size: 18,
          ),
          const SizedBox(
            width: 15,
          ),
          Text(title, style: const TextStyle(fontSize: 15)),
        ],
      ),
      trailing: const Icon(Icons.chevron_right,
          color: Color.fromARGB(255, 214, 214, 214)),
      onTap: () {
        Navigator.pushNamed(context, url);
      },
    );
  }
}
