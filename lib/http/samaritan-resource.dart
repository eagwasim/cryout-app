import 'dart:convert';

import 'package:cryout_app/http/access-resource.dart';
import 'package:cryout_app/http/base-resource.dart';
import 'package:cryout_app/utils/shared-preference-util.dart';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart';

class SamaritanResource {
  static const String _RESOURCE_URL = "/api/v1/samaritan";
  static const String UPDATE_USER_SAMARITAN_MODE = "/mode";
  static const String UPDATE_USER_SAMARITAN_LOCATION = "/location";

  static Future<Response> getUserReceivedDistressSignals(BuildContext context, String cursor) async {
    if (!await BaseResource.isConnected()) {
      return Response("ERROR", 500);
    }

    String token = await SharedPreferenceUtil.getToken();
    Map<String, String> headers = Map.from(BaseResource.HEADERS);
    headers["Authorization"] = "Bearer " + token;

    Response response = await get(BaseResource.BASE_URL + _RESOURCE_URL + "/distress/signals${cursor == null ? '' : '?cursor=' + cursor}", headers: headers);

    if (response.statusCode == 401) {
      if (await AccessResource.refreshToken(context)) {
        return await getUserReceivedDistressSignals(context, cursor);
      }
    }
    return response;
  }

  static Future<Response> getUserReceivedDistressSignal(BuildContext context, String id) async {
    if (!await BaseResource.isConnected()) {
      return Response("ERROR", 500);
    }

    String token = await SharedPreferenceUtil.getToken();
    Map<String, String> headers = Map.from(BaseResource.HEADERS);
    headers["Authorization"] = "Bearer " + token;

    Response response = await get(BaseResource.BASE_URL + _RESOURCE_URL + "/distress/signals/$id", headers: headers);

    if (response.statusCode == 401) {
      if (await AccessResource.refreshToken(context)) {
        return await getUserReceivedDistressSignal(context, id);
      }
    }
    return response;
  }

  static Future<Response> dismissDistressSignals(BuildContext context, String id) async {
    if (!await BaseResource.isConnected()) {
      return Response("ERROR", 500);
    }

    String token = await SharedPreferenceUtil.getToken();
    Map<String, String> headers = Map.from(BaseResource.HEADERS);
    headers["Authorization"] = "Bearer " + token;

    Response response = await delete(BaseResource.BASE_URL + _RESOURCE_URL + "/distress/signals/$id", headers: headers);

    if (response.statusCode == 401) {
      if (await AccessResource.refreshToken(context)) {
        return await dismissDistressSignals(context, id);
      }
    }
    return response;
  }

  static Future<Response> updateSamaritanMode(BuildContext context, Map<String, dynamic> body) async {
    if (!await BaseResource.isConnected()) {
      return Response("ERROR", 500);
    }

    String token = await SharedPreferenceUtil.getToken();

    Map<String, String> headers = Map.from(BaseResource.HEADERS);
    headers["Authorization"] = "Bearer " + token;

    Response response = await post(BaseResource.BASE_URL + _RESOURCE_URL + UPDATE_USER_SAMARITAN_MODE, headers: headers, body: jsonEncode(body));

    if (response.statusCode == 401) {
      if (await AccessResource.refreshToken(context)) {
        return await updateSamaritanMode(context, body);
      }
    }
    return response;
  }

  static Future<Response> updateSamaritanLocation(BuildContext context, Map<String, dynamic> body) async {
    if (!await BaseResource.isConnected()) {
      return Response("ERROR", 500);
    }

    String token = await SharedPreferenceUtil.getToken();

    Map<String, String> headers = Map.from(BaseResource.HEADERS);
    headers["Authorization"] = "Bearer " + token;

    Response response = await post(BaseResource.BASE_URL + _RESOURCE_URL + UPDATE_USER_SAMARITAN_LOCATION, headers: headers, body: jsonEncode(body));

    if (response.statusCode == 401) {
      if (await AccessResource.refreshToken(context)) {
        return await updateSamaritanMode(context, body);
      }
    }
    return response;
  }

  static Future<Response> getUserReceivedSafeWalks(BuildContext context, String cursor) async {
    if (!await BaseResource.isConnected()) {
      return Response("ERROR", 500);
    }

    String token = await SharedPreferenceUtil.getToken();
    Map<String, String> headers = Map.from(BaseResource.HEADERS);
    headers["Authorization"] = "Bearer " + token;

    Response response = await get(BaseResource.BASE_URL + _RESOURCE_URL + "/safe/walks${cursor == null ? '' : '?cursor=' + cursor}", headers: headers);

    if (response.statusCode == 401) {
      if (await AccessResource.refreshToken(context)) {
        return await getUserReceivedSafeWalks(context, cursor);
      }
    }
    return response;
  }

  static Future<Response> getUserReceivedSafeWalk(BuildContext context, String id) async {
    if (!await BaseResource.isConnected()) {
      return Response("ERROR", 500);
    }

    String token = await SharedPreferenceUtil.getToken();
    Map<String, String> headers = Map.from(BaseResource.HEADERS);
    headers["Authorization"] = "Bearer " + token;

    Response response = await get(BaseResource.BASE_URL + _RESOURCE_URL + "/safe/walks/$id", headers: headers);

    if (response.statusCode == 401) {
      if (await AccessResource.refreshToken(context)) {
        return await getUserReceivedSafeWalk(context, id);
      }
    }
    return response;
  }

  static Future<Response> dismissSafeWalk(BuildContext context, String id) async {
    if (!await BaseResource.isConnected()) {
      return Response("ERROR", 500);
    }

    String token = await SharedPreferenceUtil.getToken();
    Map<String, String> headers = Map.from(BaseResource.HEADERS);
    headers["Authorization"] = "Bearer " + token;

    Response response = await delete(BaseResource.BASE_URL + _RESOURCE_URL + "/safe/walks/$id", headers: headers);

    if (response.statusCode == 401) {
      if (await AccessResource.refreshToken(context)) {
        return await dismissDistressSignals(context, id);
      }
    }
    return response;
  }

  static Future<Response> activeSafeWalksCount(BuildContext context) async {
    if (!await BaseResource.isConnected()) {
      return Response("ERROR", 500);
    }

    String token = await SharedPreferenceUtil.getToken();
    Map<String, String> headers = Map.from(BaseResource.HEADERS);
    headers["Authorization"] = "Bearer " + token;

    Response response = await get(BaseResource.BASE_URL + _RESOURCE_URL + "/safe/walks/active/count", headers: headers);

    if (response.statusCode == 401) {
      if (await AccessResource.refreshToken(context)) {
        return await activeSafeWalksCount(context);
      }
    }
    return response;
  }

  static Future<Response> activeDistressCallsCount(BuildContext context) async {
    if (!await BaseResource.isConnected()) {
      return Response("ERROR", 500);
    }

    String token = await SharedPreferenceUtil.getToken();
    Map<String, String> headers = Map.from(BaseResource.HEADERS);
    headers["Authorization"] = "Bearer " + token;

    Response response = await get(BaseResource.BASE_URL + _RESOURCE_URL + "/distress/signals/active/count", headers: headers);

    if (response.statusCode == 401) {
      if (await AccessResource.refreshToken(context)) {
        return await activeSafeWalksCount(context);
      }
    }
    return response;
  }
}
