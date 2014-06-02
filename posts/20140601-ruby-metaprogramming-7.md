title: Ruby Metaprogramming: More Hook Methods & Why Details Are Important
created: 2014/06/01 12:02:34
tags: ruby, конспекты

Продолжение [конспекта](/2014/05/26/ruby-metaprogramming-1.html) по курсу Дэйва Томаса [Ruby Object Model and Metaprogramming](http://pragprog.com/screencasts/v-dtrubyom/the-ruby-object-model-and-metaprogramming).

---

Оглавление конспекта:

- Episode 1: [Objects and Classes](/2014/05/26/ruby-metaprogramming-1.html)
- Episode 2: [Sharing Behavior](/2014/05/26/ruby-metaprogramming-2.html)
- Episode 3: [Dynamic Code](/2014/05/28/ruby-metaprogramming-3.html)
- Episode 4: [instance_eval and class_eval](/2014/05/28/ruby-metaprogramming-4.html)
- Episode 5: [Nine Examples](/2014/05/28/ruby-metaprogramming-5.html)
- Episode 6: [Some Hook Methods](/2014/06/01/ruby-metaprogramming-6.html)
- **Episode 7: More Hook Methods**

---

### `included`

Метод, который вызывается при инклюде модуля в класс.

~~~ ruby
module Persistable
  def self.included(cls)
    puts "#{self} included into #{cls}!"
  end
end

class Person
  include Persistable # Persistable included into Person!
end
~~~

Более развёрнутый пример из предыдущих эпизодов, иллюстрирующий, как включить class method и instance method из модуля в класс:

~~~ ruby
module Persistable
  module ClassMethods
    def find
      puts "Find class method called"
    end
  end
  def self.included(cls)
    cls.extend ClassMethods
  end

  def save
    puts "Save instance method called"
  end
end

class Person
  include Persistable
end

Person.find       # Find class method called
Person.new.save   # Save instance method called
~~~

### `method_added`

Вызывается при каждом определении метода в классе или модуле.

~~~ ruby
class Dave
  def self.method_added(name)
    puts "Added method #{name}"
  end

  def fred # Added method fred
  end

  def wilma # Added method wilma
  end
end
~~~

### A Tracing Extension

Задача: сделать трейсинг вызываемых методов, со значениями аргументов.

Приведённый ниже вариант вызывает переполнение стека из-за того, что `alias_method` добавляет новый метод в класс `cls`, что приводит к рекурсивносму вызову функции `method_added`. 

~~~ ruby
module TraceCalls
  def self.included(cls)
    def cls.method_added(name)
      original_method = "original #{name}"
      alias_method original_method, name
      define_method(name) do |*args|
        puts "==> Calling #{name} with #{args.inspect}"
         result = send(original_method, *args)
         puts "<== result = #{result}"
         result
      end
    end
  end
end


class Example
  include TraceCalls

  def some_method(arg1, arg2)
    arg1 + arg2
  end
end

ex = Example.new.some_method(5, 6)
~~~

Проблему можно решить, например, так:

~~~ ruby
module TraceCalls
  def self.included(cls)
    def cls.method_added(name)
      return if @_adding_a_method
      @_adding_a_method = true
      original_method = "original #{name}"
      alias_method original_method, name
      define_method(name) do |*args|
        puts "==> Calling #{name} with #{args.inspect}"
         result = send(original_method, *args)
         puts "<== result = #{result}"
         result
      end
    end
    @_adding_a_method = false
  end
end

class Example
  # ...
end

ex = Example.new.some_method(5, 6)
# ==> Calling some_method with [5, 6]
# <== result = 11
~~~

Добавление возможности использовать code blocks:

~~~ ruby
module TraceCalls
  def self.included(cls)
    def cls.method_added(name)
      return if @_adding_a_method
      @_adding_a_method = true
      original_method = "original #{name}"
      alias_method original_method, name
      define_method(name) do |*args, &block| # (1)
        puts "==> Calling #{name} with #{args.inspect}"
        result = send(original_method, *args, &block)
        puts "<== result = #{result}"
        result
      end
      @_adding_a_method = false
    end
  end
end

class Example
  # ...
end

ex = Example.new
ex.method2(99) { 2 }
# ==> Calling method2 with [99]
# <== result = 198
ex.name = "Fred"
# ==> Calling name= with ["Fred"]
# <== result = Fred
~~~

**(1)** — `&block` можно передавать через аргументы в другой блок или лямбду в Ruby 1.9+. Есть альтернативный метод имеплементации той же логики для Ruby 1.8 (он присутствует [в примерах кода](http://pragprog.com/screencasts/v-dtrubyom/source_code) для седьмого эпизода), но очень адский код. Cубъективный вывод состоит в том, что если есть возможность не поддерживать версию Ruby 1.8, не нужно её поддерживать.

Для такого примера трейсинг не сработает, т.к. модуль TraceCalls обрабатывает только добавляемые методы, а не те, которые уже присутствуют в классе:

~~~ ruby
class Time
  include TraceCalls
end

puts Time.now + 3600
~~~

#### Exercise

Нужно сделать трейсинг для вызовов существующих методов класса.

~~~ ruby
module TraceCalls
  def self.included(cls)
    cls.methods(false).each do |method|
      original_method = cls.method(method)
      cls.define_singleton_method(method) do |*args|
        puts "==> Calling [#{method}] with args = #{args.inspect}"
        result = original_method.call(*args)
        puts "<== Method returned [#{result}]"
        result
      end
    end
  end
end

class Time
  include TraceCalls
end

Time.now
# ==> Calling [now] with args = []
# <== Method returned [2014-05-31 23:00:06 +0400]

Time.at(0)
# ==> Calling [at] with args = [0]
# <== Method returned [1970-01-01 03:00:00 +0300]

Time.utc(2000, "jan", 1, 20, 15, 1)
# ==> Calling [utc] with args = [2000, "jan", 1, 20, 15, 1]
# <== Method returned [2000-01-01 20:15:01 UTC]
~~~

Финальная версия кода для отслеживания вызовов и возвращаемых значений для пользовательского кода. Пример расчитан на версию Ruby 1.9+.

~~~ ruby
module TraceCalls
  def self.included(klass)
    suppress_tracing do
      klass.instance_methods(false).each do |existing_method|
        wrap(klass, existing_method)
      end
    end

    def klass.method_added(method)  # note: nested definition
      unless @trace_calls_internal
        @trace_calls_internal = true
        TraceCalls.wrap(self, method)
        @trace_calls_internal = false
      end
    end
  end
     
  def self.suppress_tracing
    Thread.current[:'suppress tracing'] = true # (1) (2)
    yield
  ensure # (3)
    Thread.current[:'suppress tracing'] = false
  end

  def self.ok_to_trace?
    !Thread.current[:'suppress tracing']
  end      

  def self.wrap(klass, method) 
    klass.class_eval do
      name = method.to_s
      original_method = instance_method(name)

      define_method(name) do |*args, &block|
        if TraceCalls.ok_to_trace?
          TraceCalls.suppress_tracing do
          	and_block = block_given? ? " (and a block)" : ""
            puts "==> Calling #{name} with #{args.inspect}#{and_block}"
          end
        end
        result = original_method.bind(self).call(*args, &block)
        if TraceCalls.ok_to_trace?
          puts "<<= returns #{result}"
        end
        result
      end
    end
  end
end

class Array
  include TraceCalls
end       

class Time
  include TraceCalls
end
 
t = Time.now   
puts t
puts t + 3600
puts t <=> Time.now


class Example
  def one(arg)
    puts "One called with #{arg}"
  end
end

ex1 = Example.new
ex1.one("Hello")     # no tracing from this call

class Example
  include TraceCalls

  def two(arg1, arg2)
    arg1 + arg2
  end
end

ex1.one("Goodbye")   # but we see tracing from these two
puts ex1.two(4, 5) 

class String
  include TraceCalls
end

puts "cat" + "dog"
~~~

**(1)** — Способ сохранить значение переменной для треда. подобие глобальной переменной.
**(2)** — Имя этого символа взято в кавычки, чтобы можно было использовать в его имени пробел. Зачем там пробел, Дэйв не объяснил.
**(3)** — Блок, который гарантированно исполняется в случае возникновения исключений в теле функции (начиная с `def`). Как оказалось, в начале функции не обязательно ставить `begin`, а перед её окончанием — ещё один `end`.
