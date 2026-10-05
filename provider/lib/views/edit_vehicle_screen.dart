import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'provider_profile_screen.dart';
import '../widgets/plate_number_field.dart';
import '../models/lookup_model.dart';

class EditVehicleScreen extends StatefulWidget {
  final ServiceProviderData provider;

  const EditVehicleScreen({super.key, required this.provider});

  @override
  State<EditVehicleScreen> createState() => _EditVehicleScreenState();
}//end EditVehicleScreen

class _EditVehicleScreenState extends State<EditVehicleScreen> {
  late TextEditingController licenseController;

  // Brand, model and color are picked from the shared Firestore lists
  // (lookup_data/vehicles). Picking "أخرى" shows a text field instead.
  VehicleLookups _lookups = VehicleLookups.fallback();
  String? _brand;
  String? _model;
  String? _color;
  final _brandOther = TextEditingController();
  final _modelOther = TextEditingController();
  final _colorOther = TextEditingController();

  /// Set once the user changes a vehicle field, so the lists arriving
  /// from Firestore never overwrite what they picked.
  bool _edited = false;
  late String _initialPlateDigits;
  late String _initialPlateArabicLetters;

  bool _plateError = false;

  final _plateFieldKey = GlobalKey<PlateNumberFieldState>();
  final _formKey = GlobalKey<FormState>();

  static List<String> _withOther(List<String> options) => [
        for (final option in options)
          if (option != kOtherOption) option,
        kOtherOption,
      ];

  List<String> get _brandOptions => _withOther(_lookups.brands);
  List<String> get _colorOptions => _withOther(_lookups.colors);

  List<String> get _modelOptions {
    final String? brand = _brand;
    if (brand == null) return const [];
    if (brand == kOtherOption) return const [kOtherOption];
    return _withOther(_lookups.models[brand] ?? const []);
  }

  /// A saved value either matches an option, or becomes "أخرى" plus text,
  /// so a vehicle saved before the lists changed still shows its value.
  static (String?, String) _split(String saved, List<String> options) {
    final String value = saved.trim();
    if (value.isEmpty) return (null, '');
    if (options.contains(value)) return (value, '');
    return (kOtherOption, value);
  }

  void _applySavedVehicle() {
    final brand = _split(widget.provider.vehicleBrand, _brandOptions);
    _brand = brand.$1;
    _brandOther.text = brand.$2;

    final model = _split(widget.provider.vehicleModel, _modelOptions);
    _model = model.$1;
    _modelOther.text = model.$2;

    final color = _split(widget.provider.vehicleColor, _colorOptions);
    _color = color.$1;
    _colorOther.text = color.$2;
  }

  Future<void> _loadLookups() async {
    final VehicleLookups lookups = await LookupModel().getVehicleLookups();
    if (!mounted) return;
    setState(() {
      _lookups = lookups;
      if (!_edited) _applySavedVehicle();
    });
  }

  String _valueOf(String? selection, TextEditingController other) =>
      selection == kOtherOption ? other.text.trim() : (selection ?? '');

  /// One dropdown plus the text field shown when "أخرى" is picked.
  List<Widget> _lookupField({
    required Key key,
    required String label,
    required String? value,
    required List<String> options,
    required TextEditingController other,
    required String requiredMessage,
    required String otherLabel,
    required ValueChanged<String?> onChanged,
  }) {
    return [
      DropdownButtonFormField<String>(
        key: key,
        initialValue: options.contains(value) ? value : null,
        menuMaxHeight: 320,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        items: options.map((option) {
          return DropdownMenuItem<String>(value: option, child: Text(option));
        }).toList(),
        onChanged: options.isEmpty ? null : onChanged,
        validator: (selected) =>
            selected == null || selected.isEmpty ? requiredMessage : null,
      ),
      if (value == kOtherOption) ...[
        const SizedBox(height: 10),
        TextFormField(
          controller: other,
          decoration: InputDecoration(
            labelText: otherLabel,
            border: const OutlineInputBorder(),
          ),
          validator: (text) =>
              text == null || text.trim().isEmpty ? requiredMessage : null,
        ),
      ],
    ];
  }

  @override
  void initState() {
    super.initState();

    _applySavedVehicle();
    _loadLookups();

    licenseController =
        TextEditingController(text: widget.provider.licenseNumber);

    final arabicParts = widget.provider.plateNumberArabic.trim().split(' ');
    _initialPlateDigits =
        arabicParts.isNotEmpty ? arabicParts[0] : '';
    _initialPlateArabicLetters =
        arabicParts.length > 1 ? arabicParts[1] : '';
  }//end initState

  @override
  void dispose() {
    _brandOther.dispose();
    _modelOther.dispose();
    _colorOther.dispose();
    licenseController.dispose();
    super.dispose();
  }//end dispose

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('تعديل تفاصيل المركبة'),
          backgroundColor: AppColors.background,
          foregroundColor: AppColors.navy,
          elevation: 0,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(18),
            child: Form(
              key: _formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [

                  ..._lookupField(
                    key: ValueKey(('brand', _lookups)),
                    label: 'ماركة المركبة',
                    value: _brand,
                    options: _brandOptions,
                    other: _brandOther,
                    requiredMessage: 'ماركة المركبة مطلوبة',
                    otherLabel: 'حدد الماركة',
                    onChanged: (value) {
                      setState(() {
                        _edited = true;
                        _brand = value;
                        if (value != kOtherOption) _brandOther.clear();
                        // A new brand has its own models.
                        _model = value == kOtherOption ? kOtherOption : null;
                        _modelOther.clear();
                      });
                    },
                  ),

                  const SizedBox(height: 14),

                  ..._lookupField(
                    key: ValueKey(('model', _brand, _lookups)),
                    label: 'موديل المركبة',
                    value: _model,
                    options: _modelOptions,
                    other: _modelOther,
                    requiredMessage: 'موديل المركبة مطلوب',
                    otherLabel: 'حدد الموديل',
                    onChanged: (value) {
                      setState(() {
                        _edited = true;
                        _model = value;
                        if (value != kOtherOption) _modelOther.clear();
                      });
                    },
                  ),

                  const SizedBox(height: 14),

                  ..._lookupField(
                    key: ValueKey(('color', _lookups)),
                    label: 'لون المركبة',
                    value: _color,
                    options: _colorOptions,
                    other: _colorOther,
                    requiredMessage: 'لون المركبة مطلوب',
                    otherLabel: 'حدد اللون',
                    onChanged: (value) {
                      setState(() {
                        _edited = true;
                        _color = value;
                        if (value != kOtherOption) _colorOther.clear();
                      });
                    },
                  ),

                  const SizedBox(height: 14),

                  PlateNumberField(
                    key: _plateFieldKey,
                    navy: AppColors.navy,
                    initialDigits: _initialPlateDigits,
                    initialArabicLetters: _initialPlateArabicLetters,
                  ),

                  if (_plateError)
                    const Padding(
                      padding: EdgeInsets.only(top: 6),
                      child: Text(
                        'رقم اللوحة مطلوب',
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 12,
                        ),
                      ),
                    ),

                  const SizedBox(height: 14),

                  TextFormField(
                    controller: licenseController,
                    enabled: false,
                    decoration: const InputDecoration(
                      labelText: 'رقم الرخصة',
                      border: OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(height: 24),

                  //Button to save changes
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.blue,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () {
                      final plateValue =
                          _plateFieldKey.currentState!.value;

                      setState(() {
                        _plateError = !plateValue.isValid;
                      });

                      if (_formKey.currentState!.validate() &&
                          plateValue.isValid) {

                        final brand = _valueOf(_brand, _brandOther);
                        final model = _valueOf(_model, _modelOther);

                        final updatedProvider = ServiceProviderData(
                          firstName: widget.provider.firstName,
                          lastName: widget.provider.lastName,
                          phone: widget.provider.phone,
                          email: widget.provider.email,
                          nationalId: widget.provider.nationalId,

                          vehicleBrand: brand,
                          vehicleModel: model,
                          vehicle: '$brand $model',

                          plateNumberArabic:
                              '${plateValue.digits} ${plateValue.arabicLetters}',
                          plateNumberLatin:
                              '${plateValue.digits} ${plateValue.englishLetters}',
                          vehicleColor: _valueOf(_color, _colorOther),
                          licenseNumber: licenseController.text,
                          rating: widget.provider.rating,
                          status: widget.provider.status,
                          activeBranches: widget.provider.activeBranches,
                          isAvailable: widget.provider.isAvailable,
                        );

                        Navigator.pop(context, updatedProvider);
                      }//end if
                    },
                    child: const Text(
                      'حفظ التغييرات',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }//end build
}//end _EditVehicleScreenState