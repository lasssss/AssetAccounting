from datetime import date
from flask_sqlalchemy import SQLAlchemy
from sqlalchemy import Column, Integer, String, Float, Date, Text, Boolean, ForeignKey, create_engine, inspect, text
from sqlalchemy.orm import declarative_base, relationship, sessionmaker

db = SQLAlchemy()


class Registry(db.Model):
    __tablename__ = 'registries'
    id = Column(Integer, primary_key=True)
    name = Column(String(200), nullable=False)
    description = Column(Text)
    db_file = Column(String(200), nullable=False)
    created_at = Column(Date, default=date.today)

    def __repr__(self):
        return self.name


RegistryBase = declarative_base()


class Category(RegistryBase):
    __tablename__ = 'categories'
    id = Column(Integer, primary_key=True)
    name = Column(String(100), nullable=False, unique=True)
    assets = relationship('Asset', back_populates='category_rel')

    def __repr__(self):
        return self.name


class Asset(RegistryBase):
    __tablename__ = 'assets'
    id = Column(Integer, primary_key=True)
    inventory_number = Column(String(50), unique=True, nullable=False)
    name = Column(String(200), nullable=False)
    category_id = Column(Integer, ForeignKey('categories.id'), nullable=False)
    initial_cost = Column(Float, nullable=False)
    salvage_value = Column(Float, default=0.0)
    useful_life_months = Column(Integer, nullable=False)
    depreciation_method = Column(String(20), default='linear')
    start_date = Column(Date, nullable=False)
    location = Column(String(200))
    responsible_person = Column(String(100))
    status = Column(String(20), default='active')
    notes = Column(Text)
    department = Column(String(200))
    cipher = Column(String(100))
    serial_number = Column(String(100))
    equipment_type = Column(String(100))
    quantity = Column(Integer, default=1)
    unit = Column(String(50))
    indicator = Column(String(100))
    inactive_date = Column(Date)
    resume_date = Column(Date)
    status_date = Column(Date)
    card = Column(String(200))
    is_deleted = Column(Boolean, default=False)
    deleted_reason = Column(Text)
    deleted_at = Column(Date)

    category_rel = relationship('Category', back_populates='assets')
    movements = relationship('Movement', back_populates='asset_rel', order_by='Movement.date.desc()')

    @property
    def monthly_depreciation(self):
        if self.useful_life_months <= 0:
            return 0.0
        base = self.initial_cost - self.salvage_value
        if base <= 0:
            return 0.0
        return round(base / self.useful_life_months, 2)

    @property
    def months_elapsed(self):
        if not self.start_date:
            return 0
        today = date.today()
        return max(0, (today.year - self.start_date.year) * 12 + (today.month - self.start_date.month))

    @property
    def accumulated_depreciation(self):
        applied = min(self.months_elapsed, self.useful_life_months)
        return round(applied * self.monthly_depreciation, 2)

    @property
    def residual_value(self):
        return round(self.initial_cost - self.accumulated_depreciation, 2)

    @property
    def status_display(self):
        labels = {'active': 'В эксплуатации', 'zip': 'ЗИП', 'repair': 'В ремонте',
                  'disposed': 'Списано', 'for_disposal': 'На списание',
                  'transferred': 'Передано',
                  'unused': 'Не используется', 'undefined': 'Не определено'}
        return labels.get(self.status, self.status)

    INDICATOR_STATUS_MAP = {
        'в эксплуатации': 'active', 'работает': 'active',
        'ЗИП': 'zip', 'в резерве': 'zip',
        'в ремонте': 'repair',
        'списано': 'disposed', 'списан': 'disposed',
        'не используется': 'unused', 'на консервации': 'unused',
    }

    def __repr__(self):
        return f'{self.inventory_number} — {self.name}'


class AssetPhoto(RegistryBase):
    __tablename__ = 'asset_photos'
    id = Column(Integer, primary_key=True)
    asset_id = Column(Integer, ForeignKey('assets.id'), nullable=False)
    filename = Column(String(200), nullable=False)
    original_filename = Column(String(200), nullable=False)
    uploaded_at = Column(Date, default=date.today)


class CardListTitle(RegistryBase):
    __tablename__ = 'card_list_titles'
    id = Column(Integer, primary_key=True)
    card_name = Column(String(200), nullable=False, unique=True)
    title = Column(String(200), default='')


class CardListItem(RegistryBase):
    __tablename__ = 'card_list_items'
    id = Column(Integer, primary_key=True)
    card_name = Column(String(200), nullable=False)
    text = Column(String(500), nullable=False)
    position = Column(Integer, default=0)


class CardPhoto(RegistryBase):
    __tablename__ = 'card_photos'
    id = Column(Integer, primary_key=True)
    card_name = Column(String(200), nullable=False)
    filename = Column(String(200), nullable=False)
    original_filename = Column(String(200), nullable=False)
    uploaded_at = Column(Date, default=date.today)


class Movement(RegistryBase):
    __tablename__ = 'movements'
    id = Column(Integer, primary_key=True)
    asset_id = Column(Integer, ForeignKey('assets.id'), nullable=False)
    date = Column(Date, nullable=False, default=date.today)
    movement_type = Column(String(20), nullable=False)
    from_location = Column(String(200))
    to_location = Column(String(200))
    reason = Column(String(300))
    document_number = Column(String(50))
    asset_rel = relationship('Asset', back_populates='movements')


class StatusLog(RegistryBase):
    __tablename__ = 'status_log'
    id = Column(Integer, primary_key=True)
    asset_id = Column(Integer, ForeignKey('assets.id'), nullable=False)
    old_status = Column(String(20))
    new_status = Column(String(20), nullable=False)
    changed_at = Column(Date, nullable=False, default=date.today)
    comment = Column(String(300))
    asset_rel = relationship('Asset', back_populates='status_logs')

Asset.status_logs = relationship('StatusLog', back_populates='asset_rel',
                                  order_by='StatusLog.changed_at.desc()')


def get_registry_session(db_path):
    engine = create_engine(f'sqlite:///{db_path}')
    RegistryBase.metadata.create_all(engine)
    _migrate_assets(engine)
    Session = sessionmaker(bind=engine)
    return Session()


def _migrate_assets(engine):
    inspector = inspect(engine)
    columns = {col['name'] for col in inspector.get_columns('assets')}
    new_cols = {
        'department': 'VARCHAR(200)', 'cipher': 'VARCHAR(100)',
        'serial_number': 'VARCHAR(100)', 'equipment_type': 'VARCHAR(100)',
        'quantity': 'INTEGER DEFAULT 1', 'unit': 'VARCHAR(50)',
        'indicator': 'VARCHAR(100)', 'inactive_date': 'DATE', 'resume_date': 'DATE',
        'status_date': 'DATE',
        'card': 'VARCHAR(200)',
        'is_deleted': 'BOOLEAN DEFAULT 0',
        'deleted_reason': 'TEXT',
        'deleted_at': 'DATE',
    }
    with engine.connect() as conn:
        for col_name, col_type in new_cols.items():
            if col_name not in columns:
                conn.execute(text(f'ALTER TABLE assets ADD COLUMN {col_name} {col_type}'))
        conn.commit()


def seed_categories(session):
    if session.query(Category).count() > 0:
        return
    names = ['Здания и сооружения', 'Машины и оборудование', 'Транспортные средства',
             'Вычислительная техника', 'Офисная мебель', 'Инструменты и приборы',
             'Производственный инвентарь', 'Прочие основные средства']
    for name in names:
        session.add(Category(name=name))
    session.commit()
