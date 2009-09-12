#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include "hook_op_check.h"

STATIC OP *
range_replace(pTHX_ OP *op, void *user_data) {
    op_dump(op);

    return op;
}

MODULE = PerlX::Range		PACKAGE = PerlX::Range

PROTOTYPES: DISABLE

void
import(SV *args)
CODE:
    hook_op_check(OP_FLOP, range_replace, NULL);
