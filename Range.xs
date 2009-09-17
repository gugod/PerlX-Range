#define PERL_CORE

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include "hook_op_check.h"

STATIC OP *
range_replace(pTHX_ OP *op, void *user_data) {
  GV *xrange;
  UNOP *entersub_op, *xrange_op;
  SVOP *min_const_op, *max_const_op;
  SV *min_val, *max_val;
  LISTOP *entersub_args = NULL;

  // Make sure that the %^H is localized
  if ((PL_hints & 0x00020000) != 0x00020000) {
    return op;
  }

  // Range.pm should properly set $^H{PerlXRange} to 1 to toggle the
  // effectiveness of PerlX::Range
  if (!hv_exists(GvHV(PL_hintgv), "PerlXRange", 10)) {
    return op;
  }

  if ( cUNOPx(op)->op_first->op_type != OP_FLIP) return op;
  if ( cUNOPx(cUNOPx(op)->op_first)->op_first->op_type != OP_RANGE ) return op;

#define ORIGINAL_RANGE_OP cLOGOPx(cUNOPx(cUNOPx(op)->op_first)->op_first)

  min_val = newSVsv(cSVOPx( ORIGINAL_RANGE_OP->op_first )->op_sv);
  max_val = newSVsv(cSVOPx( ORIGINAL_RANGE_OP->op_other )->op_sv);

#undef ORIGINAL_RANGE_OP

  min_const_op = (SVOP*)newSVOP(OP_CONST, 0, min_val);
  max_const_op = (SVOP*)newSVOP(OP_CONST, 0, max_val);

  xrange = gv_fetchpvs("PerlX::Range::xrange", 1, SVt_PVCV);

  xrange_op = (UNOP*)scalar(newUNOP(OP_RV2CV, 0, newGVOP(OP_GV, 0, xrange)));

  entersub_args = (LISTOP*)append_elem(OP_LIST, (OP*)entersub_args, (OP*)min_const_op);
  entersub_args = (LISTOP*)append_elem(OP_LIST, (OP*)entersub_args, (OP*)max_const_op);
  entersub_args = (LISTOP*)append_elem(OP_LIST, (OP*)entersub_args, (OP*)xrange_op);

  entersub_op   = (UNOP*)newUNOP(OP_ENTERSUB, OPf_STACKED, (OP*)min_const_op);
  return (OP*)entersub_op;
}

STATIC hook_op_check_id perlx_range_flop_hook_id = 0;

MODULE = PerlX::Range		PACKAGE = PerlX::Range

PROTOTYPES: DISABLE

void
add_flop_hook()
CODE:
    perlx_range_flop_hook_id = hook_op_check(OP_FLOP, range_replace, NULL);

void
remove_flop_hook()
CODE:
    hook_op_check_remove(OP_FLOP, perlx_range_flop_hook_id);
