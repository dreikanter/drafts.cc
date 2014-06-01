title: Ruby Hook Methods List
created: 2014/06/01 13:00:14
tags: ruby

Method-related hooks:

- `method_missing` (BasicObject)
- `method_added` (Module)
- `method_removed` (Module)
- `method_undefined` (Module)
- `singleton_method_added` (BasicObject)
- `singleton_method_removed` (BasicObject)
- `singleton_method_undefined` (BasicObject)

Classes and module hooks:

- `inherited` (Class)
- `append_features` (Module)
- `included` (Class)
- `extend_object` (Module)
- `extended` (Module)
- `initialize_copy` (Kernel)
- `const_missing` (Module)

Marshalling hooks:

- `marshal_dump`
- `marshal_load`

Coercion hooks:

- `coerce`
- `induced_from`
- `to_XXX`
