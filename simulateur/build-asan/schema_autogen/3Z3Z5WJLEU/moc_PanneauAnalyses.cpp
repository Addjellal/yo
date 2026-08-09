/****************************************************************************
** Meta object code from reading C++ file 'PanneauAnalyses.h'
**
** Created by: The Qt Meta Object Compiler version 68 (Qt 6.4.2)
**
** WARNING! All changes made in this file will be lost!
*****************************************************************************/

#include <memory>
#include "../../../src/app/panels/PanneauAnalyses.h"
#include <QtCore/qmetatype.h>
#include <QtCore/QList>
#if !defined(Q_MOC_OUTPUT_REVISION)
#error "The header file 'PanneauAnalyses.h' doesn't include <QObject>."
#elif Q_MOC_OUTPUT_REVISION != 68
#error "This file was generated using the moc from 6.4.2. It"
#error "cannot be used with the include files from this version of Qt."
#error "(The moc has changed too much.)"
#endif

#ifndef Q_CONSTINIT
#define Q_CONSTINIT
#endif

QT_BEGIN_MOC_NAMESPACE
QT_WARNING_PUSH
QT_WARNING_DISABLE_DEPRECATED
namespace {
struct qt_meta_stringdata_TraceCourbes_t {
    uint offsetsAndSizes[2];
    char stringdata0[13];
};
#define QT_MOC_LITERAL(ofs, len) \
    uint(sizeof(qt_meta_stringdata_TraceCourbes_t::offsetsAndSizes) + ofs), len 
Q_CONSTINIT static const qt_meta_stringdata_TraceCourbes_t qt_meta_stringdata_TraceCourbes = {
    {
        QT_MOC_LITERAL(0, 12)   // "TraceCourbes"
    },
    "TraceCourbes"
};
#undef QT_MOC_LITERAL
} // unnamed namespace

Q_CONSTINIT static const uint qt_meta_data_TraceCourbes[] = {

 // content:
      10,       // revision
       0,       // classname
       0,    0, // classinfo
       0,    0, // methods
       0,    0, // properties
       0,    0, // enums/sets
       0,    0, // constructors
       0,       // flags
       0,       // signalCount

       0        // eod
};

Q_CONSTINIT const QMetaObject TraceCourbes::staticMetaObject = { {
    QMetaObject::SuperData::link<QWidget::staticMetaObject>(),
    qt_meta_stringdata_TraceCourbes.offsetsAndSizes,
    qt_meta_data_TraceCourbes,
    qt_static_metacall,
    nullptr,
    qt_incomplete_metaTypeArray<qt_meta_stringdata_TraceCourbes_t,
        // Q_OBJECT / Q_GADGET
        QtPrivate::TypeAndForceComplete<TraceCourbes, std::true_type>
    >,
    nullptr
} };

void TraceCourbes::qt_static_metacall(QObject *_o, QMetaObject::Call _c, int _id, void **_a)
{
    (void)_o;
    (void)_id;
    (void)_c;
    (void)_a;
}

const QMetaObject *TraceCourbes::metaObject() const
{
    return QObject::d_ptr->metaObject ? QObject::d_ptr->dynamicMetaObject() : &staticMetaObject;
}

void *TraceCourbes::qt_metacast(const char *_clname)
{
    if (!_clname) return nullptr;
    if (!strcmp(_clname, qt_meta_stringdata_TraceCourbes.stringdata0))
        return static_cast<void*>(this);
    return QWidget::qt_metacast(_clname);
}

int TraceCourbes::qt_metacall(QMetaObject::Call _c, int _id, void **_a)
{
    _id = QWidget::qt_metacall(_c, _id, _a);
    return _id;
}
namespace {
struct qt_meta_stringdata_PanneauAnalyses_t {
    uint offsetsAndSizes[32];
    char stringdata0[16];
    char stringdata1[17];
    char stringdata2[1];
    char stringdata3[10];
    char stringdata4[5];
    char stringdata5[18];
    char stringdata6[10];
    char stringdata7[10];
    char stringdata8[14];
    char stringdata9[8];
    char stringdata10[20];
    char stringdata11[10];
    char stringdata12[8];
    char stringdata13[16];
    char stringdata14[7];
    char stringdata15[12];
};
#define QT_MOC_LITERAL(ofs, len) \
    uint(sizeof(qt_meta_stringdata_PanneauAnalyses_t::offsetsAndSizes) + ofs), len 
Q_CONSTINIT static const qt_meta_stringdata_PanneauAnalyses_t qt_meta_stringdata_PanneauAnalyses = {
    {
        QT_MOC_LITERAL(0, 15),  // "PanneauAnalyses"
        QT_MOC_LITERAL(16, 16),  // "balayage_demande"
        QT_MOC_LITERAL(33, 0),  // ""
        QT_MOC_LITERAL(34, 9),  // "directive"
        QT_MOC_LITERAL(44, 4),  // "bode"
        QT_MOC_LITERAL(49, 17),  // "campagne_demandee"
        QT_MOC_LITERAL(67, 9),  // "reference"
        QT_MOC_LITERAL(77, 9),  // "propriete"
        QT_MOC_LITERAL(87, 13),  // "QList<double>"
        QT_MOC_LITERAL(101, 7),  // "valeurs"
        QT_MOC_LITERAL(109, 19),  // "monte_carlo_demande"
        QT_MOC_LITERAL(129, 9),  // "tolerance"
        QT_MOC_LITERAL(139, 7),  // "tirages"
        QT_MOC_LITERAL(147, 15),  // "spectre_demande"
        QT_MOC_LITERAL(163, 6),  // "signal"
        QT_MOC_LITERAL(170, 11)   // "harmoniques"
    },
    "PanneauAnalyses",
    "balayage_demande",
    "",
    "directive",
    "bode",
    "campagne_demandee",
    "reference",
    "propriete",
    "QList<double>",
    "valeurs",
    "monte_carlo_demande",
    "tolerance",
    "tirages",
    "spectre_demande",
    "signal",
    "harmoniques"
};
#undef QT_MOC_LITERAL
} // unnamed namespace

Q_CONSTINIT static const uint qt_meta_data_PanneauAnalyses[] = {

 // content:
      10,       // revision
       0,       // classname
       0,    0, // classinfo
       4,   14, // methods
       0,    0, // properties
       0,    0, // enums/sets
       0,    0, // constructors
       0,       // flags
       4,       // signalCount

 // signals: name, argc, parameters, tag, flags, initial metatype offsets
       1,    2,   38,    2, 0x06,    1 /* Public */,
       5,    5,   43,    2, 0x06,    4 /* Public */,
      10,    4,   54,    2, 0x06,   10 /* Public */,
      13,    2,   63,    2, 0x06,   15 /* Public */,

 // signals: parameters
    QMetaType::Void, QMetaType::QString, QMetaType::Bool,    3,    4,
    QMetaType::Void, QMetaType::QString, QMetaType::QString, 0x80000000 | 8, QMetaType::QString, QMetaType::Bool,    6,    7,    9,    3,    4,
    QMetaType::Void, QMetaType::Double, QMetaType::Int, QMetaType::QString, QMetaType::Bool,   11,   12,    3,    4,
    QMetaType::Void, QMetaType::QString, QMetaType::Int,   14,   15,

       0        // eod
};

Q_CONSTINIT const QMetaObject PanneauAnalyses::staticMetaObject = { {
    QMetaObject::SuperData::link<QWidget::staticMetaObject>(),
    qt_meta_stringdata_PanneauAnalyses.offsetsAndSizes,
    qt_meta_data_PanneauAnalyses,
    qt_static_metacall,
    nullptr,
    qt_incomplete_metaTypeArray<qt_meta_stringdata_PanneauAnalyses_t,
        // Q_OBJECT / Q_GADGET
        QtPrivate::TypeAndForceComplete<PanneauAnalyses, std::true_type>,
        // method 'balayage_demande'
        QtPrivate::TypeAndForceComplete<void, std::false_type>,
        QtPrivate::TypeAndForceComplete<const QString &, std::false_type>,
        QtPrivate::TypeAndForceComplete<bool, std::false_type>,
        // method 'campagne_demandee'
        QtPrivate::TypeAndForceComplete<void, std::false_type>,
        QtPrivate::TypeAndForceComplete<const QString &, std::false_type>,
        QtPrivate::TypeAndForceComplete<const QString &, std::false_type>,
        QtPrivate::TypeAndForceComplete<const QVector<double> &, std::false_type>,
        QtPrivate::TypeAndForceComplete<const QString &, std::false_type>,
        QtPrivate::TypeAndForceComplete<bool, std::false_type>,
        // method 'monte_carlo_demande'
        QtPrivate::TypeAndForceComplete<void, std::false_type>,
        QtPrivate::TypeAndForceComplete<double, std::false_type>,
        QtPrivate::TypeAndForceComplete<int, std::false_type>,
        QtPrivate::TypeAndForceComplete<const QString &, std::false_type>,
        QtPrivate::TypeAndForceComplete<bool, std::false_type>,
        // method 'spectre_demande'
        QtPrivate::TypeAndForceComplete<void, std::false_type>,
        QtPrivate::TypeAndForceComplete<const QString &, std::false_type>,
        QtPrivate::TypeAndForceComplete<int, std::false_type>
    >,
    nullptr
} };

void PanneauAnalyses::qt_static_metacall(QObject *_o, QMetaObject::Call _c, int _id, void **_a)
{
    if (_c == QMetaObject::InvokeMetaMethod) {
        auto *_t = static_cast<PanneauAnalyses *>(_o);
        (void)_t;
        switch (_id) {
        case 0: _t->balayage_demande((*reinterpret_cast< std::add_pointer_t<QString>>(_a[1])),(*reinterpret_cast< std::add_pointer_t<bool>>(_a[2]))); break;
        case 1: _t->campagne_demandee((*reinterpret_cast< std::add_pointer_t<QString>>(_a[1])),(*reinterpret_cast< std::add_pointer_t<QString>>(_a[2])),(*reinterpret_cast< std::add_pointer_t<QList<double>>>(_a[3])),(*reinterpret_cast< std::add_pointer_t<QString>>(_a[4])),(*reinterpret_cast< std::add_pointer_t<bool>>(_a[5]))); break;
        case 2: _t->monte_carlo_demande((*reinterpret_cast< std::add_pointer_t<double>>(_a[1])),(*reinterpret_cast< std::add_pointer_t<int>>(_a[2])),(*reinterpret_cast< std::add_pointer_t<QString>>(_a[3])),(*reinterpret_cast< std::add_pointer_t<bool>>(_a[4]))); break;
        case 3: _t->spectre_demande((*reinterpret_cast< std::add_pointer_t<QString>>(_a[1])),(*reinterpret_cast< std::add_pointer_t<int>>(_a[2]))); break;
        default: ;
        }
    } else if (_c == QMetaObject::RegisterMethodArgumentMetaType) {
        switch (_id) {
        default: *reinterpret_cast<QMetaType *>(_a[0]) = QMetaType(); break;
        case 1:
            switch (*reinterpret_cast<int*>(_a[1])) {
            default: *reinterpret_cast<QMetaType *>(_a[0]) = QMetaType(); break;
            case 2:
                *reinterpret_cast<QMetaType *>(_a[0]) = QMetaType::fromType< QList<double> >(); break;
            }
            break;
        }
    } else if (_c == QMetaObject::IndexOfMethod) {
        int *result = reinterpret_cast<int *>(_a[0]);
        {
            using _t = void (PanneauAnalyses::*)(const QString & , bool );
            if (_t _q_method = &PanneauAnalyses::balayage_demande; *reinterpret_cast<_t *>(_a[1]) == _q_method) {
                *result = 0;
                return;
            }
        }
        {
            using _t = void (PanneauAnalyses::*)(const QString & , const QString & , const QVector<double> & , const QString & , bool );
            if (_t _q_method = &PanneauAnalyses::campagne_demandee; *reinterpret_cast<_t *>(_a[1]) == _q_method) {
                *result = 1;
                return;
            }
        }
        {
            using _t = void (PanneauAnalyses::*)(double , int , const QString & , bool );
            if (_t _q_method = &PanneauAnalyses::monte_carlo_demande; *reinterpret_cast<_t *>(_a[1]) == _q_method) {
                *result = 2;
                return;
            }
        }
        {
            using _t = void (PanneauAnalyses::*)(const QString & , int );
            if (_t _q_method = &PanneauAnalyses::spectre_demande; *reinterpret_cast<_t *>(_a[1]) == _q_method) {
                *result = 3;
                return;
            }
        }
    }
}

const QMetaObject *PanneauAnalyses::metaObject() const
{
    return QObject::d_ptr->metaObject ? QObject::d_ptr->dynamicMetaObject() : &staticMetaObject;
}

void *PanneauAnalyses::qt_metacast(const char *_clname)
{
    if (!_clname) return nullptr;
    if (!strcmp(_clname, qt_meta_stringdata_PanneauAnalyses.stringdata0))
        return static_cast<void*>(this);
    return QWidget::qt_metacast(_clname);
}

int PanneauAnalyses::qt_metacall(QMetaObject::Call _c, int _id, void **_a)
{
    _id = QWidget::qt_metacall(_c, _id, _a);
    if (_id < 0)
        return _id;
    if (_c == QMetaObject::InvokeMetaMethod) {
        if (_id < 4)
            qt_static_metacall(this, _c, _id, _a);
        _id -= 4;
    } else if (_c == QMetaObject::RegisterMethodArgumentMetaType) {
        if (_id < 4)
            qt_static_metacall(this, _c, _id, _a);
        _id -= 4;
    }
    return _id;
}

// SIGNAL 0
void PanneauAnalyses::balayage_demande(const QString & _t1, bool _t2)
{
    void *_a[] = { nullptr, const_cast<void*>(reinterpret_cast<const void*>(std::addressof(_t1))), const_cast<void*>(reinterpret_cast<const void*>(std::addressof(_t2))) };
    QMetaObject::activate(this, &staticMetaObject, 0, _a);
}

// SIGNAL 1
void PanneauAnalyses::campagne_demandee(const QString & _t1, const QString & _t2, const QVector<double> & _t3, const QString & _t4, bool _t5)
{
    void *_a[] = { nullptr, const_cast<void*>(reinterpret_cast<const void*>(std::addressof(_t1))), const_cast<void*>(reinterpret_cast<const void*>(std::addressof(_t2))), const_cast<void*>(reinterpret_cast<const void*>(std::addressof(_t3))), const_cast<void*>(reinterpret_cast<const void*>(std::addressof(_t4))), const_cast<void*>(reinterpret_cast<const void*>(std::addressof(_t5))) };
    QMetaObject::activate(this, &staticMetaObject, 1, _a);
}

// SIGNAL 2
void PanneauAnalyses::monte_carlo_demande(double _t1, int _t2, const QString & _t3, bool _t4)
{
    void *_a[] = { nullptr, const_cast<void*>(reinterpret_cast<const void*>(std::addressof(_t1))), const_cast<void*>(reinterpret_cast<const void*>(std::addressof(_t2))), const_cast<void*>(reinterpret_cast<const void*>(std::addressof(_t3))), const_cast<void*>(reinterpret_cast<const void*>(std::addressof(_t4))) };
    QMetaObject::activate(this, &staticMetaObject, 2, _a);
}

// SIGNAL 3
void PanneauAnalyses::spectre_demande(const QString & _t1, int _t2)
{
    void *_a[] = { nullptr, const_cast<void*>(reinterpret_cast<const void*>(std::addressof(_t1))), const_cast<void*>(reinterpret_cast<const void*>(std::addressof(_t2))) };
    QMetaObject::activate(this, &staticMetaObject, 3, _a);
}
QT_WARNING_POP
QT_END_MOC_NAMESPACE
