title: Ruby Metaprogramming: Dynamic Code
created: 2014/05/28 21:57:29
tags: ruby, конспекты

Продолжение [конспекта](/2014/05/26/ruby-metaprogramming-1.html) по курсу Дэйва Томаса [Ruby Object Model and Metaprogramming](http://pragprog.com/screencasts/v-dtrubyom/the-ruby-object-model-and-metaprogramming).

---

Оглавление конспекта:

- Episode 1: [Objects and Classes](/2014/05/26/ruby-metaprogramming-1.html)
- Episode 2: [Sharing Behavior](/2014/05/26/ruby-metaprogramming-2.html)
- **Episode 3: Dynamic Code**
- Episode 4: [instance_eval and class_eval](/2014/05/28/ruby-metaprogramming-4.html)
- Episode 5: [Nine Examples](/2014/05/28/ruby-metaprogramming-5.html)
- Episode 6: [Some Hook Methods](/2014/06/01/ruby-metaprogramming-6.html)
- Episode 7: [More Hook Methods](/2014/06/01/ruby-metaprogramming-7.html)

---

### Blocks

Это блок:

~~~ ruby
File.open('file.txt') { |f| puts f.read }
~~~

А это — лямбда:

~~~ ruby
l = lambda { |a| a + 1 }
l.call(99) # 100

l = Proc.new { |a| a + 1 }
l.call(99) # 100
~~~

`lambda` — метод модуля `Kernel`, который включён в класс `Object`.

Так можно преобразовать блок в лямбду, т.е. получить объект, репрезентирующий блок кода:

~~~ ruby
def convert(&block)
  block
end

l = convert { |a| a + 1 }
l.call(99) # 100
~~~

Есть ещё deprecated метод `proc`, который в версии Руби 1.8 работает идентично методу `lambda`, а в 1.9 — `Proc.new`. Его не стоит использовать, но вот пример:

~~~ ruby
l = proc { |a| a + 1 }
l.call(99) # 100
~~~

Отличия между блоком и лямбдой:

**[1]** `lambda` проверяет количество аргументов. Если с лябдой нужно использовать переменное количество параметров, можно задать их список как в такой же ситуации для функции:

~~~ ruby
lambda {|a, b, *c| p a, b, c}
l.call(1, 2, 3, 4, 5) # a == 1, b == 2, c == [3, 4, 5]
~~~

**[2]** По-разному работает return:

~~~ ruby
def method
  prc = Proc.new { return } # Этот return заверщит method
  lmb = lambda { return } # Этот return завершит только лямбду
end
~~~

Лямбду можно рассматривать как метод, а `Proc.new` — как inline code.

~~~ ruby
def method
  [1, 2, 3].each do |value|
    return if value > 2 # Завершит метод
  end
end
~~~

Дэйв не упомянул, что ещё есть метод `method`, который возвращает объектное представление для другого метода. Пример из документации:

~~~ ruby
class Demo
  def initialize(n)
    @iv = n
  end
  def hello()
    "Hello, @iv = #{@iv}"
  end
end

k = Demo.new(99)
m = k.method(:hello)
m.call   #=> "Hello, @iv = 99"

l = Demo.new('Fred')
m = l.method("hello")
m.call   #=> "Hello, @iv = Fred"
~~~

### Bindings

Байндинг — это странная штука, позволяющая сохранить контекст исполняемого метода. Работает так:

~~~ ruby
def simple(param)
  lvar = "lvar with value"
  binding
end

b = simple(99) { "block value" }

eval "puts param", b  # Выводит 99
eval "puts lvar", b   # "lvar with value"
eval "puts yield", b  # "block value"

class Simple
  def initialize
    @ivar = "ivar with a value"
  en  
  def simple(param)
    lvar = "lvar with value"
    binding
  end
end

s = Simple.new
b = s.simple(99) { "block value" }

eval "puts param", b  # Выводит 99
eval "puts lvar", b   # "lvar with value"
eval "puts yield", b  # "block value"
eval "puts self", b   # #<Simple:...>
eval "puts @ivar", b  # "ivar with a value"
~~~

(Ума ни приложу, зачем вообще нужная такая сложная конструкция.)

Binding encapsulates:

- self
- local variables
- any associated block
- return stack

~~~ ruby
def n_times(n)
  lambda { |val| n * val }
end

two_times = n_times(2)
puts two_times.call(2)    # 6

puts eval "n", two_times  # 6
~~~

#### Exercise

~~~ ruby
def count_with_increment(start, inc)
  counter = start
  lambda { counter += inc }
end

counter = count_with_increment(10, 3)

puts counter.call   # 10
puts counter.call   # 13
puts counter.call   # 16
~~~

### define_method

Иллюстрация того, как в Ruby работает определение методов:

~~~ ruby
class Example
  def one
    def two
    end
  end
end
ex = Example.new

# Если в этом месте вызвать ex.two, будет NoMethodError,
# но если сначала вызвать ex.one, то произвойдёт definition метода two:

ex.one  # Ok
ex.two  # Ok
~~~

Вариант полезного использования переопределения метода для кэширования результата ресурсоёмкого вычисления:

~~~ ruby
class Example
  def one
    def one  # Переопределение первого метода one!
      @value
    end
    # Здесь происходят трудные вычисления, которые
    # исполняются только при первом вызове метода
    @value = 99
  end
end
~~~

Другой способ сделать то же самое:

~~~ ruby
class Example
  def one
    @value ||= calculate_value
  end
  def calculate_value
    # Heavy calculations
  end
end
~~~

Ещё вариант умного использования определения методов в классе. Enforcing method call sequence:

~~~ ruby
class Example
  def start
    def stop
      # ...
    end
    # ...
  end
end
~~~

Метод stop не будет доступен, пока не выполнен старт. (Довольно стрёмная техника, на самом деле, и метод stop всё равно можно будет вызвать невпопад.)

Новые методы можно определять с помощью eval, но это довольно небезопасный (errorprone) способ, т.к. в эвалюируемую строку может случайно или преднамеренно попасть всякое. Более надёжный способ — метод `define_method`, доступный в классах и модулях.

Например:

~~~ ruby
class Multiplier
  define_method(:times_2) do |value|
    value * 2
  end
end

puts Multiplier.new.times_2(3)  # 6
~~~

Но это вырожденный способ использования `define_method`, т.к. он эквивалентен здесь простому `def`.

~~~ ruby
class Multiplier
  def self.define_multiplier(factor)
    define_method("times_#{factor}") do |value|
      value * factor
    end
  end

  10.times { |i| define_multiplier(i) }
end

m = Multiplier.new
p m.times_2(3)  # 6
p m.times_5(3)  # 15
p m.times_6(3)  # 18

Multiplier.define_multiplier(28)  # Метапрограммирвоне!!1
p m.times_28(3)  # 84
~~~

Создание аксессоров с помощью `define_method`:

~~~ ruby
module Accessor
  def my_attr_accessor(name)
    ivar_name = "@#{name}"

    define_method(name) do
      instance_variable_get(ivar_name)
    end

    define_method("#{name}=") do |val|
      instance_variable_set(ivar_name, val)
    end
  end
end

class Example
  extend Accessor
  my_attr_accessor :var
end

ex = Example.new
ex.var = 99
puts ex.var
~~~

#### Exercise

~~~ ruby
module Accessors
  def def_attr_accessor(name)
    define_method(name) do
      STDERR.puts "Getting value for #{name}"
      instance_variable_get("@#{name}")
    end
    define_method("#{name}=") do |val|
      STDERR.puts "Setting value to #{name}"
      instance_variable_set("@#{name}", val)
    end
  end
end

class Example
  extend Accessors
  def_attr_accessor :hello
end

ex = Example.new
ex.hello = "Hello, Hello!"
p ex.hello
~~~
