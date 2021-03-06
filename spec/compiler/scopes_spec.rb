require File.dirname(__FILE__) + "/spec_helper"

describe Compiler do
  it "compiles a defn with no args" do
    x = [:defn, :a, [:scope, [:block, [:args],
           [:fixnum, 12]], []]]
           
    gen x do |g|
      meth = description do |d|
        d.check_argcount 0, 0
        d.push 12
        d.sret
      end
      
      g.push_literal meth
      g.add_method :a
    end
  end
  
  it "compiles 'def add(a,b); a + b; end'" do
    x = [:defn, :add, 
          [:scope, 
            [:block, 
              [:args, [:a, :b], [], nil, nil], 
              [:call, [:lvar, :a, 0], :+, [:array, [:lvar, :b, 0]]]
            ], 
            [:a, :b]
          ]
        ]
    
    gen x do |g|
      meth = description do |d|
        d.check_argcount 2, 2
        d.set_local_from_fp 0, 0
        d.set_local_from_fp 1, 1
        d.push_local 1
        d.push_local 0
        d.meta_send_op_plus
        d.sret
      end
      
      g.push_literal meth
      g.add_method :add
    end
  end
  
  it "compiles 'def add(a,b=2); a + b; end'" do
    x = [:defn, :add, 
          [:scope, 
            [:block, 
              [:args, [:a], [:b], nil, 
                [:block, [:lasgn, :b, [:lit, 2]]]], 
              [:call, [:lvar, :a, 0], :+, [:array, [:lvar, :b, 0]]]
            ], 
            [:a, :b]
          ]
        ]
    
    gen x do |g|
      meth = description do |d|
        d.check_argcount 1, 2
        d.set_local_from_fp 1, 0
        up = d.new_label
        dn = d.new_label
        d.passed_arg 1
        d.git up
        d.push 2
        d.set_local 0
        d.pop
        d.goto dn
        
        up.set!
        d.set_local_from_fp 0, 1
        dn.set!
        
        d.push_local 0
        d.push_local 1
        d.meta_send_op_plus
        d.sret
      end
      
      g.push_literal meth
      g.add_method :add
    end
  end
  
  it "compiles 'def add(a); [].each { |b| a + b }; end'" do
    x = [:defn, :add, 
          [:scope, 
            [:block, 
              [:args, [:a], [], nil, nil],
              [:iter, [:call, [:zarray], :each], 
                [:lasgn, :b], 
                [:block, [:dasgn_curr, :b], 
                  [:call, [:lvar, :a, 0], :+, [:array, [:lvar, :b, 0]]]
                ]
              ]
            ], 
            [:a, :b]
          ]
        ]
    
    gen x do |g|
      meth = description do |d|
        d.check_argcount 1, 1
        d.set_local_from_fp 0, 0

        iter = description do |i|
          i.cast_for_single_block_arg
          i.set_local_depth 0, 0
          i.pop
          i.push_modifiers
          i.new_label.set! # redo
          
          i.push_local_depth 0, 0
          i.push_local 0
          i.meta_send_op_plus
          i.pop_modifiers
          i.soft_return
        end

        d.push_literal iter
        d.create_block2
        d.make_array 0
        d.passed_block(1) do
          d.send_with_block :each, 0, false
        end
        d.sret
      end
      
      g.push_literal meth
      g.add_method :add
    end
  end
  
  it "compiles 'def a(*b); nil; end' with no max argument count" do
    x = [:defn, :a, 
      [:scope, 
        [:block, [:args, [], [], [:b, 1], nil], 
          [:lvar, :b, 0]
        ], 
        [:b]
      ]
    ]
    
    gen x do |g|
      meth = description do |d|
        d.check_argcount 0, -1
        d.make_rest_fp 0
        d.set_local 0
        d.pop
        d.push_local 0
        d.sret
      end
      
      g.push_literal meth
      g.add_method :a
    end
  end
  
  it "compiles 'def a(&b); b; end'" do
    x = [:defn, :a, 
      [:scope, 
        [:block, [:args], [:block_arg, :b, 0], [:lvar, :b, 0]], 
        [:b]
      ]
    ]
    
    gen x do |g|
      meth = description do |d|
        d.check_argcount 0, 0
        d.push_block
        d.dup
        d.is_nil

        after = d.new_label
        d.git after

        d.push_const :Proc
        d.send :__from_block__, 1

        after.set!
        d.set_local 0
        d.pop
        d.push_local 0
        d.sret
      end
      
      g.push_literal meth
      g.add_method :a
    end
  end
  
  it "compiles a defs" do
    x = [:defs, [:vcall, :a], :go, [:scope, [:block, [:args], 
          [:fixnum, 12]], []]]
          
    gen x do |g|
      meth = description do |d|
        d.check_argcount 0, 0
        d.push 12
        d.sret
      end
      
      g.push_literal meth
      g.push_literal :go
      g.push :self
      g.send :a, 0, true
      g.send :metaclass, 0
      g.send :attach_method, 2
    end
  end

  it "compiles 'lambda { def a(x); x; end }'" do
    x = [:iter, [:fcall, :lambda], nil,
          [:defn, :a,
            [:scope,
              [:block, [:args, [:x], [], nil, nil], [:lvar, :x, 0]],
              [:x]
            ]
          ]
        ]
    gen x do |g|
      lam = description do |l|
        meth = description do |m|
          m.check_argcount 1, 1
          m.set_local_from_fp 0, 0
          m.push_local 0
          m.sret
        end

        l.pop
        l.push_modifiers
        l.new_label.set!
        l.push_literal meth
        l.add_method :a
        l.pop_modifiers
        l.soft_return
      end

      g.push_literal lam
      g.create_block2
      g.push :self
      g.passed_block do
        g.send_with_block :lambda, 0, true
      end
    end
  end
  
  it "compiles 'class << x; 12; end'" do
    x = [:sclass, [:vcall, :x], [:scope, [:lit, 12], []]]
    
    gen x do |g|
      meth = description do |d|
        d.push :self
        d.push_self_or_class
        d.set_encloser
        d.push 12
        d.sret
      end
      
      g.push :self
      g.send :x, 0, true
      g.dup
      g.send :__verify_metaclass__, 0
      g.pop
      g.open_metaclass
      g.dup
      g.push_literal meth
      g.swap
      g.attach_method :__metaclass_init__
      g.pop
      g.send :__metaclass_init__, 0
      g.push_encloser
    end
  end
  
  it "compiles a class with no superclass" do
    x = [:class, [:colon2, :A], nil, [:scope, [:lit, 12], []]]
    
    gen x do |g|
      desc = description do |d|
        d.push :self
        d.push_self_or_class
        d.set_encloser
        d.push 12
        d.sret
      end
      
      g.push :nil
      g.open_class :A
      g.dup
      g.push_literal desc
      g.swap
      g.attach_method :__class_init__
      g.pop
      g.send :__class_init__, 0
      g.push_encloser
    end
  end
  
  it "compiles a class declared at a path" do
    x = [:class, [:colon2, [:const, :B], :A], nil, [:scope, [:lit, 12], []]]
    
    gen x do |g|
      desc = description do |d|
        d.push :self
        d.push_self_or_class
        d.set_encloser
        d.push 12
        d.sret
      end
      
      g.push_const :B
      g.push :nil
      g.open_class_under :A
      g.dup
      g.push_literal desc
      g.swap
      g.attach_method :__class_init__
      g.pop
      g.send :__class_init__, 0
      g.push_encloser
    end
  end
  
  it "compiles a class with superclass" do
    x = [:class, [:colon2, :A], [:const, :B], [:scope, [:lit, 12], []]]
    
    gen x do |g|
      desc = description do |d|
        d.push :self
        d.push_self_or_class
        d.set_encloser
        d.push 12
        d.sret
      end
      
      g.push_const :B
      g.open_class :A
      g.dup
      g.push_literal desc
      g.swap
      g.attach_method :__class_init__
      g.pop
      g.send :__class_init__, 0
      g.push_encloser
    end
  end
  
  it "compiles a class with space allocated for locals" do
    x = [:class, [:colon2, :A], nil,
          [:scope, [:block, [:lasgn, :a, [:fixnum, 1]]], []]]
          
    gen x do |g|
      desc = description do |d|
        d.push :self
        d.push_self_or_class
        d.set_encloser
        d.push 1
        d.set_local 0
        d.sret
      end
      
      g.push :nil
      g.open_class :A
      g.dup
      g.push_literal desc
      g.swap
      g.attach_method :__class_init__
      g.pop
      g.send :__class_init__, 0
      g.push_encloser
      
    end
  end

  it "compiles a normal module" do
    x = [:module, [:colon2, :A], [:scope, [:lit, 12], []]]

    gen x do |g|
      desc = description do |d|
        d.push :self
        d.push_self_or_class
        d.set_encloser
        d.push 12
        d.sret
      end

      g.open_module :A
      g.dup
      g.push_literal desc
      g.swap
      g.attach_method :__module_init__
      g.pop
      g.send :__module_init__, 0
      g.push_encloser
    end
  end

  it "compiles a module declared at a path" do
    x = [:module, [:colon2, [:const, :B], :A], [:scope, [:lit, 12], []]]

    gen x do |g|
      desc = description do |d|
        d.push :self
        d.push_self_or_class
        d.set_encloser
        d.push 12
        d.sret
      end

      g.push_const :B
      g.open_module_under :A
      g.dup
      g.push_literal desc
      g.swap
      g.attach_method :__module_init__
      g.pop
      g.send :__module_init__, 0
      g.push_encloser
    end
  end
end
