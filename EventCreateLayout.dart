import 'dart:convert';
import 'package:flushbar/flushbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_chips_input/flutter_chips_input.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_imf/apis/ApiConfig.dart';
import 'package:flutter_imf/modals/request/AddEventRequest.dart';
import 'package:flutter_imf/modals/response/AddEventResponse.dart';
import 'package:flutter_imf/modals/response/GetAllDataOfCalender.dart';
import 'package:flutter_imf/modals/response/LoginResponse.dart';
import 'package:flutter_imf/modals/response/LogoutResponse.dart';
import 'package:flutter_imf/mvp/CalenderContract.dart';
import 'package:flutter_imf/utils/Constants.dart';
import 'package:flutter_imf/utils/InternalConstants.dart';
import 'package:flutter_imf/utils/ScreenUtils.dart';
import 'package:flutter_imf/utils/app_defaults.dart';
import 'package:flutter_imf/utils/app_utils.dart';
import 'package:flutter_imf/utils/color.dart';
import 'package:google_places_picker/google_places_picker.dart';
import 'package:intl/intl.dart';

class EventCreateLayout extends StatefulWidget {
  final AddEventRequest data;
  final bool isEdit;

  EventCreateLayout({this.data, this.isEdit: false});

  @override
  State<StatefulWidget> createState() =>
      EventCreateState(this.data, this.isEdit);
}

class EventCreateState extends State<EventCreateLayout> with CalenderContract {
  final GlobalKey<FormBuilderState> _fbKey = GlobalKey<FormBuilderState>();
  bool _autoValidate = false;

  final AddEventRequest data;
  final bool isEdit;

  TextEditingController startDateController = TextEditingController();
  TextEditingController endDateController = TextEditingController();

  TextEditingController startTimeController = TextEditingController();
  TextEditingController endTimeController = TextEditingController();

  String title = "Add Event";
  String editTitle = "Edit Event";

  CalenderPresenter presenter;

  EventCreateState(this.data, this.isEdit);

  @override
  void initState() {
    PluginGooglePlacePicker.initialize(
      androidApiKey: "AIzaSyDv7BRWslfhqpUXAc5brYXtITXjWZqFxQE",
      iosApiKey: "AIzaSyDv7BRWslfhqpUXAc5brYXtITXjWZqFxQE",
    );

    presenter = CalenderPresenter(this);

    if (data != null) {
      nameController.text = data.name;
      descriptionController.text = data.descriptions;
      participantsController.text = data.participants;
      locationController.text = data.location;
      startDateController.text = data.startDate;
      endDateController.text = data.endDate;
      startTimeController.text = data.startTime;
      endTimeController.text = data.endTime;
    }

    super.initState();
  }

  TextEditingController nameController = new TextEditingController();
  TextEditingController descriptionController = new TextEditingController();
  TextEditingController participantsController = new TextEditingController();
  TextEditingController locationController = new TextEditingController();

  @override
  Widget build(BuildContext context) {
    return MediaQuery.removePadding(
      context: context,
      removeBottom: true,
      child: WillPopScope(
        onWillPop: () async {
          Navigator.pop(context, "Update");
          return false;
        },
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: Container(
            alignment: Alignment.bottomCenter,
            decoration:
                BoxDecoration(color: HexColor(color.fourty_transparent)),
            padding: EdgeInsets.only(top: 80),
            child: Stack(
              alignment: Alignment.topCenter,
              overflow: Overflow.visible,
              children: <Widget>[
                SingleChildScrollView(
                  child: Container(
                      width: MediaQuery.of(context).size.width,
                      alignment: Alignment.bottomCenter,
                      padding: EdgeInsets.only(
                          top: 30, bottom: 10, right: 10, left: 10),
                      decoration: BoxDecoration(
                        image: DecorationImage(
                            image: AssetImage("assets/bg_curve.png"),
                            fit: BoxFit.fill),
                      ),
                      child: Column(
                        children: <Widget>[
                          ScreenUtils.textViewWithOutClick(
                              context, isEdit ? editTitle : title,
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                              color: HexColor(color.light_green)),
                          FormBuilder(
                              autovalidate: _autoValidate,
                              key: _fbKey,
                              child: getInputFields(context)),
                          Padding(
                            padding: const EdgeInsets.only(
                                top: 25.0, bottom: 25.0, right: 40, left: 40),
                            child: ButtonTheme(
                              padding: EdgeInsets.all(10),
                              minWidth: MediaQuery.of(context).size.width,
                              child: FlatButton(
                                  onPressed: () {
                                    CommonUtils.isNetworkAvailable()
                                        .then((bool connected) async {
                                      if (connected) {
                                        if (_validateInput()) {
                                          String data = await SharedPrefHelper()
                                              .getWithDefault(
                                                  SharedPrefConstants.userData,
                                                  jsonEncode(UserData()));

                                          UserData userData = UserData.fromJson(
                                              jsonDecode(data));

                                          AddEventRequest req = AddEventRequest(
                                              name: nameController.text,
                                              descriptions:
                                                  descriptionController.text,
                                              endDate: endDateController.text,
                                              endTime: endTimeController.text,
                                              startDate:
                                                  startDateController.text,
                                              startTime:
                                                  startTimeController.text,
                                              userId: userData.id,
                                              location:
                                                  locationController.text);

                                          CommonUtils.fullScreenProgress(
                                              context: context);
                                          if (isEdit) {
                                            presenter.doEditEvent(
                                                jsonEncode(req), this.data.id);
                                          } else {
                                            presenter
                                                .doAddEvent(jsonEncode(req));
                                          }
                                        }
                                      } else {
                                        CommonUtils.showFlushBarMessage(
                                            title: "Info",
                                            msg: AppConstants.of(context)
                                                .internetNotConnected,
                                            bgColor: Colors.red,
                                            textColor: Colors.white,
                                            position: FlushbarPosition.TOP,
                                            context: context);
                                      }
                                    });
                                  },
                                  color: HexColor(color.light_green),
                                  child: Text(
                                    AppConstants.of(context).save,
                                    style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.white,
                                        fontFamily:
                                            AppConstants.of(context).fontFamily,
                                        fontWeight: FontWeight.w600),
                                  )),
                            ),
                          ),
                        ],
                      )),
                ),
                Positioned(
                    top: -30,
                    child: new IconButton(
                      iconSize: 50,
                      icon: new Image.asset('assets/cross_ico.png'),
                      tooltip: 'Closes Screen',
                      onPressed: () => Navigator.pop(context, "Update"),
                    )),
              ],
            ),
          ),
        ),
      ),
    );
  }

  getInputFields(BuildContext context) {
    return Column(children: <Widget>[
      FormBuilderTextField(
          controller: nameController,
          keyboardType: TextInputType.text,
          attribute: "name",
          validators: [FormBuilderValidators.required()],
          style: ScreenUtils.inputFieldCustomTextStyle(
              context, HexColor(color.light_black_text_color)),
          decoration: ScreenUtils.inputFieldCustomDecoration(context, "Name",
              HexColor(color.light_black_text_color), Colors.red)),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.max,
        children: <Widget>[
          getDateFormBuilder(
              title: "Start Date",
              controller: startDateController,
              edgePadding: EdgeInsets.only(right: 15)),
          getDateFormBuilder(
              title: "End Date",
              controller: endDateController,
              edgePadding: EdgeInsets.only(left: 15))
        ],
      ),
      Padding(
        padding: const EdgeInsets.only(top: 10.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.max,
          children: <Widget>[
            getTimeFormBuilder(
                title: "Start Time",
                controller: startTimeController,
                edgePadding: EdgeInsets.only(right: 15)),
            getTimeFormBuilder(
                title: "End Time",
                controller: endTimeController,
                edgePadding: EdgeInsets.only(left: 15))
          ],
        ),
      ),
      InkWell(
        onTap: () async {
          Place place = await _showAutocomplete();
          locationController.text = place.address;
        },
        child: FormBuilderTextField(
          controller: locationController,
          keyboardType: TextInputType.text,
          attribute: "location",
          readOnly: true,
          validators: [FormBuilderValidators.required()],
          style: ScreenUtils.inputFieldCustomTextStyle(
              context, HexColor(color.light_black_text_color)),
          decoration: ScreenUtils.inputFieldCustomDecoration(context,
              "Location", HexColor(color.light_black_text_color), Colors.red),
        ),
      ),
      FormBuilderTextField(
        controller: descriptionController,
        keyboardType: TextInputType.text,
        attribute: "description",
        validators: [FormBuilderValidators.required()],
        style: ScreenUtils.inputFieldCustomTextStyle(
            context, HexColor(color.light_black_text_color)),
        decoration: ScreenUtils.inputFieldCustomDecoration(context,
            "Description", HexColor(color.light_black_text_color), Colors.red),
      ),
      FormBuilderTextField(
        controller: participantsController,
        keyboardType: TextInputType.text,
        attribute: "participants",
        style: ScreenUtils.inputFieldCustomTextStyle(
            context, HexColor(color.light_black_text_color)),
        decoration: ScreenUtils.inputFieldCustomDecoration(context,
            "Participants", HexColor(color.light_black_text_color), Colors.red),
      ),
    ]);
  }

  bool _validateInput() {
    if (_fbKey.currentState.validate()) {
      // If all data are correct then save data to out variables
      _fbKey.currentState.save();
      return true;
    } else {
      // If all data are not valid then start auto validation.
      setState(() {
        _autoValidate = true;
      });
      return false;
    }
  }

  getDateFormBuilder(
      {String title,
      String attribute,
      TextEditingController controller,
      EdgeInsets edgePadding}) {
    return Expanded(
      child: Container(
        padding: edgePadding,
        child: InkWell(
          onTap: () async {
            DateTime date = await CommonUtils.setCalender(context);
            var formatter = new DateFormat('d MMM y');
            String formatted = formatter.format(date);
            controller.text = formatted;
          },
          child: FormBuilderTextField(
            keyboardType: TextInputType.text,
            controller: controller,
            attribute: attribute,
            readOnly: true,
            validators: [FormBuilderValidators.required()],
            style: ScreenUtils.inputFieldCustomTextStyle(
                context, HexColor(color.light_black_text_color)),
            decoration: ScreenUtils.inputFieldCustomDecoration(context, title,
                HexColor(color.light_black_text_color), Colors.red,
                suffixImage: "assets/expense_calendar_icon.png"),
          ),
        ),
      ),
    );
  }

  getTimeFormBuilder(
      {String title,
      String attribute,
      TextEditingController controller,
      EdgeInsets edgePadding}) {
    return Expanded(
      child: Container(
        padding: edgePadding,
        child: InkWell(
          onTap: () async {
            String time = await CommonUtils.getTime(context);
            controller.text = time;
          },
          child: FormBuilderTextField(
            keyboardType: TextInputType.text,
            controller: controller,
            attribute: attribute,
            readOnly: true,
            validators: [FormBuilderValidators.required()],
            style: ScreenUtils.inputFieldCustomTextStyle(
                context, HexColor(color.light_black_text_color)),
            decoration: ScreenUtils.inputFieldCustomDecoration(context, title,
                HexColor(color.light_black_text_color), Colors.red,
                suffixImage: "assets/clock_icon.png"),
          ),
        ),
      ),
    );
  }

  _showAutocomplete() async {
    var locationBias = LocationBias()
      ..northEastLat = 20.0
      ..northEastLng = 20.0
      ..southWestLat = 0.0
      ..southWestLng = 0.0;

    var locationRestriction = LocationRestriction()
      ..northEastLat = 20.0
      ..northEastLng = 20.0
      ..southWestLng = 0.0
      ..southWestLat = 0.0;

    var country = "US";

    // Platform messages may fail, so we use a try/catch PlatformException.
    var place = await PluginGooglePlacePicker.showAutocomplete(
        mode: PlaceAutocompleteMode.MODE_FULLSCREEN,
        typeFilter: TypeFilter.ESTABLISHMENT);

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    return place;
  }

  @override
  void onAddEventSuccess(res) {
    CommonUtils.dismissProgressDialog(context);

    if (res.success) {
      CommonUtils.showToast(
          msg: res.message, bgColor: Colors.white, textColor: Colors.black);
      Navigator.pop(context, "Update");
    } else {
      CommonUtils.showFlushBarMessage(
          title: "Info",
          msg: AppConstants.of(context).internetNotConnected,
          bgColor: Colors.white,
          textColor: Colors.black,
          position: FlushbarPosition.TOP,
          context: context);
    }
  }

  @override
  void onCalenderError(String error) {
    CommonUtils.dismissProgressDialog(context);
    CommonUtils.showToast(
        msg: ApiConstants.serverErrorMsg,
        bgColor: Colors.white,
        textColor: Colors.black);
  }

  @override
  void onDeleteEventSuccess(LogoutResponse res) {
    // TODO: implement onDeleteEventSuccess
  }

  @override
  void onGetAllCalenderData(GetAllDataOfCalender dataOfCalender) {
    // TODO: implement onGetAllCalenderData
  }

  @override
  void onEditEventSuccess(AddEventResponse res) {
    CommonUtils.dismissProgressDialog(context);
    if (res.success) {
      CommonUtils.showToast(
          msg: res.message, bgColor: Colors.white, textColor: Colors.black);
      Navigator.pop(context, jsonEncode(res.data));
    } else {
      CommonUtils.showFlushBarMessage(
          title: "Info",
          msg: res.message,
          bgColor: Colors.white,
          textColor: Colors.black,
          position: FlushbarPosition.TOP,
          context: context);
    }
  }
}
