// Package imports:
import 'package:get_it/get_it.dart';
import 'package:logger/logger.dart';

// Project imports:
import 'package:dragginator/model/db/appdb.dart';
import 'package:dragginator/model/vault.dart';
import 'package:dragginator/service/app_service.dart';
import 'package:dragginator/service/dragginator_service.dart';
import 'package:dragginator/service/http_service.dart';
import 'package:dragginator/util/biometrics.dart';
import 'package:dragginator/util/hapticutil.dart';
import 'package:dragginator/util/sharedprefsutil.dart';

GetIt sl = GetIt.instance;

void setupServiceLocator() {
  sl.registerLazySingleton<AppService>(() => AppService());
  sl.registerLazySingleton<HttpService>(() => HttpService());
  sl.registerLazySingleton<DragginatorService>(() => DragginatorService());
  sl.registerLazySingleton<DBHelper>(() => DBHelper());
  sl.registerLazySingleton<HapticUtil>(() => HapticUtil());
  sl.registerLazySingleton<BiometricUtil>(() => BiometricUtil());
  sl.registerLazySingleton<Vault>(() => Vault());
  sl.registerLazySingleton<SharedPrefsUtil>(() => SharedPrefsUtil());
  sl.registerLazySingleton<Logger>(() => Logger(printer: PrettyPrinter()));
}
