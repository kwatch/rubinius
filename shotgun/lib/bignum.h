#ifndef RBS_BIGNUM_H
#define RBS_BIGNUM_H
#include <tommath.h>

void bignum_debug(STATE, OBJECT n);
OBJECT bignum_new(STATE, native_int num);
OBJECT bignum_new_unsigned(STATE, unsigned int num);
OBJECT bignum_add(STATE, OBJECT a, OBJECT b);
OBJECT bignum_sub(STATE, OBJECT a, OBJECT b);
OBJECT bignum_mul(STATE, OBJECT a, OBJECT b);
OBJECT bignum_div(STATE, OBJECT a, OBJECT b, mp_int *mod);
OBJECT bignum_mod(STATE, OBJECT a, OBJECT b);
OBJECT bignum_equal(STATE, OBJECT a, OBJECT b);
OBJECT bignum_compare(STATE, OBJECT a, OBJECT b);
OBJECT bignum_gt(STATE, OBJECT a, OBJECT b);
OBJECT bignum_ge(STATE, OBJECT a, OBJECT b);
OBJECT bignum_lt(STATE, OBJECT a, OBJECT b);
OBJECT bignum_le(STATE, OBJECT a, OBJECT b);
OBJECT bignum_and(STATE, OBJECT a, OBJECT b);
OBJECT bignum_or(STATE, OBJECT a, OBJECT b);
OBJECT bignum_xor(STATE, OBJECT a, OBJECT b);
OBJECT bignum_neg(STATE, OBJECT self);
OBJECT bignum_invert(STATE, OBJECT self);
unsigned long bignum_to_int(STATE, OBJECT self);
OBJECT bignum_to_s(STATE, OBJECT self, OBJECT radix);
void bignum_into_string(STATE, OBJECT self, int radix, char *buf, int sz);
OBJECT bignum_from_string(STATE, char *str, int radix);
OBJECT bignum_from_string_detect(STATE, char *str);
double bignum_to_double(STATE, OBJECT self);
OBJECT bignum_from_double(STATE, double d);
OBJECT bignum_left_shift(STATE, OBJECT self, OBJECT bits);
OBJECT bignum_right_shift(STATE, OBJECT self, OBJECT bits);
OBJECT bignum_divmod(STATE, OBJECT a, OBJECT b);
unsigned long long bignum_to_ull(STATE, OBJECT self);
long long bignum_to_ll(STATE, OBJECT self);
OBJECT bignum_from_ull(STATE, unsigned long long val);
OBJECT bignum_from_ll(STATE, long long val);
OBJECT bignum_size(STATE, OBJECT self);
int bignum_is_zero(STATE, OBJECT a);
int bignum_hash_int(OBJECT a);
unsigned int bignum_to_ui(STATE, OBJECT self);
int bignum_to_i(STATE, OBJECT self);

/* initialize and set a long integer value */
int mp_init_set_long (mp_int * a, unsigned long b);
int mp_set_long (mp_int * a, unsigned long b);

#endif
