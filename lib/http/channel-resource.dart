import 'dart:convert';

import 'package:cryout_app/utils/shared-preference-util.dart';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart';

import 'access-resource.dart';
import 'base-resource.dart';

class ChannelResource {
  static const String _RESOURCE_URL = "/api/v1/channels";

  static Future<Response> createChannel(BuildContext context, Map<String, dynamic> body) async {
    String token = await SharedPreferenceUtil.getToken();
    Map<String, String> headers = Map.from(BaseResource.HEADERS);
    headers["Authorization"] = "Bearer " + token;

    Response response = await post(BaseResource.BASE_URL + _RESOURCE_URL, headers: headers, body: jsonEncode(body));

    if (response.statusCode == 401) {
      if (await AccessResource.refreshToken(context)) {
        return createChannel(context, body);
      }
    }

    return response;
  }

  static Future<Response> getUserCreatedChannels(BuildContext context, String cursor) async {
    String token = await SharedPreferenceUtil.getToken();
    Map<String, String> headers = Map.from(BaseResource.HEADERS);
    headers["Authorization"] = "Bearer " + token;

    Response response = await get(BaseResource.BASE_URL + _RESOURCE_URL + "${cursor == null ? '' : '?cursor=' + cursor}", headers: headers);

    if (response.statusCode == 401) {
      if (await AccessResource.refreshToken(context)) {
        return getUserCreatedChannels(context, cursor);
      }
    }

    print(response.statusCode);
    return response;
  }

  static Future<Response> getUserSubscribedChannels(BuildContext context, String cursor) async {
    String token = await SharedPreferenceUtil.getToken();
    Map<String, String> headers = Map.from(BaseResource.HEADERS);
    headers["Authorization"] = "Bearer " + token;

    Response response = await get(BaseResource.BASE_URL + _RESOURCE_URL + "/subscribed${cursor == null ? '' : '?cursor=' + cursor}", headers: headers);

    if (response.statusCode == 401) {
      if (await AccessResource.refreshToken(context)) {
        return getUserSubscribedChannels(context, cursor);
      }
    }
    return response;
  }

  static Future<Response> searchChannels(BuildContext context, String query) async {
    String token = await SharedPreferenceUtil.getToken();
    Map<String, String> headers = Map.from(BaseResource.HEADERS);
    headers["Authorization"] = "Bearer " + token;

    Response response = await get(BaseResource.BASE_URL + _RESOURCE_URL + "/search?q=$query", headers: headers);

    if (response.statusCode == 401) {
      if (await AccessResource.refreshToken(context)) {
        return searchChannels(context, query);
      }
    }
    return response;
  }

  static Future<Response> getChannel(BuildContext context, int channelId) async {
    String token = await SharedPreferenceUtil.getToken();
    Map<String, String> headers = Map.from(BaseResource.HEADERS);
    headers["Authorization"] = "Bearer " + token;

    Response response = await get(BaseResource.BASE_URL + _RESOURCE_URL + "/$channelId", headers: headers);

    if (response.statusCode == 401) {
      if (await AccessResource.refreshToken(context)) {
        return getChannel(context, channelId);
      }
    }
    return response;
  }

  static Future<Response> subscribeToChannel(BuildContext context, int channelId) async {
    String token = await SharedPreferenceUtil.getToken();
    Map<String, String> headers = Map.from(BaseResource.HEADERS);
    headers["Authorization"] = "Bearer " + token;

    Response response = await get(BaseResource.BASE_URL + _RESOURCE_URL + "/$channelId/subscribe", headers: headers);

    if (response.statusCode == 401) {
      if (await AccessResource.refreshToken(context)) {
        return subscribeToChannel(context, channelId);
      }
    }
    return response;
  }

  static Future<Response> unsubscribeToChannel(BuildContext context, int channelId) async {
    String token = await SharedPreferenceUtil.getToken();
    Map<String, String> headers = Map.from(BaseResource.HEADERS);
    headers["Authorization"] = "Bearer " + token;

    Response response = await get(BaseResource.BASE_URL + _RESOURCE_URL + "/$channelId/unsubscribe", headers: headers);

    if (response.statusCode == 401) {
      if (await AccessResource.refreshToken(context)) {
        return subscribeToChannel(context, channelId);
      }
    }
    return response;
  }

  static Future<Response> getChannelPosts(BuildContext context, int channelId) async {
    String token = await SharedPreferenceUtil.getToken();
    Map<String, String> headers = Map.from(BaseResource.HEADERS);
    headers["Authorization"] = "Bearer " + token;

    Response response = await get(BaseResource.BASE_URL + _RESOURCE_URL + "/$channelId/unsubscribe", headers: headers);

    if (response.statusCode == 401) {
      if (await AccessResource.refreshToken(context)) {
        return getChannelPosts(context, channelId);
      }
    }
    return response;
  }

  static Future<Response> getChannelSubscribers(BuildContext context, int channelId, String cursor, int page, int limit) async {
    String token = await SharedPreferenceUtil.getToken();
    Map<String, String> headers = Map.from(BaseResource.HEADERS);
    headers["Authorization"] = "Bearer " + token;

    Response response = await get(BaseResource.BASE_URL + _RESOURCE_URL + "/$channelId/subscribers?cursor=$cursor&page=$page&limit=$limit", headers: headers);

    if (response.statusCode == 401) {
      if (await AccessResource.refreshToken(context)) {
        return getChannelPosts(context, channelId);
      }
    }
    return response;
  }
  static Future<Response> deleteChannel(BuildContext context, int channelId) async {
    String token = await SharedPreferenceUtil.getToken();
    Map<String, String> headers = Map.from(BaseResource.HEADERS);
    headers["Authorization"] = "Bearer " + token;

    Response response = await delete(BaseResource.BASE_URL + _RESOURCE_URL + "/$channelId", headers: headers);

    if (response.statusCode == 401) {
      if (await AccessResource.refreshToken(context)) {
        return deleteChannel(context, channelId);
      }
    }
    return response;
  }

}
