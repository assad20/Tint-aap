import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/models/account_models.dart';
import '../../../../core/widgets/tint_ui.dart';
import '../cubit/addresses_cubit.dart';

class AddressFormPage extends StatefulWidget {
  const AddressFormPage({
    super.key,
    this.addressId,
  });

  final String? addressId;

  @override
  State<AddressFormPage> createState() => _AddressFormPageState();
}

class _AddressFormPageState extends State<AddressFormPage> {
  late final TextEditingController nameController;
  late final TextEditingController mobileController;
  late final TextEditingController neighborhoodController;
  late final TextEditingController detailsController;
  String city = 'الرياض';
  String title = 'المنزل';

  @override
  void initState() {
    super.initState();
    final address = context.read<AddressesCubit>().findById(widget.addressId);
    title = address?.title ?? 'المنزل';
    city = address?.city ?? 'الرياض';
    nameController = TextEditingController(text: address?.recipient);
    mobileController = TextEditingController(text: address?.mobile);
    neighborhoodController = TextEditingController(text: address?.neighborhood);
    detailsController = TextEditingController(text: address?.details);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.addressId != null;

    return TintPageScaffold(
      title: isEdit ? 'تعديل العنوان' : 'إضافة عنوان جديد',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [
          SizedBox(
            height: 180,
            child: Stack(
              children: [
                Positioned.fill(
                  child: TintNetworkImage(
                    url: 'https://images.unsplash.com/photo-1524661135-423995f22d0b?w=600&q=80',
                    fit: BoxFit.cover,
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
                const Center(
                  child: CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.location_on, color: Colors.red),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          TintSurfaceCard(
            child: Column(
              children: [
                const Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    'تسمية العنوان',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: ['المنزل', 'العمل', 'أخرى']
                      .map(
                        (item) => Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: ChoiceChip(
                              selected: title == item,
                              label: Text(item),
                              onSelected: (_) => setState(() => title = item),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(hintText: 'الاسم بالكامل'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: mobileController,
                  decoration: const InputDecoration(hintText: 'رقم الجوال'),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: city,
                  items: const [
                    DropdownMenuItem(value: 'الرياض', child: Text('الرياض')),
                    DropdownMenuItem(value: 'جدة', child: Text('جدة')),
                    DropdownMenuItem(value: 'الدمام', child: Text('الدمام')),
                  ],
                  onChanged: (value) => setState(() => city = value ?? city),
                  decoration: const InputDecoration(hintText: 'المدينة'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: neighborhoodController,
                  decoration: const InputDecoration(hintText: 'الحي'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: detailsController,
                  minLines: 2,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: 'تفاصيل العنوان (الشارع، المبنى، الدور...)',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          TintPrimaryButton(
            label: 'حفظ العنوان',
            expanded: true,
            onPressed: () {
              context.read<AddressesCubit>().upsert(
                    AddressModel(
                      id: widget.addressId ?? DateTime.now().millisecondsSinceEpoch.toString(),
                      title: title,
                      recipient: nameController.text.trim(),
                      mobile: mobileController.text.trim(),
                      city: city,
                      neighborhood: neighborhoodController.text.trim(),
                      details: detailsController.text.trim(),
                      isDefault: widget.addressId == null,
                    ),
                  );
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    mobileController.dispose();
    neighborhoodController.dispose();
    detailsController.dispose();
    super.dispose();
  }
}
