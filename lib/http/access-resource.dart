import 'dart:convert';

import 'package:cryout_app/http/base-resource.dart';
import 'package:cryout_app/utils/routes.dart';
import 'package:cryout_app/utils/shared-preference-util.dart';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart';


class AccessResource {
  static const String VERIFY_PHONE_NUMBER_URL = "/api/v1/access/phone/verify";
  static const String CONFIRM_PHONE_NUMBER_URL = "/api/v1/access/phone/confirm";

  static Future<Response> phoneNumberVerification(dynamic body) async {
    return await post(BaseResource.BASE_URL + VERIFY_PHONE_NUMBER_URL, headers: BaseResource.HEADERS, body: jsonEncode(body));
  }

  static Future<Response> phoneNumberConfirmation(dynamic body) async {
    return await post(BaseResource.BASE_URL + CONFIRM_PHONE_NUMBER_URL, headers: BaseResource.HEADERS, body: jsonEncode(body));
  }

  static Future<bool> refreshToken(BuildContext buildContext) async {
    String refreshToken = await SharedPreferenceUtil.getRefreshToken();
    Response response = await get(BaseResource.BASE_URL + "/token/refresh?refreshToken=" + refreshToken);

    if (response.statusCode != 200) {
      Navigator.of(buildContext).pushNamedAndRemoveUntil(Routes.PHONE_VERIFICATION_SCREEN, (Route<dynamic> route) => false);
      return false;
    }

    Map<String, dynamic> respPayLoad = jsonDecode(response.body);

    await SharedPreferenceUtil.saveToken(respPayLoad["token"]);
    await SharedPreferenceUtil.saveRefreshToken(respPayLoad["refreshToken"]);

    return true;
  }
}
