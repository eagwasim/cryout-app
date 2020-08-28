import 'dart:convert';

import 'package:cryout_app/http/access-resource.dart';
import 'package:cryout_app/http/base-resource.dart';
import 'package:cryout_app/utils/shared-preference-util.dart';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart';

class SafeWalkResource {
  static const String _SAFE_WALK_BASE_ENDPOINT = "/api/v1/safe/walk";

  static Future<Response> sendSafeWalk(BuildContext context, Map<String, dynamic> body) async {
    if (!await BaseResource.isConnected()) {
      return Response("ERROR", 500);
    }

    String token = await SharedPreferenceUtil.getToken();

    Map<String, String> headers = Map.from(BaseResource.HEADERS);
    headers["Authorization"] = "Bearer " + token;

    Response response = await post(BaseResource.BASE_URL + _SAFE_WALK_BASE_ENDPOINT, headers: headers, body: jsonEncode(body));

    if (response.statusCode == 401) {
      if (await AccessResource.refreshToken(context)) {
        return await sendSafeWalk(context, body);
      }
    }
    return response;
  }

  static Future<Response> closeSafeWalk(BuildContext context, int id) async {
    if (!await BaseResource.isConnected()) {
      return Response("ERROR", 500);
    }

    String token = await SharedPreferenceUtil.getToken();

    Map<String, String> headers = Map.from(BaseResource.HEADERS);
    headers["Authorization"] = "Bearer " + token;

    Response response = await post(BaseResource.BASE_URL + _SAFE_WALK_BASE_ENDPOINT + "/$id" + "/close", headers: headers, body: jsonEncode({}));

    if (response.statusCode == 401) {
      if (await AccessResource.refreshToken(context)) {
        return await closeSafeWalk(context, id);
      }
    }
    return response;
  }

  static Future<Response> updateSafeWalkSignalResponseStatus(BuildContext context, String id, dynamic data) async {
    if (!await BaseResource.isConnected()) {
      return Response("ERROR", 500);
    }

    String token = await SharedPreferenceUtil.getToken();

    Map<String, String> headers = Map.from(BaseResource.HEADERS);
    headers["Authorization"] = "Bearer " + token;
    Response response = await put(BaseResource.BASE_URL + _SAFE_WALK_BASE_ENDPOINT + "/$id" + "/response/status", headers: headers, body: jsonEncode(data));

    if (response.statusCode == 401) {
      if (await AccessResource.refreshToken(context)) {
        return await updateSafeWalkSignalResponseStatus(context, id, data);
      }
    }
    return response;
  }

  static Future<Response> notifySafeWalkChannelOfMessage(BuildContext context, String id, dynamic data) async {
    if (!await BaseResource.isConnected()) {
      return Response("ERROR", 500);
    }

    String token = await SharedPreferenceUtil.getToken();
    Map<String, String> headers = Map.from(BaseResource.HEADERS);
    headers["Authorization"] = "Bearer " + token;
    Response response = await post(BaseResource.BASE_URL + _SAFE_WALK_BASE_ENDPOINT + "/$id" + "/messages/notify", headers: headers, body: jsonEncode(data));

    if (response.statusCode == 401) {
      if (await AccessResource.refreshToken(context)) {
        return await updateSafeWalkSignalResponseStatus(context, id, data);
      }
    }
    return response;
  }
}
