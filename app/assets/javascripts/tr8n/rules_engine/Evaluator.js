/****************************************************************************
 Copyright (c) 2013 Michael Berkovich, tr8nhub.com

 Permission is hereby granted, free of charge, to any person obtaining
 a copy of this software and associated documentation files (the
 "Software"), to deal in the Software without restriction, including
 without limitation the rights to use, copy, modify, merge, publish,
 distribute, sublicense, and/or sell copies of the Software, and to
 permit persons to whom the Software is furnished to do so, subject to
 the following conditions:

 The above copyright notice and this permission notice shall be
 included in all copies or substantial portions of the Software.

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
 MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
 LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
 OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
 WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 ****************************************************************************/

var Evaluator = function(ctx) {
  this.vars = {};
  this.ctx = ctx || {
    'atom':     function(a){ return !(typeof a in {'object':1, 'array':1, 'function':1}); }.bind(this),
    'set':      function(l, r){ this.vars[l] = this.ctx[l] = r; return r; }.bind(this),

    '=':        function(args){ return (args[0] == args[1]); }.bind(this),
    '!=':       function(args){ return (args[0] != args[1]); }.bind(this),
    '<':        function(args){ return (args[0] < args[1]); }.bind(this),
    '>':        function(args){ return (args[0] > args[1]); }.bind(this),
    '+':        function(args){ return (args[0] + args[1]); }.bind(this),
    '-':        function(args){ return (args[0] - args[1]); }.bind(this),
    '*':        function(args){ return (args[0] * args[1]); }.bind(this),
    '/':        function(args){ return (args[0] / args[1]); }.bind(this),
    '!':        function(args){ return (("" + args) == "true" ? false : true); }.bind(this),
    'not':      function(args){ return this.ctx['!'](args); }.bind(this),
    '&&':       function(args){
      for (var index = 0; index < args.length; ++index) {
        if (!this.evaluate(args[index])) return false;
      }
      return true;
    }.bind(this),
    'and':      function(args){ return this.ctx['&&'](args); }.bind(this),
    '||':       function(args){
      for (var index = 0; index < args.length; ++index) {
        if (this.evaluate(args[index])) return true;
      }
      return false;
    }.bind(this),
    'or':      function(args){ return this.ctx['||'](args); }.bind(this),
  };
  return this;
}

Evaluator.prototype = {
  apply: function(fn, args) {
    if (typeof this.ctx[fn] == 'function') {
//            alert("Executing: " + fn + "(" + args + ") = " + this.ctx[fn](args));
      return this.ctx[fn](args);
    }
    return this.ctx[fn];
  },
  evaluate: function(sexpr) {
//        alert("evaluate: " + sexpr);
    if (this.ctx['atom'](sexpr)) {
      return (sexpr in this.ctx ? this.ctx[sexpr] : sexpr);
    }

    var fn = sexpr[0];
    var args = sexpr.slice(1);

    if (["quote", "cdr", "cond", "if", "&&", "||", "and", "or", "true", "false", "let", "count", "all", "any"].indexOf(fn) == -1) {
      args = args.map(function(arg) {
        return this.evaluate(arg);
      }.bind(this));
    }

    return this.apply(fn, args);
  }
}
