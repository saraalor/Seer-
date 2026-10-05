import 'package:cloud_firestore/cloud_firestore.dart';

/// Shown at the end of every brand and model dropdown. Picking it opens a
/// text field so the customer can type a value the list does not have.
const String kOtherOption = 'أخرى';

/// The dropdown lists both apps share: vehicle brands, models per brand,
/// and colors. Stored in Firestore so they can be changed without a new
/// app release:
///
///   lookup_data (collection)
///     vehicles (document)
///       brands: ["تويوتا", "هيونداي", ...]
///       colors: ["أبيض", "أسود", ...]
///       models: { "تويوتا": ["كامري", "كورولا", ...], "كيا": [...] }
///
/// Security Rules should let anyone READ it and let no one write it from
/// the app. Reading must not require sign-in, because a provider picks
/// their vehicle while registering, before they have an account:
///   match /lookup_data/{doc} {
///     allow read: if true;
///     allow write: if false;
///   }
class VehicleLookups {
  const VehicleLookups({
    required this.brands,
    required this.colors,
    required this.models,
    required this.isFallback,
  });

  final List<String> brands;
  final List<String> colors;

  /// Brand -> its models. A brand that is missing here simply has no
  /// suggestions, and the customer types the model under "أخرى".
  final Map<String, List<String>> models;

  /// true when the lists came from the built-in copy below, because
  /// Firestore could not be read or the document is missing.
  final bool isFallback;

  factory VehicleLookups.fallback() {
    return const VehicleLookups(
      brands: kFallbackVehicleBrands,
      colors: kFallbackVehicleColors,
      models: kFallbackVehicleModels,
      isFallback: true,
    );
  }
}

/// Used when Firestore is unreachable, so the customer can still add a
/// vehicle. Keep in step with the shared document.
const List<String> kFallbackVehicleBrands = [
  'تويوتا (Toyota)',
  'هيونداي (Hyundai)',
  'كيا (Kia)',
  'نيسان (Nissan)',
  'فورد (Ford)',
  'شيفروليه (Chevrolet)',
  'لكزس (Lexus)',
  'هوندا (Honda)',
  'مازدا (Mazda)',
  'ميتسوبيشي (Mitsubishi)',
  'إم جي (MG)',
  'جيلي (Geely)',
  'شانجان (Changan)',
  'بي واي دي (BYD)',
  'هافال (Haval)',
  'جي ام سي (GMC)',
  'شيري (Chery)',
  'سوزوكي (Suzuki)',
  'إيسوزو (Isuzu)',
  'دودج (Dodge)',
  'جيب (Jeep)',
  kOtherOption,
];

const List<String> kFallbackVehicleColors = [
  'أبيض',
  'أسود',
  'فضي',
  'رمادي',
  'أزرق',
  'أحمر',
  'بني',
  'ذهبي',
  'بيج',
  'أخضر',
  'كحلي',
  'برتقالي',
  kOtherOption,
];

const Map<String, List<String>> kFallbackVehicleModels = {
  'تويوتا (Toyota)': ['كامري (Camry)', 'كورولا (Corolla)', 'يارس (Yaris)', 'لاندكروزر (Land Cruiser)', 'هايلكس (Hilux)', 'برادو (Prado)', 'راف فور (RAV4)', 'فورتشنر (Fortuner)'],
  'هيونداي (Hyundai)': ['النترا (Elantra)', 'سوناتا (Sonata)', 'أكسنت (Accent)', 'توسان (Tucson)', 'سنتافي (Santa Fe)', 'كريتا (Creta)'],
  'كيا (Kia)': ['سيراتو (Cerato)', 'K5', 'بيجاس (Pegas)', 'سبورتاج (Sportage)', 'سورينتو (Sorento)'],
  'نيسان (Nissan)': ['صني (Sunny)', 'ألتيما (Altima)', 'باترول (Patrol)', 'إكس تريل (X-Trail)', 'نافارا (Navara)', 'ماكسيما (Maxima)'],
  'فورد (Ford)': ['إكسبلورر (Explorer)', 'تورس (Taurus)', 'إكسبيديشن (Expedition)', 'F-150'],
  'شيفروليه (Chevrolet)': ['تاهو (Tahoe)', 'ماليبو (Malibu)', 'كابرس (Caprice)', 'كابتيفا (Captiva)', 'سيلفرادو (Silverado)', 'بليزر (Blazer)'],
  'لكزس (Lexus)': ['ES', 'LS', 'LX', 'RX', 'NX'],
  'هوندا (Honda)': ['أكورد (Accord)', 'سيفيك (Civic)', 'CR-V', 'بايلوت (Pilot)'],
  'مازدا (Mazda)': ['مازدا 6 (Mazda 6)', 'مازدا 3 (Mazda 3)', 'CX-5', 'CX-9', 'CX-30'],
  'ميتسوبيشي (Mitsubishi)': ['باجيرو (Pajero)', 'أوتلاندر (Outlander)', 'أتراج (Attrage)', 'إكليبس كروس (Eclipse Cross)'],
  'إم جي (MG)': ['MG5', 'MG6', 'MG GT', 'MG ZS', 'MG RX5'],
  'جيلي (Geely)': ['كولراي (Coolray)', 'توغيلا (Tugella)', 'مونجارو (Monjaro)', 'إمجراند (Emgrand)'],
  'شانجان (Changan)': ['ألسن (Alsvin)', 'إيدو (Eado)', 'CS35 Plus', 'CS75 Plus', 'CS85', 'CS95', 'UNI-V', 'UNI-K', 'UNI-T'],
  'بي واي دي (BYD)': ['هان (Han)', 'تانغ (Tang)', 'سونغ بلس (Song Plus)', 'تشين بلس (Qin Plus)', 'سيل (Seal)', 'أتو 3 (Atto 3)'],
  'هافال (Haval)': ['H6', 'جوليون (Jolion)', 'H9'],
  'جي ام سي (GMC)': ['يوكن (Yukon)', 'أكاديا (Acadia)', 'تيرين (Terrain)', 'همر (Hummer)', 'سييرا (Sierra)'],
  'شيري (Chery)': ['تيقو 4 (Tiggo 4)', 'تيقو 7 (Tiggo 7)', 'تيقو 8 (Tiggo 8)', 'أريزو 6 (Arrizo 6)'],
  'سوزوكي (Suzuki)': ['سويفت (Swift)', 'ديزاير (Dzire)', 'جيمني (Jimny)', 'فيتارا (Vitara)'],
  'إيسوزو (Isuzu)': ['D-Max', 'MU-X'],
  'دودج (Dodge)': ['تشارجر (Charger)', 'دورانجو (Durango)', 'رام (Ram)'],
  'جيب (Jeep)': ['جراند شيروكي (Grand Cherokee)', 'رانجلر (Wrangler)', 'شيروكي (Cherokee)'],
};

/// Talks to the database.
class LookupModel {
  LookupModel({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  /// Read once per app session: these lists change rarely, and re-reading
  /// them on every form would cost a Firestore read each time.
  static VehicleLookups? _cached;

  Future<VehicleLookups> getVehicleLookups() async {
    final cached = _cached;
    if (cached != null && !cached.isFallback) return cached;

    try {
      final doc = await _firestore.collection('lookup_data').doc('vehicles').get();
      final data = doc.data();

      final brands = _stringList(data?['brands']);
      final colors = _stringList(data?['colors']);
      final models = _modelsMap(data?['models']);

      // An empty or missing list would leave the customer with an empty
      // dropdown, so fall back to the built-in copy for that list.
      final result = VehicleLookups(
        brands: brands.isEmpty ? kFallbackVehicleBrands : brands,
        colors: colors.isEmpty ? kFallbackVehicleColors : colors,
        models: models.isEmpty ? kFallbackVehicleModels : models,
        isFallback: brands.isEmpty && colors.isEmpty && models.isEmpty,
      );
      _cached = result;
      return result;
    } catch (e) {
      return VehicleLookups.fallback();
    }
  }

  static List<String> _stringList(dynamic value) {
    if (value is! List) return const [];
    return [
      for (final item in value)
        if (item is String && item.trim().isNotEmpty) item.trim(),
    ];
  }

  static Map<String, List<String>> _modelsMap(dynamic value) {
    if (value is! Map) return const {};
    final result = <String, List<String>>{};
    value.forEach((key, models) {
      if (key is! String) return;
      final list = _stringList(models);
      if (list.isNotEmpty) result[key.trim()] = list;
    });
    return result;
  }
}
