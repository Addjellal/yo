/****************************************************************************
** Meta object code from reading C++ file 'MoteurSimulation.h'
**
** Created by: The Qt Meta Object Compiler version 68 (Qt 6.4.2)
**
** WARNING! All changes made in this file will be lost!
*****************************************************************************/

#include <memory>
#include "../../../src/app/MoteurSimulation.h"
#include <QtCore/qmetatype.h>
#if !defined(Q_MOC_OUTPUT_REVISION)
#error "The header file 'MoteurSimulation.h' doesn't include <QObject>."
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
struct qt_meta_stringdata_MoteurSimulation_t {
    uint offsetsAndSizes[50];
    char stringdata0[17];
    char stringdata1[10];
    char stringdata2[1];
    char stringdata3[29];
    char stringdata4[9];
    char stringdata5[9];
    char stringdata6[15];
    char stringdata7[14];
    char stringdata8[7];
    char stringdata9[14];
    char stringdata10[12];
    char stringdata11[6];
    char stringdata12[6];
    char stringdata13[17];
    char stringdata14[51];
    char stringdata15[6];
    char stringdata16[8];
    char stringdata17[8];
    char stringdata18[11];
    char stringdata19[9];
    char stringdata20[8];
    char stringdata21[12];
    char stringdata22[5];
    char stringdata23[5];
    char stringdata24[6];
};
#define QT_MOC_LITERAL(ofs, len) \
    uint(sizeof(qt_meta_stringdata_MoteurSimulation_t::offsetsAndSizes) + ofs), len 
Q_CONSTINIT static const qt_meta_stringdata_MoteurSimulation_t qt_meta_stringdata_MoteurSimulation = {
    {
        QT_MOC_LITERAL(0, 16),  // "MoteurSimulation"
        QT_MOC_LITERAL(17, 9),  // "resultats"
        QT_MOC_LITERAL(27, 0),  // ""
        QT_MOC_LITERAL(28, 28),  // "std::map<std::string,double>"
        QT_MOC_LITERAL(57, 8),  // "courants"
        QT_MOC_LITERAL(66, 8),  // "tensions"
        QT_MOC_LITERAL(75, 14),  // "trame_calculee"
        QT_MOC_LITERAL(90, 13),  // "coeur::Formes"
        QT_MOC_LITERAL(104, 6),  // "formes"
        QT_MOC_LITERAL(111, 13),  // "instant_debut"
        QT_MOC_LITERAL(125, 11),  // "octet_serie"
        QT_MOC_LITERAL(137, 5),  // "octet"
        QT_MOC_LITERAL(143, 5),  // "carte"
        QT_MOC_LITERAL(149, 16),  // "etats_composants"
        QT_MOC_LITERAL(166, 50),  // "std::map<std::string,std::map..."
        QT_MOC_LITERAL(217, 5),  // "etats"
        QT_MOC_LITERAL(223, 7),  // "journal"
        QT_MOC_LITERAL(231, 7),  // "message"
        QT_MOC_LITERAL(239, 10),  // "avancement"
        QT_MOC_LITERAL(250, 8),  // "temps_ms"
        QT_MOC_LITERAL(259, 7),  // "vitesse"
        QT_MOC_LITERAL(267, 11),  // "etat_change"
        QT_MOC_LITERAL(279, 4),  // "Etat"
        QT_MOC_LITERAL(284, 4),  // "etat"
        QT_MOC_LITERAL(289, 5)   // "trame"
    },
    "MoteurSimulation",
    "resultats",
    "",
    "std::map<std::string,double>",
    "courants",
    "tensions",
    "trame_calculee",
    "coeur::Formes",
    "formes",
    "instant_debut",
    "octet_serie",
    "octet",
    "carte",
    "etats_composants",
    "std::map<std::string,std::map<std::string,double>>",
    "etats",
    "journal",
    "message",
    "avancement",
    "temps_ms",
    "vitesse",
    "etat_change",
    "Etat",
    "etat",
    "trame"
};
#undef QT_MOC_LITERAL
} // unnamed namespace

Q_CONSTINIT static const uint qt_meta_data_MoteurSimulation[] = {

 // content:
      10,       // revision
       0,       // classname
       0,    0, // classinfo
       8,   14, // methods
       0,    0, // properties
       0,    0, // enums/sets
       0,    0, // constructors
       0,       // flags
       7,       // signalCount

 // signals: name, argc, parameters, tag, flags, initial metatype offsets
       1,    2,   62,    2, 0x06,    1 /* Public */,
       6,    2,   67,    2, 0x06,    4 /* Public */,
      10,    2,   72,    2, 0x06,    7 /* Public */,
      13,    1,   77,    2, 0x06,   10 /* Public */,
      16,    1,   80,    2, 0x06,   12 /* Public */,
      18,    2,   83,    2, 0x06,   14 /* Public */,
      21,    1,   88,    2, 0x06,   17 /* Public */,

 // slots: name, argc, parameters, tag, flags, initial metatype offsets
      24,    0,   91,    2, 0x08,   19 /* Private */,

 // signals: parameters
    QMetaType::Void, 0x80000000 | 3, 0x80000000 | 3,    4,    5,
    QMetaType::Void, 0x80000000 | 7, QMetaType::Double,    8,    9,
    QMetaType::Void, QMetaType::Char, QMetaType::QString,   11,   12,
    QMetaType::Void, 0x80000000 | 14,   15,
    QMetaType::Void, QMetaType::QString,   17,
    QMetaType::Void, QMetaType::Double, QMetaType::Double,   19,   20,
    QMetaType::Void, 0x80000000 | 22,   23,

 // slots: parameters
    QMetaType::Void,

       0        // eod
};

Q_CONSTINIT const QMetaObject MoteurSimulation::staticMetaObject = { {
    QMetaObject::SuperData::link<QObject::staticMetaObject>(),
    qt_meta_stringdata_MoteurSimulation.offsetsAndSizes,
    qt_meta_data_MoteurSimulation,
    qt_static_metacall,
    nullptr,
    qt_incomplete_metaTypeArray<qt_meta_stringdata_MoteurSimulation_t,
        // Q_OBJECT / Q_GADGET
        QtPrivate::TypeAndForceComplete<MoteurSimulation, std::true_type>,
        // method 'resultats'
        QtPrivate::TypeAndForceComplete<void, std::false_type>,
        QtPrivate::TypeAndForceComplete<const std::map<std::string,double> &, std::false_type>,
        QtPrivate::TypeAndForceComplete<const std::map<std::string,double> &, std::false_type>,
        // method 'trame_calculee'
        QtPrivate::TypeAndForceComplete<void, std::false_type>,
        QtPrivate::TypeAndForceComplete<const coeur::Formes &, std::false_type>,
        QtPrivate::TypeAndForceComplete<double, std::false_type>,
        // method 'octet_serie'
        QtPrivate::TypeAndForceComplete<void, std::false_type>,
        QtPrivate::TypeAndForceComplete<char, std::false_type>,
        QtPrivate::TypeAndForceComplete<const QString &, std::false_type>,
        // method 'etats_composants'
        QtPrivate::TypeAndForceComplete<void, std::false_type>,
        QtPrivate::TypeAndForceComplete<const std::map<std::string,std::map<std::string,double>> &, std::false_type>,
        // method 'journal'
        QtPrivate::TypeAndForceComplete<void, std::false_type>,
        QtPrivate::TypeAndForceComplete<const QString &, std::false_type>,
        // method 'avancement'
        QtPrivate::TypeAndForceComplete<void, std::false_type>,
        QtPrivate::TypeAndForceComplete<double, std::false_type>,
        QtPrivate::TypeAndForceComplete<double, std::false_type>,
        // method 'etat_change'
        QtPrivate::TypeAndForceComplete<void, std::false_type>,
        QtPrivate::TypeAndForceComplete<Etat, std::false_type>,
        // method 'trame'
        QtPrivate::TypeAndForceComplete<void, std::false_type>
    >,
    nullptr
} };

void MoteurSimulation::qt_static_metacall(QObject *_o, QMetaObject::Call _c, int _id, void **_a)
{
    if (_c == QMetaObject::InvokeMetaMethod) {
        auto *_t = static_cast<MoteurSimulation *>(_o);
        (void)_t;
        switch (_id) {
        case 0: _t->resultats((*reinterpret_cast< std::add_pointer_t<std::map<std::string,double>>>(_a[1])),(*reinterpret_cast< std::add_pointer_t<std::map<std::string,double>>>(_a[2]))); break;
        case 1: _t->trame_calculee((*reinterpret_cast< std::add_pointer_t<coeur::Formes>>(_a[1])),(*reinterpret_cast< std::add_pointer_t<double>>(_a[2]))); break;
        case 2: _t->octet_serie((*reinterpret_cast< std::add_pointer_t<char>>(_a[1])),(*reinterpret_cast< std::add_pointer_t<QString>>(_a[2]))); break;
        case 3: _t->etats_composants((*reinterpret_cast< std::add_pointer_t<std::map<std::string,std::map<std::string,double>>>>(_a[1]))); break;
        case 4: _t->journal((*reinterpret_cast< std::add_pointer_t<QString>>(_a[1]))); break;
        case 5: _t->avancement((*reinterpret_cast< std::add_pointer_t<double>>(_a[1])),(*reinterpret_cast< std::add_pointer_t<double>>(_a[2]))); break;
        case 6: _t->etat_change((*reinterpret_cast< std::add_pointer_t<Etat>>(_a[1]))); break;
        case 7: _t->trame(); break;
        default: ;
        }
    } else if (_c == QMetaObject::IndexOfMethod) {
        int *result = reinterpret_cast<int *>(_a[0]);
        {
            using _t = void (MoteurSimulation::*)(const std::map<std::string,double> & , const std::map<std::string,double> & );
            if (_t _q_method = &MoteurSimulation::resultats; *reinterpret_cast<_t *>(_a[1]) == _q_method) {
                *result = 0;
                return;
            }
        }
        {
            using _t = void (MoteurSimulation::*)(const coeur::Formes & , double );
            if (_t _q_method = &MoteurSimulation::trame_calculee; *reinterpret_cast<_t *>(_a[1]) == _q_method) {
                *result = 1;
                return;
            }
        }
        {
            using _t = void (MoteurSimulation::*)(char , const QString & );
            if (_t _q_method = &MoteurSimulation::octet_serie; *reinterpret_cast<_t *>(_a[1]) == _q_method) {
                *result = 2;
                return;
            }
        }
        {
            using _t = void (MoteurSimulation::*)(const std::map<std::string,std::map<std::string,double>> & );
            if (_t _q_method = &MoteurSimulation::etats_composants; *reinterpret_cast<_t *>(_a[1]) == _q_method) {
                *result = 3;
                return;
            }
        }
        {
            using _t = void (MoteurSimulation::*)(const QString & );
            if (_t _q_method = &MoteurSimulation::journal; *reinterpret_cast<_t *>(_a[1]) == _q_method) {
                *result = 4;
                return;
            }
        }
        {
            using _t = void (MoteurSimulation::*)(double , double );
            if (_t _q_method = &MoteurSimulation::avancement; *reinterpret_cast<_t *>(_a[1]) == _q_method) {
                *result = 5;
                return;
            }
        }
        {
            using _t = void (MoteurSimulation::*)(Etat );
            if (_t _q_method = &MoteurSimulation::etat_change; *reinterpret_cast<_t *>(_a[1]) == _q_method) {
                *result = 6;
                return;
            }
        }
    }
}

const QMetaObject *MoteurSimulation::metaObject() const
{
    return QObject::d_ptr->metaObject ? QObject::d_ptr->dynamicMetaObject() : &staticMetaObject;
}

void *MoteurSimulation::qt_metacast(const char *_clname)
{
    if (!_clname) return nullptr;
    if (!strcmp(_clname, qt_meta_stringdata_MoteurSimulation.stringdata0))
        return static_cast<void*>(this);
    return QObject::qt_metacast(_clname);
}

int MoteurSimulation::qt_metacall(QMetaObject::Call _c, int _id, void **_a)
{
    _id = QObject::qt_metacall(_c, _id, _a);
    if (_id < 0)
        return _id;
    if (_c == QMetaObject::InvokeMetaMethod) {
        if (_id < 8)
            qt_static_metacall(this, _c, _id, _a);
        _id -= 8;
    } else if (_c == QMetaObject::RegisterMethodArgumentMetaType) {
        if (_id < 8)
            *reinterpret_cast<QMetaType *>(_a[0]) = QMetaType();
        _id -= 8;
    }
    return _id;
}

// SIGNAL 0
void MoteurSimulation::resultats(const std::map<std::string,double> & _t1, const std::map<std::string,double> & _t2)
{
    void *_a[] = { nullptr, const_cast<void*>(reinterpret_cast<const void*>(std::addressof(_t1))), const_cast<void*>(reinterpret_cast<const void*>(std::addressof(_t2))) };
    QMetaObject::activate(this, &staticMetaObject, 0, _a);
}

// SIGNAL 1
void MoteurSimulation::trame_calculee(const coeur::Formes & _t1, double _t2)
{
    void *_a[] = { nullptr, const_cast<void*>(reinterpret_cast<const void*>(std::addressof(_t1))), const_cast<void*>(reinterpret_cast<const void*>(std::addressof(_t2))) };
    QMetaObject::activate(this, &staticMetaObject, 1, _a);
}

// SIGNAL 2
void MoteurSimulation::octet_serie(char _t1, const QString & _t2)
{
    void *_a[] = { nullptr, const_cast<void*>(reinterpret_cast<const void*>(std::addressof(_t1))), const_cast<void*>(reinterpret_cast<const void*>(std::addressof(_t2))) };
    QMetaObject::activate(this, &staticMetaObject, 2, _a);
}

// SIGNAL 3
void MoteurSimulation::etats_composants(const std::map<std::string,std::map<std::string,double>> & _t1)
{
    void *_a[] = { nullptr, const_cast<void*>(reinterpret_cast<const void*>(std::addressof(_t1))) };
    QMetaObject::activate(this, &staticMetaObject, 3, _a);
}

// SIGNAL 4
void MoteurSimulation::journal(const QString & _t1)
{
    void *_a[] = { nullptr, const_cast<void*>(reinterpret_cast<const void*>(std::addressof(_t1))) };
    QMetaObject::activate(this, &staticMetaObject, 4, _a);
}

// SIGNAL 5
void MoteurSimulation::avancement(double _t1, double _t2)
{
    void *_a[] = { nullptr, const_cast<void*>(reinterpret_cast<const void*>(std::addressof(_t1))), const_cast<void*>(reinterpret_cast<const void*>(std::addressof(_t2))) };
    QMetaObject::activate(this, &staticMetaObject, 5, _a);
}

// SIGNAL 6
void MoteurSimulation::etat_change(Etat _t1)
{
    void *_a[] = { nullptr, const_cast<void*>(reinterpret_cast<const void*>(std::addressof(_t1))) };
    QMetaObject::activate(this, &staticMetaObject, 6, _a);
}
QT_WARNING_POP
QT_END_MOC_NAMESPACE
