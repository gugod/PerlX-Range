#define PERL_CORE

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include "hook_op_check.h"

STATIC OP *
range_replace(pTHX_ OP *op, void *user_data) {
  UNOP *entersub_op;
  LISTOP *entersub_args = NULL;
  SVOP *min_const_op;
  SVOP *max_const_op;
  GV *xrange;
  UNOP *xrange_op;
  I32 min_val;
  I32 max_val;

  if ( cUNOPx(op)->op_first->op_type != OP_FLIP) return op;
  if ( cUNOPx(cUNOPx(op)->op_first)->op_first->op_type != OP_RANGE ) return op;

  min_val = SvIV(cSVOPx(cLOGOPx(cUNOPx(cUNOPx(op)->op_first)->op_first)->op_first)->op_sv);
  max_val = SvIV(cSVOPx(cLOGOPx(cUNOPx(cUNOPx(op)->op_first)->op_first)->op_other)->op_sv);

  min_const_op = newSVOP(OP_CONST, 0, newSViv(min_val));
  max_const_op = newSVOP(OP_CONST, 0, newSViv(max_val));

  xrange = gv_fetchpvs("PerlX::Range::xrange", 1, SVt_PVCV);

  xrange_op = scalar(newUNOP(OP_RV2CV, 0, newGVOP(OP_GV, 0, xrange)));

  entersub_args = append_elem(OP_LIST, entersub_args, min_const_op);
  entersub_args = append_elem(OP_LIST, entersub_args, max_const_op);
  entersub_args = append_elem(OP_LIST, entersub_args, xrange_op);

  entersub_op   = newUNOP(OP_ENTERSUB, OPf_STACKED, min_const_op);
  return entersub_op;
}

MODULE = PerlX::Range		PACKAGE = PerlX::Range

PROTOTYPES: DISABLE

void
import(SV *args)
CODE:
    hook_op_check(OP_FLOP, range_replace, NULL);
