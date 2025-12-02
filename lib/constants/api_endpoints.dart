class ApiEndpoints {
  // UAA Service Base URL
  static const String baseUrl =
      'https://demo.kyta.fpt.com/econdrive/services/uaa';

  // S3 Service Base URL
  static const String s3BaseUrl =
      'https://demo.kyta.fpt.com/econdrive/services/s3service';

  // Authentication
  static const String loginAuth =
      'https://demo.eaccount.kyta.fpt.com/auth/login';
  static const String loginEmail =
      'https://demo.eaccount.kyta.fpt.com/services/uaa/api/p/customer-logins/email';
  static const String authenticate = '/api/authenticate';

  // UAA APIs
  static const String menuSwaps = '/api/menu-swaps';
  static const String menuViews = '/api/owner/menu-views?serviceId=3';
  static const String accountInfo = '/api/account-eaccount';
  static const String userRoleSearch =
      '/api/search/user-info/role?page=0&size=1';

  // S3 Service APIs
  static const String s3Resource = '/api/resource';
  static const String s3Workspaces = '/api/workspaces';
  static const String s3ResourceSize = '/api/resource/size';
  static const String s3ResourceTab = '/api/resource/tab';
  static const String s3ResourceDetails = '/api/resource/details';

  // Helper methods để build URLs với query params
  static String s3ResourceWithPagination(
      {int pageOffset = 1, int pageSize = 20}) {
    return '$s3Resource?pageOffset=$pageOffset&pageSize=$pageSize';
  }

  static String s3ResourceTabWithPagination(
      {int pageOffset = 1, int pageSize = 30}) {
    return '$s3ResourceTab?pageOffset=$pageOffset&pageSize=$pageSize';
  }

  static String s3ResourceDetailsWithId(String resourceId) {
    return '$s3ResourceDetails?resourceID=$resourceId';
  }
}
