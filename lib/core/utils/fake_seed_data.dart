import '../models/account_models.dart';
import '../models/cart_item_model.dart';
import '../models/category_model.dart';
import '../models/chat_message_model.dart';
import '../models/product_model.dart';

class FakeSeedData {
  static const fallbackImage =
      'https://images.unsplash.com/photo-1483985988355-763728e1935b?w=400&q=80';
  static const fallbackBanner =
      'https://images.unsplash.com/photo-1483985988355-763728e1935b?w=800&q=80';

  static const topNavCategories = [
    'الرئيسية',
    'المكياج',
    'العطور',
    'العبايات',
    'الفساتين',
    'الإكسسوارات',
    'الهدايا',
    'الجديد',
    'العروض',
  ];

  static final quickLinks = <CategoryModel>[
    const CategoryModel(
      id: 'makeup',
      name: 'مكياج',
      image:
          'https://images.unsplash.com/photo-1596462502278-27bfdc403348?w=150&q=80',
    ),
    const CategoryModel(
      id: 'perfumes',
      name: 'عطور',
      image:
          'https://images.unsplash.com/photo-1541643600914-78b084683601?w=150&q=80',
    ),
    const CategoryModel(
      id: 'abayas',
      name: 'عبايات',
      image:
          'https://images.unsplash.com/photo-1589465885855-40813f367eb7?w=150&q=80',
    ),
    const CategoryModel(
      id: 'dresses',
      name: 'فساتين',
      image:
          'https://images.unsplash.com/photo-1595777457583-95e059d581b8?w=150&q=80',
    ),
    const CategoryModel(
      id: 'accessories',
      name: 'إكسسوارات',
      image:
          'https://images.unsplash.com/photo-1535632066927-ab7c9ab60908?w=150&q=80',
    ),
    const CategoryModel(
      id: 'gifts',
      name: 'هدايا',
      image:
          'https://images.unsplash.com/photo-1549465220-1a8b9238cd48?w=150&q=80',
    ),
    const CategoryModel(
      id: 'best-sellers',
      name: 'الأكثر مبيعاً',
      image:
          'https://images.unsplash.com/photo-1605100804763-247f67b2548e?w=150&q=80',
    ),
    const CategoryModel(
      id: 'new',
      name: 'الجديد',
      image:
          'https://images.unsplash.com/photo-1483985988355-763728e1935b?w=150&q=80',
    ),
    const CategoryModel(
      id: 'trends',
      name: 'ترندات',
      image:
          'https://images.unsplash.com/photo-1485230405346-71acb9518d9c?w=150&q=80',
    ),
    const CategoryModel(
      id: 'offers',
      name: 'عروض',
      image:
          'https://images.unsplash.com/photo-1607083206869-4c7672e72a8a?w=150&q=80',
    ),
  ];

  static final sidebarCategories = <String>[
    'الكل',
    'المكياج',
    'العطور',
    'العبايات',
    'الفساتين',
    'الإكسسوارات',
    'الهدايا',
    'العناية',
    'الأحذية',
    'الحقائب',
    'المنزل',
  ];

  static final productsByCategory = <String, List<ProductModel>>{
    'makeup': [
      const ProductModel(
        id: 'm1',
        brand: 'Tint Beauty',
        title: 'باليت ظلال العيون ترابي',
        price: 120,
        oldPrice: 150,
        image:
            'https://images.unsplash.com/photo-1512496015851-a1c8ce0b0973?w=400&q=80',
        tag: 'ترند',
        views: '2.4k',
        category: 'makeup',
      ),
      const ProductModel(
        id: 'm2',
        brand: 'Glow',
        title: 'أحمر شفاه مخملي مطفي',
        price: 85,
        image:
            'https://images.unsplash.com/photo-1586495777744-4413f21062fa?w=400&q=80',
        tag: 'الأكثر مبيعاً',
        views: '1.2k',
        category: 'makeup',
      ),
      const ProductModel(
        id: 'm3',
        brand: 'Flawless',
        title: 'كريم أساس تغطية كاملة',
        price: 150,
        image:
            'https://images.unsplash.com/photo-1599305090598-fe179d501227?w=400&q=80',
        views: '800',
        category: 'makeup',
      ),
      const ProductModel(
        id: 'm4',
        brand: 'Tint',
        title: 'طقم فرش مكياج احترافية',
        price: 95,
        oldPrice: 130,
        image:
            'https://images.unsplash.com/photo-1522337360788-8b13dee7a37e?w=400&q=80',
        views: '1k',
        category: 'makeup',
      ),
    ],
    'perfumes': [
      const ProductModel(
        id: 'p1',
        brand: 'Luxury Oud',
        title: 'عطر عود ملكي فاخر - 100مل',
        price: 450,
        image:
            'https://images.unsplash.com/photo-1588405748880-12d1d2a59f75?w=400&q=80',
        tag: 'حصري',
        views: '5k',
        category: 'perfumes',
      ),
      const ProductModel(
        id: 'p2',
        brand: 'Tint Paris',
        title: 'عطر زهري فرنسي ناعم',
        price: 280,
        oldPrice: 320,
        image:
            'https://images.unsplash.com/photo-1541643600914-78b084683601?w=400&q=80',
        views: '3k',
        category: 'perfumes',
      ),
      const ProductModel(
        id: 'p3',
        brand: 'Musk',
        title: 'مسك النظافة الأبيض',
        price: 120,
        image:
            'https://images.unsplash.com/photo-1594035910387-fea47794261f?w=400&q=80',
        tag: 'الأكثر طلباً',
        views: '4.2k',
        category: 'perfumes',
      ),
      const ProductModel(
        id: 'p4',
        brand: 'Night',
        title: 'عطر السهرات الكلاسيكي',
        price: 320,
        image:
            'https://images.unsplash.com/photo-1590736969955-71cc94801759?w=400&q=80',
        views: '2k',
        category: 'perfumes',
      ),
    ],
    'abayas': [
      const ProductModel(
        id: 'a1',
        brand: 'أناقة',
        title: 'عباية سوداء كلاسيكية بتطريز ناعم',
        price: 250,
        image:
            'https://images.unsplash.com/photo-1589465885855-40813f367eb7?w=400&q=80',
        tag: 'جديد',
        views: '1.5k',
        category: 'abayas',
      ),
      const ProductModel(
        id: 'a2',
        brand: 'Tint',
        title: 'عباية عملية قماش كريب',
        price: 180,
        oldPrice: 220,
        image:
            'https://images.unsplash.com/photo-1512316668700-111fb08dbf8c?w=400&q=80',
        views: '900',
        category: 'abayas',
      ),
      const ProductModel(
        id: 'a3',
        brand: 'الشرق',
        title: 'عباية مناسبات فاخرة',
        price: 450,
        image:
            'https://images.unsplash.com/photo-1550639525-c97d455acf70?w=400&q=80',
        tag: 'محدود',
        views: '3.1k',
        category: 'abayas',
      ),
      const ProductModel(
        id: 'a4',
        brand: 'ألوان',
        title: 'عباية صيفية بلون ترابي',
        price: 210,
        image:
            'https://images.unsplash.com/photo-1601333144130-8c1f12369685?w=400&q=80',
        views: '1.1k',
        category: 'abayas',
      ),
    ],
    'dresses': [
      const ProductModel(
        id: 'd1',
        brand: 'Glamour',
        title: 'فستان سهرة مخملي طويل',
        price: 550,
        image:
            'https://images.unsplash.com/photo-1595777457583-95e059d581b8?w=400&q=80',
        tag: 'ترند الموسم',
        views: '6k',
        category: 'dresses',
      ),
      const ProductModel(
        id: 'd2',
        brand: 'Tint',
        title: 'فستان ناعم للمناسبات البسيطة',
        price: 220,
        oldPrice: 280,
        image:
            'https://images.unsplash.com/photo-1515347619252-5d8122d4f2bc?w=400&q=80',
        views: '2.2k',
        category: 'dresses',
      ),
      const ProductModel(
        id: 'd3',
        brand: 'Chic',
        title: 'فستان صيفي مشجر',
        price: 150,
        image:
            'https://images.unsplash.com/photo-1572804013309-82a89b47afc2?w=400&q=80',
        views: '1.8k',
        category: 'dresses',
      ),
      const ProductModel(
        id: 'd4',
        brand: 'Elegance',
        title: 'فستان كلاسيكي أسود',
        price: 300,
        image:
            'https://images.unsplash.com/photo-1539008835657-9e8e9680c956?w=400&q=80',
        tag: 'لا غنى عنه',
        views: '4.5k',
        category: 'dresses',
      ),
    ],
    'accessories': [
      const ProductModel(
        id: 'ac1',
        brand: 'Tint Gold',
        title: 'طقم قلادة وأقراط ذهبي',
        price: 85,
        oldPrice: 120,
        image:
            'https://images.unsplash.com/photo-1535632066927-ab7c9ab60908?w=400&q=80',
        tag: 'الأكثر مبيعاً',
        views: '8.2k',
        category: 'accessories',
      ),
      const ProductModel(
        id: 'ac2',
        brand: 'Silver',
        title: 'خاتم فضي بتصميم عصري',
        price: 45,
        image:
            'https://images.unsplash.com/photo-1605100804763-247f67b2548e?w=400&q=80',
        views: '3k',
        category: 'accessories',
      ),
      const ProductModel(
        id: 'ac3',
        brand: 'Tint',
        title: 'نظارة شمسية كلاسيكية',
        price: 120,
        image:
            'https://images.unsplash.com/photo-1511499767150-a48a237f0083?w=400&q=80',
        views: '1.2k',
        category: 'accessories',
      ),
      const ProductModel(
        id: 'ac4',
        brand: 'Glam',
        title: 'أساور لؤلؤ ناعمة',
        price: 60,
        oldPrice: 80,
        image:
            'https://images.unsplash.com/photo-1611591437281-460bfbe1220a?w=400&q=80',
        views: '2.1k',
        category: 'accessories',
      ),
    ],
    'gifts': [
      const ProductModel(
        id: 'g1',
        brand: 'Tint Box',
        title: 'صندوق هدية متكامل (عطر + إكسسوار)',
        price: 350,
        image:
            'https://images.unsplash.com/photo-1549465220-1a8b9238cd48?w=400&q=80',
        tag: 'جاهزة للإهداء',
        views: '3.5k',
        category: 'gifts',
      ),
      const ProductModel(
        id: 'g2',
        brand: 'Luxury',
        title: 'تغليف هدايا فاخر للعرائس',
        price: 150,
        image:
            'https://images.unsplash.com/photo-1512909006721-3d6018887383?w=400&q=80',
        views: '1k',
        category: 'gifts',
      ),
      const ProductModel(
        id: 'g3',
        brand: 'Tint',
        title: 'بطاقة هدايا إلكترونية',
        price: 100,
        image:
            'https://images.unsplash.com/photo-1556742049-0cfed4f6a45d?w=400&q=80',
        views: '500',
        category: 'gifts',
      ),
    ],
  };

  static List<ProductModel> get allProducts => productsByCategory.values
      .expand((items) => items)
      .toList(growable: false);

  static List<ProductModel> get bestSellers => [
        productsByCategory['makeup']![1],
        productsByCategory['perfumes']![2],
        productsByCategory['accessories']![0],
        productsByCategory['dresses']![3],
      ];

  static List<ProductModel> get newArrivals => [
        productsByCategory['abayas']![0],
        productsByCategory['makeup']![0],
        productsByCategory['dresses']![0],
      ];

  static List<ProductModel> get offers =>
      allProducts.where((product) => product.oldPrice != null).toList();

  static List<ProductModel> get topTrending => [
        productsByCategory['dresses']![0],
        productsByCategory['perfumes']![0],
        productsByCategory['accessories']![0],
      ];

  static List<ProductModel> get mostViewed => [
        productsByCategory['makeup']![0],
        productsByCategory['perfumes']![2],
        productsByCategory['accessories']![0],
        productsByCategory['dresses']![3],
      ];

  static List<CartItemModel> get cartItems => [
        CartItemModel(
          cartId: 'c1',
          product: productsByCategory['makeup']![0],
          quantity: 1,
          variant: 'درجة 02 - نيود',
        ),
        CartItemModel(
          cartId: 'c2',
          product: productsByCategory['perfumes']![1],
          quantity: 2,
          variant: '100 مل',
        ),
        CartItemModel(
          cartId: 'c3',
          product: productsByCategory['dresses']![0],
          quantity: 1,
          variant: 'مقاس M - أسود',
        ),
      ];

  static ProfileBundle get profileBundle => ProfileBundle(
        profile: const UserProfileModel(
          name: 'سارة أحمد',
          phone: '+966 50 123 4567',
          membershipTier: 'عضوية بلاتينية VIP',
          avatarUrl:
              'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=150&q=80',
          points: 1250,
          couponsCount: 3,
          walletBalance: 50,
        ),
        paymentCards: const [
          PaymentCardModel(
            id: 'card_1',
            label: 'بطاقة العمل',
            maskedNumber: '**** **** **** 4242',
            brand: 'VISA',
            isDefault: true,
          ),
          PaymentCardModel(
            id: 'card_2',
            label: 'مدى الشخصية',
            maskedNumber: '**** **** **** 1881',
            brand: 'mada',
            isDefault: false,
          ),
        ],
        browsingHistory: [
          productsByCategory['dresses']![0],
          productsByCategory['abayas']![2],
          productsByCategory['perfumes']![1],
          productsByCategory['accessories']![2],
        ],
        sizeProfiles: const [
          SizeProfileModel(
            id: 'size_1',
            title: 'إطلالات السهرات',
            dressSize: 'M',
            abayaSize: '54',
            notes: 'أفضلني القصات الواسعة والخصر العالي',
          ),
          SizeProfileModel(
            id: 'size_2',
            title: 'العبايات اليومية',
            dressSize: 'L',
            abayaSize: '56',
            notes: 'أكمام واسعة وطول إضافي 2 سم',
          ),
        ],
        giftCards: const [
          GiftCardModel(
            id: 'gift_1',
            title: 'بطاقة هدية عيد ميلاد',
            balanceLabel: '100 ﷼',
            code: 'TINT-GIFT-100',
            expiryLabel: 'تنتهي في 30 يونيو 2026',
          ),
          GiftCardModel(
            id: 'gift_2',
            title: 'بطاقة هدية فاخرة',
            balanceLabel: '250 ﷼',
            code: 'VIP-GIFT-250',
            expiryLabel: 'تنتهي في 10 أغسطس 2026',
          ),
        ],
        stockAlerts: [
          StockAlertModel(
            id: 'alert_1',
            product: productsByCategory['accessories']![2]
                .copyWith(isAvailable: false),
            variant: 'لون أسود',
            createdAtLabel: 'أُنشئ التنبيه قبل 3 أيام',
          ),
          StockAlertModel(
            id: 'alert_2',
            product: productsByCategory['abayas']![1]
                .copyWith(isAvailable: false),
            variant: 'مقاس 56',
            createdAtLabel: 'أُنشئ التنبيه قبل أسبوع',
          ),
        ],
      );

  static RewardsBundle get rewardsBundle => const RewardsBundle(
        availablePoints: 1250,
        pendingPoints: 150,
        usedPoints: 850,
        walletBalance: 50,
        history: [
          RewardTransactionModel(
            id: 1,
            type: 'earn',
            title: 'مكافأة الشراء من طلب #TN-98765',
            points: '+150',
            dateLabel: '15 مايو 2024',
            status: 'مكتملة',
          ),
          RewardTransactionModel(
            id: 2,
            type: 'spend',
            title: 'خصم مستخدم في طلب #TN-98700',
            points: '-80',
            dateLabel: '02 مايو 2024',
            status: 'مكتملة',
          ),
          RewardTransactionModel(
            id: 3,
            type: 'earn',
            title: 'تقييم 3 منتجات من طلب سابق',
            points: '+30',
            dateLabel: '28 أبريل 2024',
            status: 'مكتملة',
          ),
          RewardTransactionModel(
            id: 4,
            type: 'earn',
            title: 'مكافأة التسجيل في متجر تنت',
            points: '+100',
            dateLabel: '20 أبريل 2024',
            status: 'مكتملة',
          ),
        ],
        coupons: [
          CouponModel(
            id: 'coupon_1',
            title: 'خصم 15% على المكياج',
            code: 'TINT15',
            subtitle: 'صالح حتى نهاية الشهر',
            badge: 'ينتهي قريباً',
          ),
          CouponModel(
            id: 'coupon_2',
            title: 'توصيل مجاني',
            code: 'FREESHIP',
            subtitle: 'للطلبات فوق 300 ريال',
          ),
          CouponModel(
            id: 'coupon_3',
            title: 'خصم 25 ﷼ لعضوية VIP',
            code: 'VIP25',
            subtitle: 'يستخدم مرة واحدة خلال هذا الشهر',
          ),
        ],
        walletTransactions: [
          WalletTransactionModel(
            id: 'wallet_1',
            title: 'تعويض عن طلب #TN-553',
            dateLabel: '01 مايو 2024',
            amountLabel: '+50.00 ﷼',
          ),
        ],
      );

  static List<OrderModel> get orders => [
        OrderModel(
          id: 'TN-98765',
          dateLabel: '15 مايو 2024',
          status: OrderStatus.shipped,
          items: [
            OrderItemModel(
              product: productsByCategory['makeup']![0],
              qty: 1,
              variant: 'درجة 02 - نيود',
            ),
            OrderItemModel(
              product: productsByCategory['perfumes']![1],
              qty: 2,
              variant: '100 مل',
            ),
          ],
          subtotal: 680,
          shipping: 0,
          total: 680,
          address:
              'المملكة العربية السعودية، الرياض، حي الياسمين، شارع العليا، مبنى 1234',
          paymentMethod: 'Apple Pay',
        ),
        OrderModel(
          id: 'TN-98700',
          dateLabel: '02 مايو 2024',
          status: OrderStatus.delivered,
          items: [
            OrderItemModel(
              product: productsByCategory['dresses']![0],
              qty: 1,
              variant: 'مقاس M - أسود',
            ),
          ],
          subtotal: 550,
          shipping: 25,
          total: 575,
          address: 'المملكة العربية السعودية، جدة، حي الشاطئ، شارع الكورنيش',
          paymentMethod: 'البطاقة الائتمانية',
        ),
        OrderModel(
          id: 'TN-98650',
          dateLabel: '28 أبريل 2024',
          status: OrderStatus.processing,
          items: [
            OrderItemModel(
              product: productsByCategory['accessories']![0],
              qty: 1,
              variant: 'ذهبي',
            ),
            OrderItemModel(
              product: productsByCategory['makeup']![2],
              qty: 1,
              variant: 'تغطية كاملة',
            ),
          ],
          subtotal: 235,
          shipping: 25,
          total: 260,
          address: 'المملكة العربية السعودية، الرياض، حي النرجس',
          paymentMethod: 'Tabby (مقسمة على 4 دفعات)',
        ),
        OrderModel(
          id: 'TN-98600',
          dateLabel: '10 أبريل 2024',
          status: OrderStatus.cancelled,
          items: [
            OrderItemModel(
              product: productsByCategory['abayas']![1],
              qty: 1,
              variant: 'مقاس 54',
            ),
          ],
          subtotal: 180,
          shipping: 25,
          total: 205,
          address: 'المملكة العربية السعودية، الدمام، حي الشاطئ',
          paymentMethod: 'الدفع عند الاستلام',
        ),
      ];

  static List<ProductModel> get favorites => [
        productsByCategory['dresses']![0],
        productsByCategory['makeup']![1],
        productsByCategory['perfumes']![0],
        productsByCategory['accessories']![2].copyWith(isAvailable: false),
        productsByCategory['abayas']![1],
      ];

  static List<AddressModel> get addresses => const [
        AddressModel(
          id: '1',
          title: 'المنزل',
          recipient: 'سارة أحمد',
          mobile: '0501234567',
          city: 'الرياض',
          neighborhood: 'حي الياسمين',
          details: 'شارع العليا، مبنى 1234، الدور 2، شقة 15',
          isDefault: true,
        ),
        AddressModel(
          id: '2',
          title: 'العمل',
          recipient: 'سارة أحمد',
          mobile: '0509876543',
          city: 'الرياض',
          neighborhood: 'حي الملقا',
          details: 'طريق الأمير محمد بن سعد، برج الأعمال، الدور 8',
          isDefault: false,
        ),
      ];

  static List<ChatMessageModel> get defaultAssistantMessages => [
        ChatMessageModel(
          role: ChatRole.assistant,
          content:
              'أهلاً بك في تنت (Tint)! أنا مستشار الموضة والجمال ✨. أي قسم تتصفحين اليوم لأساعدك في الاختيار؟',
          createdAt: DateTime.now(),
        ),
      ];

  static List<ProductModel> productsForCategoryName(String categoryName) {
    return switch (categoryName) {
      'المكياج' => productsByCategory['makeup']!,
      'العطور' => productsByCategory['perfumes']!,
      'العبايات' => productsByCategory['abayas']!,
      'الفساتين' => productsByCategory['dresses']!,
      'الإكسسوارات' => productsByCategory['accessories']!,
      'الهدايا' => productsByCategory['gifts']!,
      'الجديد' => newArrivals,
      'العروض' => offers,
      _ => allProducts,
    };
  }

  static List<ProductModel> searchProducts(String query) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) {
      return allProducts.take(8).toList();
    }
    return allProducts.where((product) {
      return product.title.toLowerCase().contains(normalized) ||
          product.brand.toLowerCase().contains(normalized) ||
          product.category.toLowerCase().contains(normalized);
    }).toList();
  }
}
