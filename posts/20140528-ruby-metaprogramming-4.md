title: Ruby Metaprogramming: instance_eval and class_eval
created: 2014/05/28 22:32:04
tags: ruby, конспекты

Продолжение [конспекта](/2014/05/26/ruby-metaprogramming-1.html) по курсу Дэйва Томаса [Ruby Object Model and Metaprogramming](http://pragprog.com/screencasts/v-dtrubyom/the-ruby-object-model-and-metaprogramming).

---

Оглавление конспекта:

- Episode 1: [Objects and Classes](/2014/05/26/ruby-metaprogramming-1.html)
- Episode 2: [Sharing Behavior](/2014/05/26/ruby-metaprogramming-2.html)
- Episode 3: [Dynamic Code](/2014/05/28/ruby-metaprogramming-3.html)
- **Episode 4: instance_eval and class_eval**
- Episode 5: [Nine Examples](/2014/05/28/ruby-metaprogramming-5.html)
- Episode 6: [Some Hook Methods](/2014/06/01/ruby-metaprogramming-6.html)
- Episode 7: [More Hook Methods](/2014/06/01/ruby-metaprogramming-7.html)

---

Пример использования `eval`:

~~~ ruby
method = "puts"
eval = "#{method} 'Hello!'"
~~~

Вместо eval лучше использовать `define_method`, `Class.new`, `instande_method_get/set`, т.к. в общем случае они более безопасны и предсказуемы. Но есть ещё два метода — `instance_eval` и `class_eval` (это методы класса `Object`).

### instance_eval

`instance_eval` исполняет блок кода, приняв за `self` заданный объект:

~~~ ruby
instance_eval do   # self в данном случае равен self
  puts self      # Выводит main (top level)
end

"cat".instance_eval do    # Здесь self — объект String
  puts self # Выводит cat, ы соответствии с объектом-ресивером
end

"cat".instance_eval do
  puts upcase # Выводит CAT
end
~~~

А вот так легко и просто можно вынуть из объекта значение instance variable, к которой нет аксессоров:

~~~ ruby
class Thing
  def initialize
    @secret = 123
  end

  private

  def do_private_stuff
  	puts 'Wooo!'
  end
end

t = Thing.new
puts t.instance_eval { @secret }       # 123
t.instance_eval { do_private_stuff }   # Wooo!
~~~

С помощью `instance_eval` можно определять методы для объекта:

~~~ ruby
cat = "cat"

cat.instance_eval do
  def say_hello
    puts "Meow!"
  end
end

cat.say_hello   # Meow!
~~~

Это singleton method, такой же, как в одном из первых примеров.


### class_eval

У метода `class_eval` есть алиас `module_eval`. Никакой разницы между ними нет.

~~~ ruby
String.class_eval do
  puts self   # String
end

String.class_eval do
  def with_cat
    "Kitty says #{self}"
  end
end

puts "Meow!".with_cat   # Kitty says Meow!
~~~

Очень круто.

`instance_eval` определяют class methods, а `class_eval` — instance methods.

Итак,

- `instance_eval` может быть вызван для любого объекта. С его помощью можно создавать singletom methods. В часном случае, когда вызов instance_eval выполняется для объекта-класса, получатся class methods.
- `class_eval` можно использовать только для класса или модуля (и он создаёт там instance method).

Проще запомнить с помощтю картинки:

![](http://sh.drafts.cc/6v.jpg)

A tricky case:

~~~ ruby
class Thing
  def hello
    puts 'Hello'
  end
end

class AnotherThing
  def do_the_thing(thing)
    thing.instance_eval do
      hello
      do_something_else  # NameError!
    end
  end

  def do_something_else
    puts 'Doing something else'
  end
end

AnotherThing.new.do_the_thing(Thing.new)
~~~

Внутри метода блока eval переопределён `self`, поэтому нельзя вот так просто взять и вызвать другой метод текущего инстанса `AnotherThing`.

Fun things to do with `*_eval`:

1. Violating privacy! (Generally bad idea.)
2. Create methods without using closures.
3. Defining stuff in classes given a class object.
4. DSL in a block.


[2] Creating methods without using closures.

~~~ ruby
module Accessor
  def my_attr_accessor(name)
    class_eval %{
      def #{name}
        @#{name}
      end
      def #{name}=(value)
        @#{name}=value
      end
    }
  end
end

class MyClass
  extend Accessor
  my_attr_accessor :var
end

m = MyClass.new
m.var = 10
p m.var
~~~

Это более лаконичный способ, чем с использованием `instance_variable_get/set`. Использован `class_eval`, т.к. объявляются instance methods.

[3] Defining stuff in classes given a class object. В примере осуществляется добавление нового метода для инстансов нескольких классов. `class_eval` используется для вызова приватного метода `include`.

~~~ ruby
module Hello
  def say_hello
    puts "Hello, I am #{self.class}"
  end
end

[String, Array, Hash].each do |cls|
  cls.class_eval { include Hello }
end

"cat".say_hello
[1, 2].say_hello
{3 => 4}.say_hello
~~~

[4] DSL in a block.

Допустим, есть класс, методы которого предполагается многократно вызывать:

~~~ ruby
class Turtle
  def initialize
    @path = []
  end

  def up(n=1)
    @path << 'u' * n
  end

  def down(n=1)
    @path << 'd' * n
  end

  def left(n=1)
    @path << 'l' * n
  end

  def right(n=1)
    @path << 'r' * n
  end

  def path
    @path.join
  end

  def move(&block)
    instance_eval(&block)
  end
end
~~~

Последовательность вызовов выглядит несколько перегруженной:

~~~ ruby
t = Turtle.new
t.up(2)
t.right
t.down(2)
t.left
puts t.path
~~~

Можно сократить взовы таким образом:

~~~ ruby
t = Turtle.new
t.move do
  up(2)
  right
  down(2)
  left
end
puts t.path
~~~

Но этот подход несёт в себе неявную опасность из-за того, что переопределение `self` внутри блока может привести к непонятным ошибкам.
