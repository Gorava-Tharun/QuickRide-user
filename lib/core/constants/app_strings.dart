/// Centralized strings used across the QuickRide User application.
abstract final class AppStrings {
  // Brand & Splash
  static const String appName = 'QuickRide';
  static const String tagline = 'Your Ride, Your Way';
  static const String appVersion = 'v1.0.0';
  static const String splashSemanticLabel = 'QuickRide splash screen';
  static const String logoSemanticLabel = 'QuickRide brand logo';

  // Login Screen
  static const String welcomeTitle = 'Welcome to QuickRide';
  static const String loginSubtitle = 'Book your ride quickly and safely';
  static const String identifierLabel = 'Mobile Number or Email';
  static const String identifierHint = 'Enter mobile number or email';
  static const String passwordLabel = 'Password';
  static const String passwordHint = 'Enter your password';
  static const String loginButton = 'Login';
  static const String forgotPassword = 'Forgot Password?';
  static const String noAccountPrompt = "Don't have an account? ";
  static const String signUpLink = 'Sign Up';

  // Sign Up Screen
  static const String signUpTitle = 'Create your QuickRide account';
  static const String signUpSubtitle = 'Sign up to start booking rides';
  static const String fullNameLabel = 'Full Name';
  static const String fullNameHint = 'Enter your full name';
  static const String mobileLabel = 'Mobile Number';
  static const String mobileHint = 'Enter 10-digit mobile number';
  static const String emailLabel = 'Email Address';
  static const String emailHint = 'Enter your email address';
  static const String confirmPasswordLabel = 'Confirm Password';
  static const String confirmPasswordHint = 'Re-enter your password';
  static const String createAccountButton = 'Create Account';
  static const String alreadyHaveAccountPrompt = 'Already have an account? ';
  static const String loginLink = 'Login';

  // Validation Messages
  static const String errorIdentifierEmpty = 'Please enter your mobile number or email';
  static const String errorInvalidIdentifier = 'Please enter a valid 10-digit mobile number or email address';
  static const String errorPasswordEmpty = 'Please enter your password';
  static const String errorPasswordTooShort = 'Password must be at least 6 characters long';
  static const String loginSuccessMessage = 'Login successful! Welcome back.';

  static const String errorNameEmpty = 'Please enter your full name';
  static const String errorNameTooShort = 'Name must be at least 2 characters long';
  static const String errorMobileEmpty = 'Please enter your mobile number';
  static const String errorInvalidMobile = 'Please enter a valid 10-digit mobile number';
  static const String errorEmailEmpty = 'Please enter your email address';
  static const String errorInvalidEmail = 'Please enter a valid email address';
  static const String errorConfirmPasswordEmpty = 'Please confirm your password';
  static const String errorPasswordsDoNotMatch = 'Passwords do not match';
  static const String accountCreatedSuccessMessage = 'Account created successfully!';

  // Home Screen & Google Maps (Step 4)
  static const String homeGreeting = 'Hello, User 👋';
  static const String whereToQuestion = 'Where do you want to go?';
  static const String searchBoxPlaceholder = 'Where do you want to go?';
  static const String destinationHint = 'Enter your destination';

  // Location & Map Strings
  static const String pickupLocationHeader = 'Pickup Location';
  static const String currentLocation = 'Current Location';
  static const String tapMapToChangePickup = 'Tap map to change pickup';
  static const String locationPermissionDeniedNotice =
      'Location permission is required to show your current location.';
  static const String openSettings = 'Open Settings';
  static const String locatingYou = 'Locating you...';

  // Vehicles
  static const String chooseRideSection = 'Choose your ride';
  static const String bikeTitle = 'Bike';
  static const String bikeSubtitle = 'Fast & affordable';
  static const String autoTitle = 'Auto';
  static const String autoSubtitle = 'Comfortable';
  static const String carTitle = 'Car';
  static const String carSubtitle = 'More comfort';

  // Confirm Ride & Validations
  static const String confirmRideButton = 'Confirm Ride';
  static const String rideDetailsReady = 'Ride details are ready.';
  static const String errorEnterDestination = 'Please enter your destination.';
  static const String errorSelectPickup = 'Please select a pickup location.';

  // Bottom Navigation
  static const String navHome = 'Home';
  static const String navMyRides = 'My Rides';
  static const String navOffers = 'Offers';
  static const String navProfile = 'Profile';
  static const String comingSoon = 'Coming soon';

  // STEP 5: Pickup & Destination Strings
  static const String pickupLocation = 'Pickup Location';
  static const String selectPickupPrompt = 'Search or select pickup location';
  static const String destinationLocation = 'Destination';
  static const String destinationSearchPrompt = 'Enter your destination';
  static const String searchLocationHint = 'Type a place, city, or landmark...';
  static const String swapLocationsTooltip = 'Swap pickup and destination';
  static const String continueButton = 'Continue';
  static const String tripDetailsTitle = 'Trip Route & Summary';
  static const String distanceLabel = 'Distance';
  static const String estTimeLabel = 'Est. Time';
  static const String popularPlacesHeader = 'Popular & Transit Spots';
  static const String tapToSelectOnMap = 'Tap anywhere on the map to set location';
  static const String setAsPickup = 'Set as Pickup';
  static const String setAsDestination = 'Set as Destination';
  static const String pickupMarkerTitle = 'Pickup Location';
  static const String destinationMarkerTitle = 'Destination';
  static const String errorMissingPickup = 'Please select your pickup location.';
  static const String errorMissingDestination = 'Please select your destination.';
  static const String errorSameLocations = 'Pickup and destination cannot be the same.';
  static const String routeUnavailableNotice =
      'Direct route preview generated. Note: Google Directions API requires active billing & API key.';

  // STEP 6: Vehicle Selection Strings
  static const String chooseRideTitle = 'Choose your ride';
  static const String chooseRideSubtitle = 'Select a vehicle that suits your journey';
  static const String tripSummaryHeader = 'Trip Summary';
  static const String estimatedFareLabel = 'Estimated Fare';
  static const String fareCalculationNext = 'Fare will be calculated next';
  static const String errorSelectVehicle = 'Please select a vehicle.';
  static const String passengerUnitSingle = '1 Passenger';
  static const String passengerUnitTriple = 'Up to 3 Passengers';
  static const String passengerUnitQuad = 'Up to 4 Passengers';

  // STEP 7: Fare Calculation Strings
  static const String fareCalculationTitle = 'Fare Estimate';
  static const String fareBreakdownHeader = 'Fare Breakdown';
  static const String baseFareLabel = 'Base Fare';
  static const String distanceFareLabel = 'Distance Fare';
  static const String timeFareLabel = 'Time Fare';
  static const String waitingChargeLabel = 'Waiting Charge';
  static const String originalFareLabel = 'Original Fare';
  static const String firstRideOfferBadge = 'FIRST RIDE — 50% OFF';
  static const String firstRideDiscountLabel = 'First Ride Discount (50%)';
  static const String finalFareLabel = 'Final Fare';
  static const String changeVehicleButton = 'Change Vehicle';
  static const String rideConfirmedNotice = 'Ride details confirmed!';
  static const String errorInvalidTripData = 'Invalid trip details or fare.';

  // Placeholder Notices
  static const String forgotPasswordNotice = 'Password recovery will be available soon.';
  static const String nextStepNotice = 'Proceeding to Vehicle & Fare Selection (Step 6)...';
  static const String step7PlaceholderNotice = 'Proceeding to Step 7: Fare Calculation & Confirmation...';
  static const String step8PlaceholderNotice = 'Proceeding to Step 8: Captain Matching...';
}
