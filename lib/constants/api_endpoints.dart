class ApiEndpoints {
  static const String baseUrl =
      'https://demo.kyta.fpt.com/econdrive/services/uaa';

  static const String loginAuth =
      'https://demo.eaccount.kyta.fpt.com/auth/login';
  static const String loginEmail =
      'https://demo.eaccount.kyta.fpt.com/services/uaa/api/p/customer-logins/email';
  static const String authenticate = '/api/authenticate';

  static const String menuSwaps = '/api/menu-swaps';
  static const String menuViews = '/api/owner/menu-views?serviceId=3';
  static const String accountInfo = '/api/account-eaccount';
  static const String userRoleSearch =
      '/api/search/user-info/role?page=0&size=1';
}
