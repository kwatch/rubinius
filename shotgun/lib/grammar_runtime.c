#include <string.h>

#include "shotgun/lib/shotgun.h"
#include "shotgun/lib/grammar_internal.h"
#include "shotgun/lib/array.h"
#include "shotgun/lib/string.h"
#include "shotgun/lib/tuple.h"
#include "shotgun/lib/bignum.h"
#include "shotgun/lib/symbol.h"
#include "shotgun/lib/grammar.h"

static OBJECT float_from_bstring(STATE, bstring str)
{
	return float_from_string(state, bdata(str));
}

static OBJECT bignum_from_bstring_detect(STATE, bstring str)
{
	return bignum_from_string_detect(state, bdata(str));
}
static OBJECT bignum_from_bstring(STATE, bstring str, int radix)
{
	return bignum_from_string(state, bdata(str), radix);
}

rb_parse_state *alloc_parse_state() {
    rb_parse_state *parse_state = (rb_parse_state*)calloc(1, sizeof(rb_parse_state));

    #undef command_start
    #undef class_nest
    #undef in_single
    #undef in_def
    #undef compile_for_eval
    #undef cur_mid
    #undef tokidx
    #undef toksiz
    parse_state->command_start = TRUE;
    parse_state->class_nest = 0;
    parse_state->in_single = 0;
    parse_state->in_def = 0;
    parse_state->compile_for_eval = 0;
    parse_state->cur_mid = 0;
    parse_state->token_buffer = NULL;
    parse_state->tokidx = 0;
    parse_state->toksiz = 0;
    parse_state->comments = 0;
    parse_state->memory_cur = NULL;
    parse_state->memory_last_addr = NULL;
    parse_state->current_pool = 0;
    parse_state->pool_size = 0;
    parse_state->memory_size = 204800;
    parse_state->memory_pools = NULL;
    parse_state->emit_warnings = 0;

    return parse_state;
}

void compile_error(const char *);

void *pt_allocate(rb_parse_state *st, int size) {
  void *cur;
  
  if(!st->memory_cur || ((st->memory_cur + size) >= st->memory_last_addr)) {
    if(st->memory_cur) st->current_pool++;

    if(st->current_pool == st->pool_size) {
      st->pool_size += 10;
      if(st->memory_pools) {
        st->memory_pools = (void**)realloc(st->memory_pools, sizeof(void*) * st->pool_size);
      } else {
        st->memory_pools = (void**)malloc(sizeof(void*) * st->pool_size);
      }
    }
    st->memory_pools[st->current_pool] = malloc(st->memory_size);
    st->memory_cur = st->memory_pools[st->current_pool];
    memset(st->memory_cur, 0, st->memory_size);
    st->memory_last_addr = st->memory_cur + st->memory_size - 1;
  }
  
  cur = (void*)st->memory_cur;
  st->memory_cur = st->memory_cur + size;
  
  return cur;
}

void pt_free(rb_parse_state *st) {
  int i;

  if(st->line_buffer) {
    bdestroy(st->line_buffer);
  }

  if(st->lex_lastline) {
	bdestroy(st->lex_lastline);
  }

  free(st->token_buffer);
  var_table_destroy(st->variables);

  if(!st->memory_pools) return;
  
  for(i = 0; i <= st->current_pool; i++) {
    free(st->memory_pools[i]);
  }
  free(st->memory_pools);
}

extern int syd_sourceline;

void create_error(rb_parse_state *parse_state, char *msg) {
  int col;
  STATE;
  OBJECT tup;
  
  state = parse_state->state;
  
  col = parse_state->lex_p - parse_state->lex_pbeg;
  
  tup = tuple_new(state, 4);
  tuple_put(state, tup, 0, string_new(state, msg));
  tuple_put(state, tup, 1, I2N(col));
  tuple_put(state, tup, 2, I2N(syd_sourceline));
  tuple_put(state, tup, 3, string_newfrombstr(state, parse_state->lex_lastline));
  parse_state->error = tup;
}

/* 
 *
 * 100% of the credit for the following node tree => sexp transform goes
 * to Ryan Davis (zenspider) and Eric Hodel (drbrain).
 *
 * It was mearly imported into this space by Evan Webb.
 */

#define nd_3rd   u3.node


// #define ADD_LINE if(node && RTEST(line_numbers)) { array_push(current, INT2NUM(nd_line(node))); }
#define ADD_LINE

#define VALUE OBJECT

#define array_push(ary, val) array_append(state, ary, val)
#define add_to_parse_tree(a,n,i,l,m) syd_add_to_parse_tree(state,a,n,i,l,m)
#undef ID2SYM
#define Q2SYM(v) quark_to_symbol(state, v)
#define SYMBOL(str) cstring_to_symbol(state, str)

static OBJECT cstring_to_symbol(STATE, const char *str) {
  return symtbl_lookup_cstr(state, state->global->symbols, str);
}

const char *op_to_name(ID id);

#if 0
static const char* print_quark(quark quark) {
  return quark_to_string(id_to_quark(quark));
}
#endif

static OBJECT quark_to_symbol(STATE, quark quark) {
  const char *op;
  op = op_to_name(quark);
  if(op) {
    return cstring_to_symbol(state, op);
  }
  return cstring_to_symbol(state, quark_to_string(id_to_quark(quark)));
}

void syd_add_to_parse_tree(STATE, OBJECT ary,
                              NODE * n,
                              int newlines,
                              ID * locals,
                              int line_numbers) {
  NODE * volatile node = n;
  NODE * volatile contnode = NULL;
  VALUE old_ary = Qnil;
  VALUE current;
  VALUE node_name;
  
  /* This is a dirty hack. This indicates if we're currently processing
     a real case statement, so when can act properly. */
  static int in_case = 0;

  if (!node) return;

again:

  if (node) {
    node_name = SYMBOL(get_node_type_string(nd_type(node)));
    /*
    if (RTEST(ruby_debug)) {
      fprintf(stderr, "%15s: %s%s%s\n",
        get_node_type_string(nd_type(node)),
        (RNODE(node)->u1.node != NULL ? "u1 " : "   "),
        (RNODE(node)->u2.node != NULL ? "u2 " : "   "),
        (RNODE(node)->u3.node != NULL ? "u3 " : "   "));
    }
    */
  } else {
    node_name = SYMBOL("ICKY");
  }

  current = array_new(state, 4);
  array_push(ary, current);
  array_push(current, node_name);

again_no_block:

    switch (nd_type(node)) {

    case NODE_BLOCK:
      if (contnode) {
        add_to_parse_tree(current, node, newlines, locals, line_numbers);
        break;
      }

      contnode = node->nd_next;

      /* NOTE: this will break the moment there is a block w/in a block */
      old_ary = ary;
      ary = current;
      node = node->nd_head;
      goto again;
      break;

    case NODE_FBODY:
    case NODE_DEFINED:
      add_to_parse_tree(current, node->nd_head, newlines, locals, line_numbers);
      break;

    case NODE_COLON2:
      add_to_parse_tree(current, node->nd_head, newlines, locals, line_numbers);
      array_push(current, Q2SYM(node->nd_mid));
      break;

    case NODE_MATCH2:
    case NODE_MATCH3:
      add_to_parse_tree(current, node->nd_recv, newlines, locals, line_numbers);
      add_to_parse_tree(current, node->nd_value, newlines, locals, line_numbers);
      break;

    case NODE_BEGIN:
    case NODE_OPT_N:
    case NODE_NOT:
      add_to_parse_tree(current, node->nd_body, newlines, locals, line_numbers);
      break;

    case NODE_IF:
      add_to_parse_tree(current, node->nd_cond, newlines, locals, line_numbers);
      if (node->nd_body) {
        add_to_parse_tree(current, node->nd_body, newlines, locals, line_numbers);
      } else {
        array_push(current, Qnil);
      }
      /* HACK: emit newline nodes to govern a nd_else if it's another if.
       * the parser seems to not emit newlines properly at all. */
      if (node->nd_else) {
        if(newlines && nd_type(node->nd_else) == NODE_IF) {
          OBJECT nl;
          nl = array_new(state, 4);
          array_push(current, nl);
          array_push(nl, SYM("newline"));
          array_push(nl, I2N(nd_line(node->nd_else)));
          array_push(nl, string_new(state, node->nd_else->nd_file));
          
          add_to_parse_tree(nl, node->nd_else, newlines, locals, line_numbers);
        } else {
          add_to_parse_tree(current, node->nd_else, newlines, locals, line_numbers);
        }
      } else {
        array_push(current, Qnil);
      }
      break;

  case NODE_CASE:
    {
      VALUE tmp, t2;
      int ic = in_case;
      in_case = 1;
      add_to_parse_tree(current, node->nd_head, newlines, locals, line_numbers); /* expr */
      node = node->nd_body;
      tmp = array_new(state, 4);
      array_push(current, tmp);
      while (node) {
        if (nd_type(node) == NODE_NEWLINE) {
          node = node->nd_next;
        }
        
        if (nd_type(node) == NODE_WHEN) {                 /* when */
          t2 = array_new(state, 3);
          array_push(t2, SYMBOL(get_node_type_string(nd_type(node))));
          array_push(tmp, t2);
          
          add_to_parse_tree(t2, node->nd_head, newlines, locals, line_numbers); /* args */
          if (node->nd_body) {
            add_to_parse_tree(t2, node->nd_body, newlines, locals, line_numbers); /* body */
          } else {
            array_push(t2, Qnil);
          }
          
          node = node->nd_next; 
        } else {
          add_to_parse_tree(current, node, newlines, locals, line_numbers);          
          break;                                          /* else */
        }
        if (! node) {
          array_push(current, Qnil);                     /* no else */
        }
      }
      in_case = ic;
      break;
    }
  case NODE_WHEN: {
    VALUE tmp, t2;
    if(in_case) {
      add_to_parse_tree(current, node->nd_head, newlines, locals, line_numbers);
      if(node->nd_body) {
        add_to_parse_tree(current, node->nd_body, newlines, locals, line_numbers);
      } else {
        array_push(current, Qnil);
      }
      break;
    }
    array_set(state, current, 0, cstring_to_symbol(state, "many_if"));
    tmp = array_new(state, 4);
    array_push(current, tmp);
    while(node) {
      if(nd_type(node) == NODE_WHEN) {
        t2 = array_new(state, 4);
        array_push(tmp, t2);
        add_to_parse_tree(t2, node->nd_head, newlines, locals, line_numbers); /* args */
        if (node->nd_body) {
          add_to_parse_tree(t2, node->nd_body, newlines, locals, line_numbers); /* body */
        } else {
          array_push(t2, Qnil);
        }
        node = node->nd_next;
      } else {
        add_to_parse_tree(current, node, newlines, locals, line_numbers);
        break;
      }
    }
    
    if(!node) {
      array_push(current, Qnil);
    }
    break;
  }
  case NODE_WHILE:
  case NODE_UNTIL:
    add_to_parse_tree(current,  node->nd_cond, newlines, locals, line_numbers);
    if(node->nd_body) {
      add_to_parse_tree(current,  node->nd_body, newlines, locals, line_numbers); 
    } else {
      array_push(current, Qnil);
    }
    array_push(current, node->nd_3rd == 0 ? Qfalse : Qtrue);
    break;

  case NODE_BLOCK_PASS:
    add_to_parse_tree(current, node->nd_body, newlines, locals, line_numbers);
    add_to_parse_tree(current, node->nd_iter, newlines, locals, line_numbers);
    break;

  case NODE_ITER:
  case NODE_FOR:
    add_to_parse_tree(current, node->nd_iter, newlines, locals, line_numbers);
    if (node->nd_var != (NODE *)1
        && node->nd_var != (NODE *)2
        && node->nd_var != NULL) {
      add_to_parse_tree(current, node->nd_var, newlines, locals, line_numbers);
    } else {
      if (node->nd_var == NULL) {
        // e.g. proc {}
        array_push(current, Qnil);
      } else {
        // e.g. proc {||}
        array_push(current, I2N(0));
      }
    }
    add_to_parse_tree(current, node->nd_body, newlines, locals, line_numbers);
    break;

  case NODE_BREAK:
  case NODE_NEXT:
    if (node->nd_stts)
      add_to_parse_tree(current, node->nd_stts, newlines, locals, line_numbers);
    break;
  case NODE_YIELD:
    if (node->nd_stts) {
      add_to_parse_tree(current, node->nd_stts, newlines, locals, line_numbers);
    } else {
      array_push(current, Qnil);
    }
    array_push(current, node->u3.value);
    break;

  case NODE_RESCUE:
      add_to_parse_tree(current, node->nd_1st, newlines, locals, line_numbers);
      add_to_parse_tree(current, node->nd_2nd, newlines, locals, line_numbers);
      add_to_parse_tree(current, node->nd_3rd, newlines, locals, line_numbers);
    break;

  /* rescue body:
   * begin stmt rescue exception => var; stmt; [rescue e2 => v2; s2;]* end 
   * stmt rescue stmt
   * a = b rescue c */

  case NODE_RESBODY:
      if(node->nd_3rd) {
          add_to_parse_tree(current, node->nd_3rd, newlines, locals, line_numbers);
      } else {
          array_push(current, Qnil);
      }
      if(node->nd_2nd) {
        add_to_parse_tree(current, node->nd_2nd, newlines, locals, line_numbers);
      } else {
          array_push(current, Qnil);
      }
     if(node->nd_1st) { 
         add_to_parse_tree(current, node->nd_1st, newlines, locals, line_numbers);
     } else {
         array_push(current, Qnil);
     }
    break;
	
  case NODE_ENSURE:
    if(node->nd_head) {
      add_to_parse_tree(current, node->nd_head, newlines, locals, line_numbers);
    } else {
      array_push(current, Qnil);      
    }
    if (node->nd_ensr) {
      add_to_parse_tree(current, node->nd_ensr, newlines, locals, line_numbers);
    } else {
      array_push(current, Qnil);
    }
    break;

  case NODE_AND:
  case NODE_OR:
    add_to_parse_tree(current, node->nd_1st, newlines, locals, line_numbers);
    add_to_parse_tree(current, node->nd_2nd, newlines, locals, line_numbers);
    break;

  case NODE_DOT2:
  case NODE_DOT3:
  case NODE_FLIP2:
  case NODE_FLIP3:
    add_to_parse_tree(current, node->nd_beg, newlines, locals, line_numbers);
    add_to_parse_tree(current, node->nd_end, newlines, locals, line_numbers);
    break;

  case NODE_RETURN:
    if (node->nd_stts)
      add_to_parse_tree(current, node->nd_stts, newlines, locals, line_numbers);
    break;

  case NODE_ARGSCAT:
  case NODE_ARGSPUSH:
    add_to_parse_tree(current, node->nd_head, newlines, locals, line_numbers);
    add_to_parse_tree(current, node->nd_body, newlines, locals, line_numbers);
    break;

  case NODE_CALL:
  case NODE_FCALL:
  case NODE_VCALL:
    if (nd_type(node) != NODE_FCALL)
      add_to_parse_tree(current, node->nd_recv, newlines, locals, line_numbers);
    array_push(current, Q2SYM(node->nd_mid));
    if (node->nd_args || nd_type(node) != NODE_FCALL)
      add_to_parse_tree(current, node->nd_args, newlines, locals, line_numbers);
    break;

  case NODE_SUPER:
    add_to_parse_tree(current, node->nd_args, newlines, locals, line_numbers);
    break;

/*
  case NODE_BMETHOD:
    {
      struct BLOCK *data;
      Data_Get_Struct(node->nd_cval, struct BLOCK, data);
      add_to_parse_tree(current, data->var, newlines, locals, line_numbers);
      add_to_parse_tree(current, data->body, newlines, locals, line_numbers);
      break;
    }
    break;

  case NODE_DMETHOD:
    {
      struct METHOD *data;
      Data_Get_Struct(node->nd_cval, struct METHOD, data);
      array_push(current, Q2SYM(data->id));
      add_to_parse_tree(current, data->body, newlines, locals, line_numbers);
      break;
    }

  case NODE_METHOD:
    fprintf(stderr, "u1 = %p u2 = %p u3 = %p\n", node->nd_1st, node->nd_2nd, node->nd_3rd);
    add_to_parse_tree(current, node->nd_3rd, newlines, locals, line_numbers);
    break;
*/

  case NODE_SCOPE:
    {
      VALUE tbl;
      int i;
      int sz;
      // printf("=> scope %x, %d\n", node->nd_tbl, node->nd_tbl[0]);
      if(node->nd_next) {
        add_to_parse_tree(current, node->nd_next, newlines, node->nd_tbl, line_numbers);
      } else {
        array_push(current, Qnil);
      }
      
      sz = node->nd_tbl[0];
      tbl = array_new(state, sz + 3);
      for(i = 0; i < sz; i++) {
        //printf("Would have called quark_to_symbol(state, %d)", node->nd_tbl[i+3]);
        array_push(tbl, Q2SYM(node->nd_tbl[i + 3]));
      }
      array_push(current, tbl);
    }
    break;

  case NODE_OP_ASGN1:
    add_to_parse_tree(current, node->nd_recv, newlines, locals, line_numbers);
    switch(node->nd_mid) {
      case 0:
        array_push(current, SYMBOL("or"));
        break;
      case 1:
        array_push(current, SYMBOL("and"));
        break;
      default:
        array_push(current, Q2SYM(node->nd_mid));
    }
    //add_to_parse_tree(current, node->nd_args->nd_next, newlines, locals, line_numbers);
    add_to_parse_tree(current, node->nd_args, newlines, locals, line_numbers);
    break;

  case NODE_OP_ASGN2:
    add_to_parse_tree(current, node->nd_recv, newlines, locals, line_numbers);
    array_push(current, Q2SYM(node->nd_next->nd_vid));
    switch(node->nd_next->nd_mid) {
      case 0:
        array_push(current, SYMBOL("or"));
        break;
      case 1:
        array_push(current, SYMBOL("and"));
        break;
      default:
        array_push(current, Q2SYM(node->nd_next->nd_mid));
    }
    
    array_push(current, Q2SYM(node->nd_next->nd_aid));    
    add_to_parse_tree(current, node->nd_value, newlines, locals, line_numbers);
    break;

  case NODE_OP_ASGN_AND:
  case NODE_OP_ASGN_OR:
    add_to_parse_tree(current, node->nd_head, newlines, locals, line_numbers);
    add_to_parse_tree(current, node->nd_value, newlines, locals, line_numbers);
    break;

  case NODE_MASGN:
    add_to_parse_tree(current, node->nd_head, newlines, locals, line_numbers);
    if (node->nd_args) {
      if(node->nd_args != (NODE *)-1) {
        add_to_parse_tree(current, node->nd_args, newlines, locals, line_numbers);
      } else {
        array_push(current, Qtrue);
      }
    } else {
        array_push(current, Qnil);
    }
    if(node->nd_value) {
        add_to_parse_tree(current, node->nd_value, newlines, locals, line_numbers);
    } else {
        array_push(current, Qnil);
    }
    break;

  case NODE_LASGN:
    array_push(current, Q2SYM(node->nd_vid));
    add_to_parse_tree(current, node->nd_value, newlines, locals, line_numbers);
    break;
  case NODE_IASGN:
  case NODE_DASGN:
  case NODE_DASGN_CURR:
  case NODE_CVASGN:
  case NODE_CVDECL:
  case NODE_GASGN:
    array_push(current, Q2SYM(node->nd_vid));
    add_to_parse_tree(current, node->nd_value, newlines, locals, line_numbers);
    break;
  
  case NODE_CDECL:
    if(node->nd_vid == 0) {
        array_push(current, Qnil);
    } else {
        array_push(current, Q2SYM(node->nd_vid));
    }
    
    if(node->nd_value) {
      add_to_parse_tree(current, node->nd_value, newlines, locals, line_numbers);
    } else{
      array_push(current, Qnil);      
    }
    
    if(node->nd_next) {
      add_to_parse_tree(current, node->nd_next, newlines, locals, line_numbers);      
    } else {
      array_push(current, Qnil);
    }
    break;

  case NODE_ALIAS:            /* u1 u2 (alias :blah :blah2) */
  case NODE_VALIAS:           /* u1 u2 (alias $global $global2) */
    array_push(current, Q2SYM(node->u1.id));
    array_push(current, Q2SYM(node->u2.id));
    break;

  case NODE_COLON3:           /* u2    (::OUTER_CONST) */
  case NODE_UNDEF:            /* u2    (undef instvar) */
    array_push(current, Q2SYM(node->u2.id));
    break;

  case NODE_HASH:
    {
      NODE *list;
      
      /* Support for sydneys flag on a Hash which indicates that it was 
         create implicitly from using a hash style syntax in a method call
         but without using {}'s */
      if(node->u2.argc) {
          array_set(state, current, 0, SYMBOL("ihash"));
      }

      list = node->nd_head;
      while (list) {
          add_to_parse_tree(current, list->nd_head, newlines, locals, line_numbers);
          list = list->nd_next;
          if (list == 0) {
              printf("odd number list for Hash");
              abort();
          }
          add_to_parse_tree(current, list->nd_head, newlines, locals, line_numbers);
          list = list->nd_next;
      }
    }
    break;

  case NODE_ARRAY:
      while (node) {
        add_to_parse_tree(current, node->nd_head, newlines, locals, line_numbers);
        node = node->nd_next;
      }
    break;

  case NODE_DSTR:
  case NODE_DXSTR:
  case NODE_DREGX:
  case NODE_DREGX_ONCE:
    {
      NODE *list = node->nd_next;
      //if (nd_type(node) == NODE_DREGX || nd_type(node) == NODE_DREGX_ONCE) {
      //  break;
      //}
      /*
      if(0 && node->u2.id) {
          rb_ary_pop(current);
          array_push(current, SYMBOL("xstr_custom"));
          array_push(current, Q2SYM(node->u2.id));
      }
      */
      /* array_push(current, I2N(node->nd_cnt)); */
      array_push(current, string_newfrombstr(state, node->nd_str));
      while (list) {
	      if (list->nd_head) {
          switch (nd_type(list->nd_head)) {
            case NODE_STR:
              add_to_parse_tree(current, list->nd_head, newlines, locals, line_numbers);
            break;
            case NODE_EVSTR:
              add_to_parse_tree(current, list->nd_head, newlines, locals, line_numbers);
            break;
            default:
              add_to_parse_tree(current, list->nd_head, newlines, locals, line_numbers);
            break;
          }
        }
        list = list->nd_next;
      }

      /* the regex options. */
      switch(nd_type(node)) {
      case NODE_DREGX:
      case NODE_DREGX_ONCE:
        array_push(current, I2N(node->nd_cflag));
      }
    }
    break;

  case NODE_DEFN:
  case NODE_DEFS:
    if (node->nd_defn) {
      if (nd_type(node) == NODE_DEFS)
          add_to_parse_tree(current, node->nd_recv, newlines, locals, line_numbers);
      array_push(current, Q2SYM(node->nd_mid));
      add_to_parse_tree(current, node->nd_defn, newlines, locals, line_numbers);
    }
    break;

  case NODE_CLASS:
  case NODE_MODULE:
    add_to_parse_tree(current, node->nd_cpath, newlines, locals, line_numbers);
    // array_push(current, Q2SYM((ID)node->nd_cpath->nd_mid));
    if (nd_type(node) == NODE_CLASS) {
      if(node->nd_super) {
        add_to_parse_tree(current, node->nd_super, newlines, locals, line_numbers);
      } else {
        array_push(current, Qnil);
      }
    }
    add_to_parse_tree(current, node->nd_body, newlines, locals, line_numbers);
    break;

  case NODE_SCLASS:
    add_to_parse_tree(current, node->nd_recv, newlines, locals, line_numbers);
    add_to_parse_tree(current, node->nd_body, newlines, locals, line_numbers);
    break;

  case NODE_ARGS:
    if (locals && (node->nd_cnt || node->nd_opt || node->nd_rest != -1)) {
      int i;
      NODE *optnode;
      VALUE tmp;
      long arg_count;

      if(locals[0] < node->nd_cnt) {
          printf("Corrupted args detected (count of %ld, local size of %ld)", node->nd_cnt, (long int)locals[0]);
          abort();
      }
      tmp = array_new(state, node->nd_cnt);
      array_push(current, tmp);
      //printf("locals: %x (%d / cnt:%d)\n", locals, locals[0], node->nd_cnt);
      for (i = 0; i < node->nd_cnt; i++) {
        /* regular arg names 
        printf("Pushing %d/%d %d (%s)\n", i, node->nd_cnt, locals[i + 3], 
            print_quark(locals[i + 3]));
        */
        array_set(state, tmp, i, Q2SYM(locals[i + 3]));
      }
      
      tmp = array_new(state, 4);
      array_push(current, tmp);

      optnode = node->nd_opt;
      while (optnode) {
        /* optional arg names */
        array_push(tmp, Q2SYM(locals[i + 3]));
	      i++;
	      optnode = optnode->nd_next;
      }

      arg_count = node->nd_rest;
      if (arg_count > 0) {
        /* *arg name */
        tmp = array_new(state, 4);
        /* Hop over the statics --rue */
        array_push(tmp, Q2SYM(locals[arg_count + 2]));
        array_push(tmp, I2N(arg_count));
        //VALUE sym = rb_str_intern(rb_str_plus(rb_str_new2("*"),
        //        rb_str_new2(rb_id2name(locals[node->nd_rest + 1]))));
        array_push(current, tmp);
      } else if (arg_count == -1) {
        array_push(current, Qnil);
        /* nothing to do in this case, handled above */
      } else if (arg_count == -2) {
        array_push(current, Qnil);
        /* nothing to do in this case, no name == no use */
      } else if (arg_count == 0) {
        /* This happens when you have: def blah(*);end.
         * The compiler still needs to be able to tell this apart
         * from a method with no arguments, so we're storing [true] here.
         */
        tmp = array_new(state, 1);
        array_push(tmp, Qtrue);
        array_push(current, tmp);
      } else {
        printf("Unknown arg_count %ld encountered while processing args.\n", arg_count);
        break;
        // exit(1);
      }

      optnode = node->nd_opt;
      /* block? */
      if (optnode) {
          add_to_parse_tree(current, node->nd_opt, newlines, locals, line_numbers);
      } else {
        array_push(current, Qnil);
      }
    }
    break;
	
  case NODE_LVAR:
    array_push(current, Q2SYM(node->nd_vid));
    array_push(current, I2N(0));
	  // array_push(current, I2N(node->nd_cnt));
	break;
	
  case NODE_DVAR:
  case NODE_IVAR:
  case NODE_CVAR:
  case NODE_GVAR:
  case NODE_CONST:
  case NODE_ATTRSET:
    array_push(current, Q2SYM(node->nd_vid));
    break;
    
  case NODE_FIXNUM:
    array_push(current, I2N(node->nd_cnt));
    break;
    
  case NODE_NUMBER:
    array_set(state, current, 0, SYMBOL("lit"));
    array_push(current, bignum_from_bstring_detect(state, node->nd_str));
	bdestroy(node->nd_str);
    break;
    
  case NODE_HEXNUM:
    array_set(state, current, 0, SYMBOL("lit"));
    array_push(current, bignum_from_bstring(state, node->nd_str, 16));
    bdestroy(node->nd_str);
    break;
  
  case NODE_BINNUM:
    array_set(state, current, 0, SYMBOL("lit"));
    array_push(current, bignum_from_bstring(state, node->nd_str, 2));
    bdestroy(node->nd_str);
    break;
    
  case NODE_OCTNUM:
    array_set(state, current, 0, SYMBOL("lit"));
    array_push(current, bignum_from_bstring(state, node->nd_str, 8));
    bdestroy(node->nd_str);
	break;
    
  case NODE_FLOAT:
    array_set(state, current, 0, SYMBOL("lit"));
    array_push(current, float_from_bstring(state, node->nd_str));
    bdestroy(node->nd_str);
	break;
    
  case NODE_XSTR:             /* u1    (%x{ls}) */
  case NODE_STR:              /* u1 */
    array_push(current, string_newfrombstr(state, node->nd_str));
    bdestroy(node->nd_str);
	break;
  case NODE_REGEX:
  case NODE_MATCH:
    array_push(current, string_newfrombstr(state, node->nd_str));
    array_push(current, I2N(node->nd_cnt));
    bdestroy(node->nd_str);
	break;
  case NODE_LIT:
    array_push(current, Q2SYM((uintptr_t)node->nd_lit));
    break;
  case NODE_NEWLINE:
    ADD_LINE;
  
    if(newlines) {
      array_push(current, I2N(nd_line(node)));
      array_push(current, string_new(state, node->nd_file));
      add_to_parse_tree(current, node->nd_next, newlines, locals, line_numbers);
    } else {
      array_pop(state, ary); 
      node = node->nd_next;
      goto again;
    }
    break;

  case NODE_NTH_REF:          /* u2 u3 ($1) - u3 is local_cnt('~') ignorable? */
    array_push(current, I2N(node->nd_nth));
    break;

  case NODE_BACK_REF:         /* u2 u3 ($& etc) */
    {
    char c = node->nd_nth;
    array_push(current, I2N(c));
    }
    break;

  case NODE_BLOCK_ARG:        /* u1 u3 (def x(&b) */
    array_push(current, Q2SYM(node->u1.id));
    array_push(current, I2N(node->nd_cnt));
    break;

  /* these nodes are empty and do not require extra work: */
  case NODE_RETRY:
  case NODE_FALSE:
  case NODE_NIL:
  case NODE_SELF:
  case NODE_TRUE:
  case NODE_ZARRAY:
  case NODE_ZSUPER:
  case NODE_REDO:
  case NODE_FILE:
    break;

  case NODE_SPLAT:
  case NODE_TO_ARY:
  case NODE_SVALUE:             /* a = b, c */
    add_to_parse_tree(current, node->nd_head, newlines, locals, line_numbers);
    break;

  case NODE_ATTRASGN:           /* literal.meth = y u1 u2 u3 */
    /* node id node */
    if (node->nd_1st == RNODE(1)) {
      array_push(current, Qnil);
      // array_push(current, rb_ary_new3(1, SYMBOL("self")));
      // add_to_parse_tree(current, Qnil, newlines, locals, line_numbers);
    } else {
      add_to_parse_tree(current, node->nd_1st, newlines, locals, line_numbers);
    }
    array_push(current, Q2SYM(node->u2.id));
    add_to_parse_tree(current, node->nd_3rd, newlines, locals, line_numbers);
    break;

  case NODE_DSYM:               /* :"#{foo}" u1 u2 u3 */
    /*
    printf("DSYM: %s", node->nd_str->str);
    printf("DSYM: %s", get_node_type_string(nd_type(node->nd_head)));
    */

    add_to_parse_tree(current, node->nd_3rd, newlines, locals, line_numbers);

    /* FIXME: Oh for the love of kittens and fuzzy stuff, please FIX ME!
     *        This hacks around a problem where the first string section
     *        of a dsym is chopped off because it is being stored in this
     *        node! -rue */

    /* First we generate our very own manual dstr node */
    OBJECT a2   = array_pop(state, current);
    int sz      = N2I(array_get_total(a2));
    OBJECT hack = array_new(state, sz);

    array_append(state, hack, SYMBOL("dstr"));
    array_append(state, hack, string_newfrombstr(state, node->nd_str));
    bdestroy(node->nd_str);

    int i = 1;
    while (i < sz) {
      array_append(state, hack, array_get(state, a2, i++));
    }

    /* Then we cleverly replace the array element with it! */
    array_append(state, current, hack);

    /* End hack */
    break;

  case NODE_EVSTR:
    add_to_parse_tree(current, node->nd_2nd, newlines, locals, line_numbers);
    break;
  case NODE_NEGATE:
    add_to_parse_tree(current, node->nd_head, newlines, locals, line_numbers);
    break;

  case NODE_POSTEXE:            /* END { ... } */
    /* Nothing to do here... we are in an iter block */
    break;

/*
  case NODE_CFUNC:
    array_push(current, INT2FIX(node->nd_cfnc));
    array_push(current, INT2FIX(node->nd_argc));
    break;
*/
  /* Nodes we found but have yet to decypher
     I think these are all runtime only... not positive but... */
  case NODE_MEMO:               /* enum.c zip */
  case NODE_CREF:
  case NODE_IFUNC:
  /* #defines:
     case NODE_LMASK:
     case NODE_LSHIFT: */
  default:
    printf("Unhandled node #%d type '%s'", nd_type(node), get_node_type_string(nd_type(node)));
    if (RNODE(node)->u1.node != NULL) printf("unhandled u1 value");
    if (RNODE(node)->u2.node != NULL) printf("unhandled u2 value");
    if (RNODE(node)->u3.node != NULL) printf("unhandled u3 value");
    if (0) fprintf(stderr, "u1 = %p u2 = %p u3 = %p\n", node->nd_1st, node->nd_2nd, node->nd_3rd);
    array_push(current, I2N(-99));
    array_push(current, I2N(nd_type(node)));
    break;
  }
  
  ADD_LINE;

 /*  finish: */
  if (contnode) {
      node = contnode;
      contnode = NULL;
      current = ary;
      ary = old_ary;
      old_ary = Qnil;
      goto again_no_block;
  }
}
