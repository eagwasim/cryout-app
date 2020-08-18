abstract class Subscriber {
  void notify(String event, {dynamic data});

  String name();

  @override
  bool operator ==(Object other) => identical(this, other) || (other is Subscriber && other.name() == name());

  @override
  int get hashCode => name().hashCode;
}

class Events {
  static const CHANNEL_CREATED = "channel-created";
  static const CHANNEL_SUBSCRIBED = "channel-subscribed";
  static const CHANNEL_UNSUBSCRIBED = "channel-unsubscribed";
  static const CHANNEL_DELETED = "channel-deleted";
  static const CHANNEL_POST_CREATED = "channel-post-created";
}

class EventManager {
  static final Map<String, List<Subscriber>> subscriptions = {};

  static void subscribe(String event, Subscriber s) {
    if (!subscriptions.containsKey(event)) {
      subscriptions[event] = [];
    }

    if (subscriptions[event].contains(s)) {
      subscriptions[event].remove(s);
    }

    subscriptions[event].add(s);
  }

  static void unsubscribe(String event, Subscriber s) {
    if (!subscriptions.containsKey(event)) {
      subscriptions[event] = [];
    }
    if (subscriptions[event].contains(s)) {
      subscriptions[event].remove(s);
    }
  }

  static void notify(String event, {dynamic data}) {
    if (!subscriptions.containsKey(event)) {
      subscriptions[event] = [];
      return;
    }

    var subscribers = subscriptions[event];

    for (int index = 0; index < subscribers.length; index++) {
      Subscriber s = subscribers[index];
      s.notify(event, data: data);
    }
  }
}
