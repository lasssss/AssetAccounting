class Asset {
  int? id;
  String inventoryNumber;
  String name;
  int categoryId;
  double initialCost;
  double salvageValue;
  int usefulLifeMonths;
  DateTime startDate;
  String? location;
  String? responsiblePerson;
  String status;
  String? notes;
  String? department;
  String? cipher;
  String? serialNumber;
  String? equipmentType;
  int quantity;
  String? unit;
  String? indicator;
  DateTime? inactiveDate;
  DateTime? resumeDate;
  DateTime? statusDate;
  String? card;
  bool isDeleted;
  String? deletedReason;
  DateTime? deletedAt;

  Asset({
    this.id,
    required this.inventoryNumber,
    required this.name,
    required this.categoryId,
    required this.initialCost,
    this.salvageValue = 0,
    required this.usefulLifeMonths,
    required this.startDate,
    this.location,
    this.responsiblePerson,
    this.status = 'active',
    this.notes,
    this.department,
    this.cipher,
    this.serialNumber,
    this.equipmentType,
    this.quantity = 1,
    this.unit,
    this.indicator,
    this.inactiveDate,
    this.resumeDate,
    this.statusDate,
    this.card,
    this.isDeleted = false,
    this.deletedReason,
    this.deletedAt,
  });

  double get monthlyDepreciation {
    if (usefulLifeMonths <= 0) return 0;
    final base = initialCost - salvageValue;
    if (base <= 0) return 0;
    return double.parse((base / usefulLifeMonths).toStringAsFixed(2));
  }

  int get monthsElapsed {
    if (startDate == null) return 0;
    final now = DateTime.now();
    return (now.year - startDate.year) * 12 + (now.month - startDate.month);
  }

  double get residualValue {
    final applied = monthsElapsed < usefulLifeMonths ? monthsElapsed : usefulLifeMonths;
    return double.parse((initialCost - applied * monthlyDepreciation).toStringAsFixed(2));
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'inventory_number': inventoryNumber,
    'name': name,
    'category_id': categoryId,
    'initial_cost': initialCost,
    'salvage_value': salvageValue,
    'useful_life_months': usefulLifeMonths,
    'start_date': startDate.toIso8601String(),
    'location': location,
    'responsible_person': responsiblePerson,
    'status': status,
    'notes': notes,
    'department': department,
    'cipher': cipher,
    'serial_number': serialNumber,
    'equipment_type': equipmentType,
    'quantity': quantity,
    'unit': unit,
    'indicator': indicator,
    'inactive_date': inactiveDate?.toIso8601String(),
    'resume_date': resumeDate?.toIso8601String(),
    'status_date': statusDate?.toIso8601String(),
    'card': card,
    'is_deleted': isDeleted ? 1 : 0,
    'deleted_reason': deletedReason,
    'deleted_at': deletedAt?.toIso8601String(),
  };

  factory Asset.fromMap(Map<String, dynamic> m) => Asset(
    id: m['id'],
    inventoryNumber: m['inventory_number'],
    name: m['name'],
    categoryId: m['category_id'],
    initialCost: (m['initial_cost'] as num).toDouble(),
    salvageValue: (m['salvage_value'] as num?)?.toDouble() ?? 0,
    usefulLifeMonths: m['useful_life_months'],
    startDate: DateTime.parse(m['start_date']),
    location: m['location'],
    responsiblePerson: m['responsible_person'],
    status: m['status'] ?? 'active',
    notes: m['notes'],
    department: m['department'],
    cipher: m['cipher'],
    serialNumber: m['serial_number'],
    equipmentType: m['equipment_type'],
    quantity: m['quantity'] ?? 1,
    unit: m['unit'],
    indicator: m['indicator'],
    inactiveDate: m['inactive_date'] != null ? DateTime.parse(m['inactive_date']) : null,
    resumeDate: m['resume_date'] != null ? DateTime.parse(m['resume_date']) : null,
    statusDate: m['status_date'] != null ? DateTime.parse(m['status_date']) : null,
    card: m['card'],
    isDeleted: m['is_deleted'] == 1,
    deletedReason: m['deleted_reason'],
    deletedAt: m['deleted_at'] != null ? DateTime.parse(m['deleted_at']) : null,
  );
}