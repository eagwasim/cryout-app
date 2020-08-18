import 'dart:convert';

import 'package:cryout_app/http/access-resource.dart';
import 'package:cryout_app/http/base-resource.dart';
import 'package:cryout_app/utils/shared-preference-util.dart';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart';

class UserResource {
  static const String UPDATE_USER_PROFILE = "/api/v1/users";
  static const String REPORT_USER = "/report";

  static Future<Response> updateUser(BuildContext context, Map<String, dynamic> body) async {
    String token = await SharedPreferenceUtil.getToken();

    Map<String, String> headers = Map.from(BaseResource.HEADERS);
    headers["Authorization"] = "Bearer " + token;

    Response response = await put(BaseResource.BASE_URL + UPDATE_USER_PROFILE, headers: headers, body: jsonEncode(body));

    if (response.statusCode == 401) {
      if (await AccessResource.refreshToken(context)) {
        return await updateUser(context, body);
      }
    }
    return response;
  }

  static Future<Response> reportUser(BuildContext context, Map<String, dynamic> body) async {
    String token = await SharedPreferenceUtil.getToken();

    Map<String, String> headers = Map.from(BaseResource.HEADERS);
    headers["Authorization"] = "Bearer " + token;

    Response response = await post(BaseResource.BASE_URL + UPDATE_USER_PROFILE + REPORT_USER, headers: headers, body: jsonEncode(body));

    if (response.statusCode == 401) {
      if (await AccessResource.refreshToken(context)) {
        return await reportUser(context, body);
      }
    }
    return response;
  }

  static Future<Response> checkPhoneNumber(BuildContext context, String phoneNumber) async {
    String token = await SharedPreferenceUtil.getToken();

    Map<String, String> headers = Map.from(BaseResource.HEADERS);
    headers["Authorization"] = "Bearer " + token;

    Response response = await get(BaseResource.BASE_URL + UPDATE_USER_PROFILE + "/check/phone-number/" + phoneNumber, headers: headers);

    if (response.statusCode == 401) {
      if (await AccessResource.refreshToken(context)) {
        return await checkPhoneNumber(context, phoneNumber);
      }
    }

    return response;
  }

}
