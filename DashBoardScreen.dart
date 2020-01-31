import 'dart:async';
import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_imf/apis/ApiConfig.dart';
import 'package:flutter_imf/modals/response/LoginResponse.dart';
import 'package:flutter_imf/mvp/DashboardContract.dart';
import 'package:flutter_imf/ui/screens/stateful/FilterScreen.dart';
import 'package:flutter_imf/ui/screens/stateful/trip_layout.dart';
import 'package:flutter_imf/ui/screens/stateless/setting_page.dart';
import 'package:flutter_imf/ui/screens/stateless/trip_empty_screen.dart';
import 'package:flutter_imf/utils/Constants.dart';
import 'package:flutter_imf/utils/InternalConstants.dart';
import 'package:flutter_imf/utils/ScreenUtils.dart';
import 'package:flutter_imf/utils/TransparentPageRoute.dart';
import 'package:flutter_imf/utils/app_defaults.dart';
import 'package:flutter_imf/utils/app_utils.dart';
import 'package:flutter_imf/utils/color.dart';

import 'ManualDistanceScreen.dart';
import 'report_tab.dart';
import 'ReferralScreen.dart';
import 'calender_demo.dart';

import 'expense_layout.dart';

class DashBoardScreen extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => DashBoardState();
}

class DashBoardState extends State<DashBoardScreen> with DashboardContract {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  StreamController<UserData> _drawerController = StreamController.broadcast();

  final tabBarViewIconList = [
    "assets/report_icon.png",
    "assets/calendar_icon.png",
    "assets/trip_icon.png",
    "assets/referral_icon.png",
  ];

  final tabBarViewTextList = [
    "Reports",
    "Calendar",
    "Trips",
    "Referrals",
  ];

  final titleTextList = [
    "Reports",
    "Calendar",
    "Expense",
    "Trips",
    "Referrals",
  ];

  DashboardPresenter presenter;
  int defaultTabSelected = 3; // Expense List Screen

  @override
  void initState() {
    super.initState();
  }

  BuildContext _context;
  StreamController<int> _selectedTabController = StreamController.broadcast();
  StreamController<Map<FilterType, dynamic>> _reportTypeController =
      StreamController.broadcast();

  @override
  void dispose() {
    _selectedTabController.close();
    _reportTypeController.close();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    SystemChrome.setEnabledSystemUIOverlays([]);
    presenter = DashboardPresenter(this);
    _context = context;
    getUserData(_context);
    return MediaQuery.removePadding(
      removeBottom: true,
      context: context,
      child: Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          centerTitle: true,
          backgroundColor: HexColor(color.themeBlue),
          title: StreamBuilder<int>(
              stream: _selectedTabController.stream,
              initialData: defaultTabSelected,
              builder: (context, snapshot) {
                int tab = snapshot.data;

                return ScreenUtils.textViewWithOutClick(
                    context, titleTextList[tab - 1],
                    fontSize: 16.0,
                    fontWeight: FontWeight.w600,
                    color: Colors.white);
              }),
          actions: <Widget>[
            StreamBuilder<int>(
                stream: _selectedTabController.stream,
                initialData: defaultTabSelected,
                builder: (context, snapshot) {
                  return Visibility(
                    visible: snapshot.data == 1 ? true : false,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: StreamBuilder<Map<FilterType, dynamic>>(
                          stream: _reportTypeController.stream,
                          initialData: {FilterType.Latest: List()},
                          builder: (context, snapshot) {
                            Map<FilterType, dynamic> snapMap = Map();
                            snapMap = snapshot.data;

                            return InkWell(
                              onTap: () async {
                                final FilterScreen screen = FilterScreen(
                                    selectedType: snapMap.keys.toList()[0]);
                                Map<FilterType, dynamic> map =
                                    await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => screen),
                                );
                                _reportTypeController.sink.add(map);
                              },
                              child: Image.asset("assets/filter_ico.png"),
                            );
                          }),
                    ),
                  );
                }),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: InkWell(
                onTap: () {
                  final SettingScreen settingPage = SettingScreen();
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => settingPage),
                  );
                },
                child: Image.asset("assets/settings_icon.png"),
              ),
            )
          ],
          leading: InkWell(
            onTap: () => _scaffoldKey.currentState.openDrawer(),
            child: Image.asset("assets/left_menu.png"),
          ),
        ),
        body: Container(
          child: StreamBuilder<int>(
              stream: _selectedTabController.stream,
              initialData: defaultTabSelected,
              builder: (context, snapshot) {
                int tab = snapshot.data;
                if (tab == 1) {
                  return StreamBuilder<Map<FilterType, dynamic>>(
                      stream: _reportTypeController.stream,
                      initialData: {FilterType.Latest: List()},
                      builder: (context, snapshot) {
                        Map<FilterType, dynamic> snapMap = snapshot.data;
                        var reportTab = ReportTab(
                          type: snapMap.keys.toList()[0],
                          filterStreamController: _reportTypeController,
                        );
                        //reportTab.filterStreamController.sink.add(snapshot.data);
                        return reportTab;
                      });
                } else if (tab == 2) {
                  return CalenderScreen(
                    title: "Calender",
                  );
                } else if (tab == 3) {
                  return ExpenseLayout();
                } else if (tab == 5) {
                  return ReferralScreen();
                } else {
                  return TripLayout();
                }
              }),
        ),
        drawer: Drawer(child: drawerView(context)),
        bottomNavigationBar: StreamBuilder<int>(
            stream: _selectedTabController.stream,
            initialData: defaultTabSelected,
            builder: (context, snapshot) {
              int tab = snapshot.data;
              return Container(
                height: 70,
                child: new BottomAppBar(
                  color: HexColor(color.themeBlue),
                  shape: CircularNotchedRectangle(),
                  notchMargin: 0,
                  child: Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: new Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                        tabBarView(tabBarViewIconList[0], tabBarViewTextList[0],
                            onClick: () {
                          _selectedTabController.sink.add(1);
                        }, isSelected: tab == 1 ? true : false),
                        Padding(
                          padding: EdgeInsets.only(right: 40),
                          child: tabBarView(
                              tabBarViewIconList[1], tabBarViewTextList[1],
                              onClick: () {
                            _selectedTabController.sink.add(2);
                          }, isSelected: tab == 2 ? true : false),
                        ),
                        tabBarView(tabBarViewIconList[2], tabBarViewTextList[2],
                            onClick: () {
                          _selectedTabController.sink.add(4);
                        }, isSelected: tab == 4 ? true : false),
                        tabBarView(tabBarViewIconList[3], tabBarViewTextList[3],
                            onClick: () {
                          _selectedTabController.sink.add(5);
                        }, isSelected: tab == 5 ? true : false),
                      ],
                    ),
                  ),
                ),
              );
            }),
        floatingActionButton: StreamBuilder<int>(
            stream: _selectedTabController.stream,
            initialData: defaultTabSelected,
            builder: (context, snapshot) {
              int tab = snapshot.data;
              return InkWell(
                  onTap: () {
                    _selectedTabController.sink.add(3);
                  },
                  child: Image.asset(tab == 3
                      ? "assets/expense_ico.png"
                      : "assets/unexpense_ico.png"));
            }),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      ),
    );
  }

  drawerView(BuildContext context) {
    return Container(
      // color: ,
      child: Container(
        child: ListView(
          children: <Widget>[
            StreamBuilder<UserData>(
                stream: _drawerController.stream,
                initialData: AppConstants.of(context).data,
                builder: (context, snapshot) {
                  UserData userData = snapshot.data;
                  return DrawerHeader(
                    padding: const EdgeInsets.all(0),
                    margin: const EdgeInsets.fromLTRB(0, 0, 0, 0),
                    child: Container(
                      alignment: Alignment.center,
                      padding: EdgeInsets.all(20),
                      child: Column(
                        children: <Widget>[
                          Stack(
                            alignment: Alignment.center,
                            children: <Widget>[
                              CircleAvatar(
                                radius: 40.0,
                                backgroundColor: Colors.lightGreenAccent,
                              ),
                              Center(
                                child: CircleAvatar(
                                  radius: 40.0,
                                  backgroundImage: userData.imageUrl != null
                                      ? NetworkImage(userData.imageUrl)
                                      : AssetImage("assets/profile_pic.png"),
                                ),
                              ),
                            ],
                          ),
                          ScreenUtils.textView(context,
                              userData.firstName + " " + userData.lastName,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white)
                        ],
                      ),
                      decoration: BoxDecoration(
                          image: DecorationImage(
                              image: AssetImage("assets/left_menu_bg.png"),
                              fit: BoxFit.fill)),
                    ),
                    decoration:
                        BoxDecoration(color: Theme.of(context).buttonColor),
                  );
                }),
            _listTile(context,
                text: "Expense",
                icon: "assets/expense_menu.png",
                onClick: () => changeTab(3)),
            _listTile(context,
                text: "Reports",
                icon: "assets/report_menu.png",
                onClick: () => changeTab(1)),
            _listTile(context,
                text: "Calendar",
                icon: "assets/calendar_menu.png",
                onClick: () => changeTab(2)),
            _listTile(context,
                text: "Trips",
                icon: "assets/trip_menu.png",
                onClick: () => changeTab(4)),
            _listTile(context,
                text: "Referral",
                icon: "assets/referral_menu.png",
                onClick: () => changeTab(5)),
            _listTile(context,
                text: "Settings",
                icon: "assets/settings_menu.png", onClick: () {
              closeDrawer();
              final SettingScreen settingPage = SettingScreen();
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => settingPage),
              );
            })
          ],
        ),
      ),
    );
  }

  changeTab(int tab) {
    _selectedTabController.sink.add(tab);
    closeDrawer();
  }

  _listTile(BuildContext context,
      {@required String text,
      @required String icon,
      @required Function onClick}) {
    return Column(
      children: <Widget>[
        ListTile(
          onTap: () => onClick(),
          leading: Image.asset(
            icon,
            color: Colors.blue,
          ),
          title: Container(
            alignment: Alignment.centerLeft,
            child: ScreenUtils.textViewWithOutClick(context, text,
                color: HexColor(color.light_black_text_color),
                fontWeight: FontWeight.w500,
                fontSize: 15),
          ),
        ),
        Container(
          color: HexColor(color.light_grey_line_color),
          height: 1,
        )
      ],
    );
  }

  tabBarView(String icon, String text,
      {@required Function onClick, bool isSelected: false}) {
    return InkWell(
      onTap: () => onClick(),
      child: Column(
        children: <Widget>[
          Image.asset(icon,
              color: isSelected
                  ? HexColor(color.dark_green)
                  : HexColor(color.dark_grey_text)),
          ScreenUtils.textViewWithOutClick(context, text,
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isSelected ? Colors.white : HexColor(color.dark_grey_text))
        ],
      ),
    );
  }

  closeDrawer() {
    if (_scaffoldKey.currentState.isDrawerOpen) {
      Navigator.pop(context);
    }
  }

  @override
  void onUserDataError(String error) {
    CommonUtils.showToast(
        msg: ApiConstants.serverErrorMsg,
        bgColor: Colors.white,
        textColor: Colors.black);
  }

  @override
  Future onUserDataSuccess(LoginResponse user, BuildContext context) async {
    await SharedPrefHelper()
        .save(SharedPrefConstants.userData, jsonEncode(user.data));

    _drawerController.sink.add(user.data);
    if (user.success) {
      AppConstants.of(_context).set(user.data);
    }
  }

  Future getUserData(BuildContext context) async {
    String json = await SharedPrefHelper()
        .getWithDefault(SharedPrefConstants.userData, UserData().toJson());
    UserData data = UserData.fromJson(jsonDecode(json));
    /*setState(() {
      AppConstants.of(context).set(data);
    });*/
    _drawerController.sink.add(data);
    String token = await SharedPrefHelper()
        .getWithDefault(SharedPrefConstants.token, null);
    String url = ApiConfig.user + AppConstants.of(context).data.id;
    presenter.doGetUserData(url, token, context);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }
}
