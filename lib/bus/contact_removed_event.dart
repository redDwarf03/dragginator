import 'package:event_taxi/event_taxi.dart';
import 'package:dragginator/model/db/contact.dart';

class ContactRemovedEvent implements Event {
  final Contact? contact;

  ContactRemovedEvent({this.contact});
}