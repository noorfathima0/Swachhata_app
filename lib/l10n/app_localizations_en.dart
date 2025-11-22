// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Swachhata App';

  @override
  String get ok => 'OK';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get delete => 'Delete';

  @override
  String get edit => 'Edit';

  @override
  String get yes => 'Yes';

  @override
  String get no => 'No';

  @override
  String get back => 'Back';

  @override
  String get submit => 'Submit';

  @override
  String get update => 'Update';

  @override
  String get search => 'Search';

  @override
  String get loading => 'Loading...';

  @override
  String get noData => 'No data available';

  @override
  String get confirmDelete => 'Are you sure you want to delete this?';

  @override
  String get success => 'Success';

  @override
  String get error => 'Error';

  @override
  String get enterName => 'Enter Name';

  @override
  String get enterPhone => 'Enter Phone Number';

  @override
  String get role => 'Role';

  @override
  String get translatingContent => 'Translating content...';

  @override
  String get login => 'Login';

  @override
  String get logout => 'Logout';

  @override
  String get register => 'Register';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get forgotPassword => 'Forgot Password?';

  @override
  String get dontHaveAccount => 'Don\'t have an account?';

  @override
  String get alreadyHaveAccount => 'Already have an account?';

  @override
  String get signUp => 'Sign Up';

  @override
  String get signIn => 'Sign In';

  @override
  String get invalidCredentials => 'Invalid email or password';

  @override
  String get noAccount => 'Don\'t have an account? Sign Up';

  @override
  String get dashboard => 'Dashboard';

  @override
  String get welcome => 'Welcome';

  @override
  String get userDashboard => 'User Dashboard';

  @override
  String get adminDashboard => 'Admin Dashboard';

  @override
  String get complaints => 'Complaints';

  @override
  String get myComplaints => 'My Complaints';

  @override
  String get complaintDetails => 'Complaint Details';

  @override
  String get addComplaint => 'Add Complaint';

  @override
  String get complaintTitle => 'Complaint Title';

  @override
  String get complaintDescription => 'Complaint Description';

  @override
  String get complaintStatus => 'Status';

  @override
  String get complaintPending => 'Pending';

  @override
  String get complaintResolved => 'Resolved';

  @override
  String get complaintRejected => 'Rejected';

  @override
  String get noComplaints => 'No complaints found';

  @override
  String get viewComplaint => 'View Complaint';

  @override
  String get activities => 'Activities';

  @override
  String get addActivity => 'Add Activity';

  @override
  String get activityDetails => 'Activity Details';

  @override
  String get activityTitle => 'Activity Title';

  @override
  String get activityDescription => 'Activity Description';

  @override
  String get activityLocation => 'Activity Location';

  @override
  String get activityDate => 'Activity Date';

  @override
  String get approve => 'Approve';

  @override
  String get reject => 'Reject';

  @override
  String get pendingApproval => 'Pending Approval';

  @override
  String get approved => 'Approved';

  @override
  String get rejected => 'Rejected';

  @override
  String get events => 'Events';

  @override
  String get eventDetails => 'Event Details';

  @override
  String get addEvent => 'Add Event';

  @override
  String get editEvent => 'Edit Event';

  @override
  String get deleteEvent => 'Delete Event';

  @override
  String get eventTitle => 'Event Title';

  @override
  String get eventDescription => 'Event Description';

  @override
  String get eventDate => 'Event Date';

  @override
  String get eventTime => 'Event Time';

  @override
  String get eventLocation => 'Location';

  @override
  String get upcomingEvents => 'Upcoming Events';

  @override
  String get pastEvents => 'Past Events';

  @override
  String get noEvents => 'No events found';

  @override
  String get interested => 'Interested';

  @override
  String get imInterested => 'I\'m Interested';

  @override
  String interestedCount(Object count) {
    return '$count interested';
  }

  @override
  String get eventCreated => 'Event created successfully';

  @override
  String get eventUpdated => 'Event updated successfully';

  @override
  String get eventDeleted => 'Event deleted successfully';

  @override
  String get profile => 'Profile';

  @override
  String get editProfile => 'Edit Profile';

  @override
  String get name => 'Name';

  @override
  String get phone => 'Phone';

  @override
  String get changeLanguage => 'Change Language';

  @override
  String get selectLanguage => 'Select Language';

  @override
  String get english => 'English';

  @override
  String get kannada => 'Kannada';

  @override
  String get profileUpdated => 'Profile updated successfully';

  @override
  String get userManagement => 'User Management';

  @override
  String get users => 'Users';

  @override
  String get userDetails => 'User Details';

  @override
  String get makeAdmin => 'Make Admin';

  @override
  String get removeAdmin => 'Remove Admin';

  @override
  String get blockUser => 'Block User';

  @override
  String get unblockUser => 'Unblock User';

  @override
  String get filterBy => 'Filter By';

  @override
  String get allUsers => 'All Users';

  @override
  String get admins => 'Admins';

  @override
  String get blockedUsers => 'Blocked Users';

  @override
  String get regularUsers => 'Regular Users';

  @override
  String get viewProfile => 'View Profile';

  @override
  String get forum => 'Community Forum';

  @override
  String get posts => 'Posts';

  @override
  String get addPost => 'Add Post';

  @override
  String get like => 'Like';

  @override
  String get unlike => 'Unlike';

  @override
  String get comment => 'Comment';

  @override
  String get noPosts => 'No posts yet';

  @override
  String get postCreated => 'Post created successfully';

  @override
  String get postDeleted => 'Post deleted successfully';

  @override
  String get uploadError => 'Failed to upload image. Try again.';

  @override
  String get networkError => 'Network error. Please check your connection.';

  @override
  String get somethingWentWrong =>
      'Something went wrong. Please try again later.';

  @override
  String get myProfile => 'My Profile';

  @override
  String get address => 'Address';

  @override
  String get bio => 'Bio';

  @override
  String get joinedOn => 'Joined on';

  @override
  String get notProvided => 'Not provided';

  @override
  String get noBio => 'No bio added';

  @override
  String get language => 'Language';

  @override
  String get languageChangedEnglish => 'Language changed to English';

  @override
  String get languageChangedKannada => 'Language changed to Kannada';

  @override
  String get unnamedUser => 'Unnamed User';

  @override
  String get complaintType => 'Complaint Type';

  @override
  String get complaintTypeGarbage => 'Garbage';

  @override
  String get complaintTypeDrainage => 'Drainage';

  @override
  String get complaintTypeStreetlight => 'Streetlight';

  @override
  String get complaintTypeRoadDamage => 'Road Damage';

  @override
  String get complaintTypeOther => 'Other';

  @override
  String get enterDescription => 'Enter description';

  @override
  String get enterAddress => 'Enter address';

  @override
  String get addPhoto => 'Add Photo Evidence';

  @override
  String get camera => 'Camera';

  @override
  String get gallery => 'Gallery';

  @override
  String get selectLocation => 'Select Location';

  @override
  String get useCurrentLocation => 'Use Current Location';

  @override
  String get failedToLoadImage => 'Failed to load image';

  @override
  String get imageNotAvailable => 'Image not available';

  @override
  String get submittedOn => 'Submitted on';

  @override
  String get description => 'Description';

  @override
  String get addressLabel => 'Address';

  @override
  String get addressNotAvailable => 'Address not available';

  @override
  String get locationOnMap => 'Location on Map';

  @override
  String get noDescription => 'No description available';

  @override
  String get unknown => 'Unknown';

  @override
  String get unknownDate => 'Unknown date';

  @override
  String get complaintInProgress => 'In Progress';

  @override
  String get beFirstToShare => 'Be the first to share something!';

  @override
  String get user => 'User';

  @override
  String get postDetails => 'Post Details';

  @override
  String get likes => 'likes';

  @override
  String get comments => 'Comments';

  @override
  String get noCommentsYet => 'No comments yet.';

  @override
  String get addCommentPlaceholder => 'Add a comment...';

  @override
  String get anonymous => 'Anonymous';

  @override
  String get submitActivity => 'Submit Activity';

  @override
  String get enterActivityTitle => 'Enter activity title...';

  @override
  String get enterTitleValidation => 'Please enter a title';

  @override
  String get describeActivity => 'Describe your activity...';

  @override
  String get enterDescriptionValidation => 'Please enter a description';

  @override
  String get location => 'Location';

  @override
  String get selectLocationOnMapHint => 'Select location on map...';

  @override
  String get orTapMap => 'or tap anywhere on the map below';

  @override
  String get selectLocationOnMapTitle => 'Select Location on Map';

  @override
  String get unknownLocation => 'Unknown location';

  @override
  String get failedToGetLocation => 'Failed to get location';

  @override
  String get uploadImages => 'Upload Images';

  @override
  String get upToFiveImages => 'Up to 5 images allowed';

  @override
  String get maxFiveImages => 'You can upload up to 5 images only.';

  @override
  String get selectImages => 'Select Images';

  @override
  String get activitySubmitted => 'Activity submitted successfully!';

  @override
  String get imageUploadFailed => 'Image upload failed';

  @override
  String get selectLocationOnMap => 'Please select a location on the map.';

  @override
  String get submitting => 'Submitting...';

  @override
  String get loginToViewActivities => 'Please log in to view your activities.';

  @override
  String get myActivities => 'My Activities';

  @override
  String get noActivitiesFound => 'No activities found.';

  @override
  String get untitledActivity => 'Untitled Activity';

  @override
  String get statusApproved => 'Approved';

  @override
  String get statusRejected => 'Rejected';

  @override
  String get statusResolved => 'Resolved';

  @override
  String get statusInProgress => 'In-Progress';

  @override
  String get statusPending => 'Pending';
}
