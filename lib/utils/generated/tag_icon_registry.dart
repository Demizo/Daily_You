// GENERATED CODE - DO NOT MODIFY
//
// Generated from lib/utils/tag_icons.yaml by tool/generate_tag_icons.dart.
// Run `dart run tool/generate_tag_icons.dart` to regenerate after editing
// the yaml source.

import 'package:daily_you/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';

/// Identifies a curated icon group
enum TagIconGroupId {
  moodPeople,
  activities,
  health,
  workFinance,
  habitsGoals,
  nature,
  foodDrink,
  home,
  hobbies,
  travel,
  symbols,
}

/// A group of icons shown together in the icon picker grid
class TagIconGroup {
  final TagIconGroupId id;
  final List<String> keys;

  const TagIconGroup({required this.id, required this.keys});
}

/// Resolves a group's display label through [AppLocalizations].
String tagIconGroupLabel(AppLocalizations l10n, TagIconGroupId id) =>
    switch (id) {
      TagIconGroupId.moodPeople => l10n.iconGroupMoodPeople,
      TagIconGroupId.activities => l10n.tagCategoryActivitiesName,
      TagIconGroupId.health => l10n.iconGroupHealth,
      TagIconGroupId.workFinance => l10n.iconGroupWorkFinance,
      TagIconGroupId.habitsGoals => l10n.iconGroupHabitsGoals,
      TagIconGroupId.nature => l10n.iconGroupNature,
      TagIconGroupId.foodDrink => l10n.iconGroupFoodDrink,
      TagIconGroupId.home => l10n.pageHomeTitle,
      TagIconGroupId.hobbies => l10n.tagEntertainmentName,
      TagIconGroupId.travel => l10n.iconGroupTravel,
      TagIconGroupId.symbols => l10n.iconGroupSymbols,
    };

/// Constants for the string keys in [tagIconRegistry]
class TagIconKey {
  TagIconKey._();

  static const String mood = 'mood';
  static const String sentimentVerySatisfied = 'sentiment_very_satisfied';
  static const String sentimentSatisfied = 'sentiment_satisfied';
  static const String sentimentNeutral = 'sentiment_neutral';
  static const String sentimentDissatisfied = 'sentiment_dissatisfied';
  static const String moodBad = 'mood_bad';
  static const String sentimentVeryDissatisfied = 'sentiment_very_dissatisfied';
  static const String person = 'person';
  static const String accountCircle = 'account_circle';
  static const String groups = 'groups';
  static const String familyRestroom = 'family_restroom';
  static const String diversity3 = 'diversity_3';
  static const String pregnantWoman = 'pregnant_woman';
  static const String childFriendly = 'child_friendly';
  static const String childCare = 'child_care';
  static const String elderly = 'elderly';
  static const String pets = 'pets';
  static const String handshake = 'handshake';
  static const String directionsRun = 'directions_run';
  static const String directionsWalk = 'directions_walk';
  static const String hiking = 'hiking';
  static const String directionsBike = 'directions_bike';
  static const String fitnessCenter = 'fitness_center';
  static const String sportsEsports = 'sports_esports';
  static const String phishing = 'phishing';
  static const String sportsSoccer = 'sports_soccer';
  static const String sportsBasketball = 'sports_basketball';
  static const String sportsTennis = 'sports_tennis';
  static const String sportsVolleyball = 'sports_volleyball';
  static const String sportsFootball = 'sports_football';
  static const String sportsRugby = 'sports_rugby';
  static const String sportsHockey = 'sports_hockey';
  static const String sportsMartialArts = 'sports_martial_arts';
  static const String pool = 'pool';
  static const String selfImprovement = 'self_improvement';
  static const String golfCourse = 'golf_course';
  static const String rowing = 'rowing';
  static const String sailing = 'sailing';
  static const String kayaking = 'kayaking';
  static const String surfing = 'surfing';
  static const String skateboarding = 'skateboarding';
  static const String snowboarding = 'snowboarding';
  static const String downhillSkiing = 'downhill_skiing';
  static const String sledding = 'sledding';
  static const String nordicWalking = 'nordic_walking';
  static const String scubaDiving = 'scuba_diving';
  static const String snowshoeing = 'snowshoeing';
  static const String rollerSkating = 'roller_skating';
  static const String favorite = 'favorite';
  static const String localHospital = 'local_hospital';
  static const String medication = 'medication';
  static const String medicationLiquid = 'medication_liquid';
  static const String monitorHeart = 'monitor_heart';
  static const String monitorWeight = 'monitor_weight';
  static const String bloodtype = 'bloodtype';
  static const String vaccines = 'vaccines';
  static const String bedtime = 'bedtime';
  static const String spa = 'spa';
  static const String bathtub = 'bathtub';
  static const String soap = 'soap';
  static const String shower = 'shower';
  static const String waterDrop = 'water_drop';
  static const String smokingRooms = 'smoking_rooms';
  static const String smokeFree = 'smoke_free';
  static const String localBar = 'local_bar';
  static const String noDrinks = 'no_drinks';
  static const String psychology = 'psychology';
  static const String healing = 'healing';
  static const String masks = 'masks';
  static const String deviceThermostat = 'device_thermostat';
  static const String coronavirus = 'coronavirus';
  static const String work = 'work';
  static const String businessCenter = 'business_center';
  static const String meetingRoom = 'meeting_room';
  static const String school = 'school';
  static const String menuBook = 'menu_book';
  static const String editNote = 'edit_note';
  static const String assignment = 'assignment';
  static const String assignmentTurnedIn = 'assignment_turned_in';
  static const String checklist = 'checklist';
  static const String laptopMac = 'laptop_mac';
  static const String attachMoney = 'attach_money';
  static const String trendingUp = 'trending_up';
  static const String savings = 'savings';
  static const String creditCard = 'credit_card';
  static const String paid = 'paid';
  static const String shoppingCart = 'shopping_cart';
  static const String shoppingBag = 'shopping_bag';
  static const String receiptLong = 'receipt_long';
  static const String accountBalance = 'account_balance';
  static const String taskAlt = 'task_alt';
  static const String checkCircle = 'check_circle';
  static const String verified = 'verified';
  static const String celebration = 'celebration';
  static const String emojiEvents = 'emoji_events';
  static const String rocketLaunch = 'rocket_launch';
  static const String repeat = 'repeat';
  static const String localFireDepartment = 'local_fire_department';
  static const String whatshot = 'whatshot';
  static const String militaryTech = 'military_tech';
  static const String block = 'block';
  static const String schedule = 'schedule';
  static const String alarm = 'alarm';
  static const String hourglassBottom = 'hourglass_bottom';
  static const String timeline = 'timeline';
  static const String wbSunny = 'wb_sunny';
  static const String cloud = 'cloud';
  static const String water = 'water';
  static const String waves = 'waves';
  static const String umbrella = 'umbrella';
  static const String acUnit = 'ac_unit';
  static const String cyclone = 'cyclone';
  static const String air = 'air';
  static const String park = 'park';
  static const String forest = 'forest';
  static const String grass = 'grass';
  static const String landscape = 'landscape';
  static const String localFlorist = 'local_florist';
  static const String eco = 'eco';
  static const String terrain = 'terrain';
  static const String nightlight = 'nightlight';
  static const String wbTwilight = 'wb_twilight';
  static const String thunderstorm = 'thunderstorm';
  static const String localDining = 'local_dining';
  static const String restaurant = 'restaurant';
  static const String noMeals = 'no_meals';
  static const String localPizza = 'local_pizza';
  static const String ramenDining = 'ramen_dining';
  static const String fastfood = 'fastfood';
  static const String noFood = 'no_food';
  static const String cake = 'cake';
  static const String icecream = 'icecream';
  static const String wineBar = 'wine_bar';
  static const String sportsBar = 'sports_bar';
  static const String coffee = 'coffee';
  static const String lunchDining = 'lunch_dining';
  static const String bakeryDining = 'bakery_dining';
  static const String setMeal = 'set_meal';
  static const String brunchDining = 'brunch_dining';
  static const String liquor = 'liquor';
  static const String dinnerDining = 'dinner_dining';
  static const String localCafe = 'local_cafe';
  static const String emojiFoodBeverage = 'emoji_food_beverage';
  static const String localDrink = 'local_drink';
  static const String outdoorGrill = 'outdoor_grill';
  static const String home = 'home';
  static const String apartment = 'apartment';
  static const String bed = 'bed';
  static const String chair = 'chair';
  static const String checkroom = 'checkroom';
  static const String cleaningServices = 'cleaning_services';
  static const String localLaundryService = 'local_laundry_service';
  static const String iron = 'iron';
  static const String build = 'build';
  static const String handyman = 'handyman';
  static const String construction = 'construction';
  static const String plumbing = 'plumbing';
  static const String carpenter = 'carpenter';
  static const String yard = 'yard';
  static const String countertops = 'countertops';
  static const String dryCleaning = 'dry_cleaning';
  static const String deck = 'deck';
  static const String palette = 'palette';
  static const String brush = 'brush';
  static const String draw = 'draw';
  static const String theaterComedy = 'theater_comedy';
  static const String theaters = 'theaters';
  static const String cameraAlt = 'camera_alt';
  static const String piano = 'piano';
  static const String musicNote = 'music_note';
  static const String movie = 'movie';
  static const String videogameAsset = 'videogame_asset';
  static const String headphones = 'headphones';
  static const String casino = 'casino';
  static const String book = 'book';
  static const String autoStories = 'auto_stories';
  static const String mic = 'mic';
  static const String flight = 'flight';
  static const String directionsCar = 'directions_car';
  static const String directionsBoat = 'directions_boat';
  static const String localTaxi = 'local_taxi';
  static const String electricScooter = 'electric_scooter';
  static const String train = 'train';
  static const String directionsBus = 'directions_bus';
  static const String luggage = 'luggage';
  static const String map = 'map';
  static const String beachAccess = 'beach_access';
  static const String hotel = 'hotel';
  static const String public = 'public';
  static const String attractions = 'attractions';
  static const String castle = 'castle';
  static const String deliveryDining = 'delivery_dining';
  static const String stadium = 'stadium';
  static const String cabin = 'cabin';
  static const String star = 'star';
  static const String bolt = 'bolt';
  static const String diamond = 'diamond';
  static const String autoAwesome = 'auto_awesome';
  static const String flag = 'flag';
  static const String warning = 'warning';
  static const String bookmark = 'bookmark';
  static const String event = 'event';
  static const String today = 'today';
  static const String label = 'label';
  static const String lightbulb = 'lightbulb';
  static const String volunteerActivism = 'volunteer_activism';
  static const String church = 'church';
  static const String phoneIphone = 'phone_iphone';
  static const String memory = 'memory';
  static const String settings = 'settings';
  static const String chat = 'chat';
  static const String email = 'email';
  static const String folder = 'folder';
  static const String category = 'category';
  static const String pushPin = 'push_pin';
  static const String batteryChargingFull = 'battery_charging_full';
  static const String batteryAlert = 'battery_alert';
  static const String battery0Bar = 'battery_0_bar';
  static const String battery1Bar = 'battery_1_bar';
  static const String battery3Bar = 'battery_3_bar';
  static const String battery5Bar = 'battery_5_bar';
  static const String batteryFull = 'battery_full';
}

/// Stable string keys mapped to their [IconData]. Keys, not code points,
/// are what gets persisted, so a future Material Icons update can't corrupt
/// stored data.
const Map<String, IconData> tagIconRegistry = {
  'mood': Icons.mood_rounded,
  'sentiment_very_satisfied': Icons.sentiment_very_satisfied_rounded,
  'sentiment_satisfied': Icons.sentiment_satisfied_rounded,
  'sentiment_neutral': Icons.sentiment_neutral_rounded,
  'sentiment_dissatisfied': Icons.sentiment_dissatisfied_rounded,
  'mood_bad': Icons.mood_bad_rounded,
  'sentiment_very_dissatisfied': Icons.sentiment_very_dissatisfied_rounded,
  'person': Icons.person_rounded,
  'account_circle': Icons.account_circle_rounded,
  'groups': Icons.groups_rounded,
  'family_restroom': Icons.family_restroom_rounded,
  'diversity_3': Icons.diversity_3_rounded,
  'pregnant_woman': Icons.pregnant_woman_rounded,
  'child_friendly': Icons.child_friendly_rounded,
  'child_care': Icons.child_care_rounded,
  'elderly': Icons.elderly_rounded,
  'pets': Icons.pets_rounded,
  'handshake': Icons.handshake_rounded,
  'directions_run': Icons.directions_run_rounded,
  'directions_walk': Icons.directions_walk_rounded,
  'hiking': Icons.hiking_rounded,
  'directions_bike': Icons.directions_bike_rounded,
  'fitness_center': Icons.fitness_center_rounded,
  'sports_esports': Icons.sports_esports_rounded,
  'phishing': Icons.phishing_rounded,
  'sports_soccer': Icons.sports_soccer_rounded,
  'sports_basketball': Icons.sports_basketball_rounded,
  'sports_tennis': Icons.sports_tennis_rounded,
  'sports_volleyball': Icons.sports_volleyball_rounded,
  'sports_football': Icons.sports_football_rounded,
  'sports_rugby': Icons.sports_rugby_rounded,
  'sports_hockey': Icons.sports_hockey_rounded,
  'sports_martial_arts': Icons.sports_martial_arts_rounded,
  'pool': Icons.pool_rounded,
  'self_improvement': Icons.self_improvement_rounded,
  'golf_course': Icons.golf_course_rounded,
  'rowing': Icons.rowing_rounded,
  'sailing': Icons.sailing_rounded,
  'kayaking': Icons.kayaking_rounded,
  'surfing': Icons.surfing_rounded,
  'skateboarding': Icons.skateboarding_rounded,
  'snowboarding': Icons.snowboarding_rounded,
  'downhill_skiing': Icons.downhill_skiing_rounded,
  'sledding': Icons.sledding_rounded,
  'nordic_walking': Icons.nordic_walking_rounded,
  'scuba_diving': Icons.scuba_diving_rounded,
  'snowshoeing': Icons.snowshoeing_rounded,
  'roller_skating': Icons.roller_skating_rounded,
  'favorite': Icons.favorite_rounded,
  'local_hospital': Icons.local_hospital_rounded,
  'medication': Icons.medication_rounded,
  'medication_liquid': Icons.medication_liquid_rounded,
  'monitor_heart': Icons.monitor_heart_rounded,
  'monitor_weight': Icons.monitor_weight_rounded,
  'bloodtype': Icons.bloodtype_rounded,
  'vaccines': Icons.vaccines_rounded,
  'bedtime': Icons.bedtime_rounded,
  'spa': Icons.spa_rounded,
  'bathtub': Icons.bathtub_rounded,
  'soap': Icons.soap_rounded,
  'shower': Icons.shower_rounded,
  'water_drop': Icons.water_drop_rounded,
  'smoking_rooms': Icons.smoking_rooms_rounded,
  'smoke_free': Icons.smoke_free_rounded,
  'local_bar': Icons.local_bar_rounded,
  'no_drinks': Icons.no_drinks_rounded,
  'psychology': Icons.psychology_rounded,
  'healing': Icons.healing_rounded,
  'masks': Icons.masks_rounded,
  'device_thermostat': Icons.device_thermostat_rounded,
  'coronavirus': Icons.coronavirus_rounded,
  'work': Icons.work_rounded,
  'business_center': Icons.business_center_rounded,
  'meeting_room': Icons.meeting_room_rounded,
  'school': Icons.school_rounded,
  'menu_book': Icons.menu_book_rounded,
  'edit_note': Icons.edit_note_rounded,
  'assignment': Icons.assignment_rounded,
  'assignment_turned_in': Icons.assignment_turned_in_rounded,
  'checklist': Icons.checklist_rounded,
  'laptop_mac': Icons.laptop_mac_rounded,
  'attach_money': Icons.attach_money_rounded,
  'trending_up': Icons.trending_up_rounded,
  'savings': Icons.savings_rounded,
  'credit_card': Icons.credit_card_rounded,
  'paid': Icons.paid_rounded,
  'shopping_cart': Icons.shopping_cart_rounded,
  'shopping_bag': Icons.shopping_bag_rounded,
  'receipt_long': Icons.receipt_long_rounded,
  'account_balance': Icons.account_balance_rounded,
  'task_alt': Icons.task_alt_rounded,
  'check_circle': Icons.check_circle_rounded,
  'verified': Icons.verified_rounded,
  'celebration': Icons.celebration_rounded,
  'emoji_events': Icons.emoji_events_rounded,
  'rocket_launch': Icons.rocket_launch_rounded,
  'repeat': Icons.repeat_rounded,
  'local_fire_department': Icons.local_fire_department_rounded,
  'whatshot': Icons.whatshot_rounded,
  'military_tech': Icons.military_tech_rounded,
  'block': Icons.block_rounded,
  'schedule': Icons.schedule_rounded,
  'alarm': Icons.alarm_rounded,
  'hourglass_bottom': Icons.hourglass_bottom_rounded,
  'timeline': Icons.timeline_rounded,
  'wb_sunny': Icons.wb_sunny_rounded,
  'cloud': Icons.cloud_rounded,
  'water': Icons.water_rounded,
  'waves': Icons.waves_rounded,
  'umbrella': Icons.umbrella_rounded,
  'ac_unit': Icons.ac_unit_rounded,
  'cyclone': Icons.cyclone_rounded,
  'air': Icons.air_rounded,
  'park': Icons.park_rounded,
  'forest': Icons.forest_rounded,
  'grass': Icons.grass_rounded,
  'landscape': Icons.landscape_rounded,
  'local_florist': Icons.local_florist_rounded,
  'eco': Icons.eco_rounded,
  'terrain': Icons.terrain_rounded,
  'nightlight': Icons.nightlight_rounded,
  'wb_twilight': Icons.wb_twilight_rounded,
  'thunderstorm': Icons.thunderstorm_rounded,
  'local_dining': Icons.local_dining_rounded,
  'restaurant': Icons.restaurant_rounded,
  'no_meals': Icons.no_meals_rounded,
  'local_pizza': Icons.local_pizza_rounded,
  'ramen_dining': Icons.ramen_dining_rounded,
  'fastfood': Icons.fastfood_rounded,
  'no_food': Icons.no_food_rounded,
  'cake': Icons.cake_rounded,
  'icecream': Icons.icecream_rounded,
  'wine_bar': Icons.wine_bar_rounded,
  'sports_bar': Icons.sports_bar_rounded,
  'coffee': Icons.coffee_rounded,
  'lunch_dining': Icons.lunch_dining_rounded,
  'bakery_dining': Icons.bakery_dining_rounded,
  'set_meal': Icons.set_meal_rounded,
  'brunch_dining': Icons.brunch_dining_rounded,
  'liquor': Icons.liquor_rounded,
  'dinner_dining': Icons.dinner_dining_rounded,
  'local_cafe': Icons.local_cafe_rounded,
  'emoji_food_beverage': Icons.emoji_food_beverage_rounded,
  'local_drink': Icons.local_drink_rounded,
  'outdoor_grill': Icons.outdoor_grill_rounded,
  'home': Icons.home_rounded,
  'apartment': Icons.apartment_rounded,
  'bed': Icons.bed_rounded,
  'chair': Icons.chair_rounded,
  'checkroom': Icons.checkroom_rounded,
  'cleaning_services': Icons.cleaning_services_rounded,
  'local_laundry_service': Icons.local_laundry_service_rounded,
  'iron': Icons.iron_rounded,
  'build': Icons.build_rounded,
  'handyman': Icons.handyman_rounded,
  'construction': Icons.construction_rounded,
  'plumbing': Icons.plumbing_rounded,
  'carpenter': Icons.carpenter_rounded,
  'yard': Icons.yard_rounded,
  'countertops': Icons.countertops_rounded,
  'dry_cleaning': Icons.dry_cleaning_rounded,
  'deck': Icons.deck_rounded,
  'palette': Icons.palette_rounded,
  'brush': Icons.brush_rounded,
  'draw': Icons.draw_rounded,
  'theater_comedy': Icons.theater_comedy_rounded,
  'theaters': Icons.theaters_rounded,
  'camera_alt': Icons.camera_alt_rounded,
  'piano': Icons.piano_rounded,
  'music_note': Icons.music_note_rounded,
  'movie': Icons.movie_rounded,
  'videogame_asset': Icons.videogame_asset_rounded,
  'headphones': Icons.headphones_rounded,
  'casino': Icons.casino_rounded,
  'book': Icons.book_rounded,
  'auto_stories': Icons.auto_stories_rounded,
  'mic': Icons.mic_rounded,
  'flight': Icons.flight_rounded,
  'directions_car': Icons.directions_car_rounded,
  'directions_boat': Icons.directions_boat_rounded,
  'local_taxi': Icons.local_taxi_rounded,
  'electric_scooter': Icons.electric_scooter_rounded,
  'train': Icons.train_rounded,
  'directions_bus': Icons.directions_bus_rounded,
  'luggage': Icons.luggage_rounded,
  'map': Icons.map_rounded,
  'beach_access': Icons.beach_access_rounded,
  'hotel': Icons.hotel_rounded,
  'public': Icons.public_rounded,
  'attractions': Icons.attractions_rounded,
  'castle': Icons.castle_rounded,
  'delivery_dining': Icons.delivery_dining_rounded,
  'stadium': Icons.stadium_rounded,
  'cabin': Icons.cabin_rounded,
  'star': Icons.star_rounded,
  'bolt': Icons.bolt_rounded,
  'diamond': Icons.diamond_rounded,
  'auto_awesome': Icons.auto_awesome_rounded,
  'flag': Icons.flag_rounded,
  'warning': Icons.warning_rounded,
  'bookmark': Icons.bookmark_rounded,
  'event': Icons.event_rounded,
  'today': Icons.today_rounded,
  'label': Icons.label_rounded,
  'lightbulb': Icons.lightbulb_rounded,
  'volunteer_activism': Icons.volunteer_activism_rounded,
  'church': Icons.church_rounded,
  'phone_iphone': Icons.phone_iphone_rounded,
  'memory': Icons.memory_rounded,
  'settings': Icons.settings_rounded,
  'chat': Icons.chat_rounded,
  'email': Icons.email_rounded,
  'folder': Icons.folder_rounded,
  'category': Icons.category_rounded,
  'push_pin': Icons.push_pin_rounded,
  'battery_charging_full': Icons.battery_charging_full_rounded,
  'battery_alert': Icons.battery_alert_rounded,
  'battery_0_bar': Icons.battery_0_bar_rounded,
  'battery_1_bar': Icons.battery_1_bar_rounded,
  'battery_3_bar': Icons.battery_3_bar_rounded,
  'battery_5_bar': Icons.battery_5_bar_rounded,
  'battery_full': Icons.battery_full_rounded,
};

/// Map keys into icon groups
const List<TagIconGroup> tagIconGroups = [
  TagIconGroup(id: TagIconGroupId.moodPeople, keys: [
    'mood',
    'sentiment_very_satisfied',
    'sentiment_satisfied',
    'sentiment_neutral',
    'sentiment_dissatisfied',
    'mood_bad',
    'sentiment_very_dissatisfied',
    'person',
    'account_circle',
    'groups',
    'family_restroom',
    'diversity_3',
    'pregnant_woman',
    'child_friendly',
    'child_care',
    'elderly',
    'pets',
    'handshake',
  ]),
  TagIconGroup(id: TagIconGroupId.activities, keys: [
    'directions_run',
    'directions_walk',
    'hiking',
    'directions_bike',
    'fitness_center',
    'sports_esports',
    'phishing',
    'sports_soccer',
    'sports_basketball',
    'sports_tennis',
    'sports_volleyball',
    'sports_football',
    'sports_rugby',
    'sports_hockey',
    'sports_martial_arts',
    'pool',
    'self_improvement',
    'golf_course',
    'rowing',
    'sailing',
    'kayaking',
    'surfing',
    'skateboarding',
    'snowboarding',
    'downhill_skiing',
    'sledding',
    'nordic_walking',
    'scuba_diving',
    'snowshoeing',
    'roller_skating',
  ]),
  TagIconGroup(id: TagIconGroupId.health, keys: [
    'favorite',
    'local_hospital',
    'medication',
    'medication_liquid',
    'monitor_heart',
    'monitor_weight',
    'bloodtype',
    'vaccines',
    'bedtime',
    'spa',
    'bathtub',
    'soap',
    'shower',
    'water_drop',
    'smoking_rooms',
    'smoke_free',
    'local_bar',
    'no_drinks',
    'psychology',
    'healing',
    'masks',
    'device_thermostat',
    'coronavirus',
  ]),
  TagIconGroup(id: TagIconGroupId.workFinance, keys: [
    'work',
    'business_center',
    'meeting_room',
    'school',
    'menu_book',
    'edit_note',
    'assignment',
    'assignment_turned_in',
    'checklist',
    'laptop_mac',
    'attach_money',
    'trending_up',
    'savings',
    'credit_card',
    'paid',
    'shopping_cart',
    'shopping_bag',
    'receipt_long',
    'account_balance',
  ]),
  TagIconGroup(id: TagIconGroupId.habitsGoals, keys: [
    'task_alt',
    'check_circle',
    'verified',
    'celebration',
    'emoji_events',
    'rocket_launch',
    'repeat',
    'local_fire_department',
    'whatshot',
    'military_tech',
    'block',
    'schedule',
    'alarm',
    'hourglass_bottom',
    'timeline',
  ]),
  TagIconGroup(id: TagIconGroupId.nature, keys: [
    'wb_sunny',
    'cloud',
    'water',
    'waves',
    'umbrella',
    'ac_unit',
    'cyclone',
    'air',
    'park',
    'forest',
    'grass',
    'landscape',
    'local_florist',
    'eco',
    'terrain',
    'nightlight',
    'wb_twilight',
    'thunderstorm',
  ]),
  TagIconGroup(id: TagIconGroupId.foodDrink, keys: [
    'local_dining',
    'restaurant',
    'no_meals',
    'local_pizza',
    'ramen_dining',
    'fastfood',
    'no_food',
    'cake',
    'icecream',
    'wine_bar',
    'sports_bar',
    'coffee',
    'lunch_dining',
    'bakery_dining',
    'set_meal',
    'brunch_dining',
    'liquor',
    'dinner_dining',
    'local_cafe',
    'emoji_food_beverage',
    'local_drink',
    'outdoor_grill',
  ]),
  TagIconGroup(id: TagIconGroupId.home, keys: [
    'home',
    'apartment',
    'bed',
    'chair',
    'checkroom',
    'cleaning_services',
    'local_laundry_service',
    'iron',
    'build',
    'handyman',
    'construction',
    'plumbing',
    'carpenter',
    'yard',
    'countertops',
    'dry_cleaning',
    'deck',
  ]),
  TagIconGroup(id: TagIconGroupId.hobbies, keys: [
    'palette',
    'brush',
    'draw',
    'theater_comedy',
    'theaters',
    'camera_alt',
    'piano',
    'music_note',
    'movie',
    'videogame_asset',
    'headphones',
    'casino',
    'book',
    'auto_stories',
    'mic',
  ]),
  TagIconGroup(id: TagIconGroupId.travel, keys: [
    'flight',
    'directions_car',
    'directions_boat',
    'local_taxi',
    'electric_scooter',
    'train',
    'directions_bus',
    'luggage',
    'map',
    'beach_access',
    'hotel',
    'public',
    'attractions',
    'castle',
    'delivery_dining',
    'stadium',
    'cabin',
  ]),
  TagIconGroup(id: TagIconGroupId.symbols, keys: [
    'star',
    'bolt',
    'diamond',
    'auto_awesome',
    'flag',
    'warning',
    'bookmark',
    'event',
    'today',
    'label',
    'lightbulb',
    'volunteer_activism',
    'church',
    'phone_iphone',
    'memory',
    'settings',
    'chat',
    'email',
    'folder',
    'category',
    'push_pin',
    'battery_charging_full',
    'battery_alert',
    'battery_0_bar',
    'battery_1_bar',
    'battery_3_bar',
    'battery_5_bar',
    'battery_full',
  ]),
];

IconData? lookupTagIcon(String? key) =>
    key == null ? null : tagIconRegistry[key];
