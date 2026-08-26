import 'package:flutter_test/flutter_test.dart';
import 'package:tint_mobile/core/models/account_models.dart';

AddressModel _a({String details = '', String? building}) => AddressModel(
      id: '1', title: 'المنزل', recipient: 'نواف', mobile: '05',
      city: 'الرياض', neighborhood: 'العليا', details: details,
      isDefault: false, buildingNumber: building,
    );

void main() {
  test('لا يتكرّر رقم المبنى إن كان في التفاصيل أصلاً', () {
    expect(_a(details: '2868 طريق العروبة', building: '2868').line,
        '2868 طريق العروبة، العليا، الرياض');
  });

  test('يُصدَّر الرقم حين تخلو التفاصيل منه', () {
    expect(_a(details: 'طريق العروبة', building: '2868').line,
        '2868 طريق العروبة، العليا، الرياض');
  });

  test('بلا رقم مبنى يبقى السطر كما هو', () {
    expect(_a(details: 'طريق العروبة').line, 'طريق العروبة، العليا، الرياض');
  });

  test('تفاصيل فارغة لا تُنتج فاصلةً يتيمة', () {
    expect(_a().line, 'العليا، الرياض');
  });
}
