import 'package:corigge/cache/shared_preferences_helper.dart';
import 'package:corigge/features/login/data/user_model.dart';

class SharedPreferencesHelperWrapper {
  UserModel? get currentUser => SharedPreferencesHelper.currentUser;

  set currentUser(UserModel? user) => SharedPreferencesHelper.currentUser = user;

  Future<void> clearUserData() {
    return SharedPreferencesHelper.clearUserData();
  }

  Future<void> saveOrUpdateUserData(UserModel user) {
    return SharedPreferencesHelper.saveOrUpdateUserData(user);
  }
}
