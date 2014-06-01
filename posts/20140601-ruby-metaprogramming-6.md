title: Ruby Metaprogramming: Some Hook Methods
created: 2014/06/01 12:02:30
tags: ruby, конспекты

Продолжение [конспекта](/2014/05/26/ruby-metaprogramming-1.html) по курсу Дэйва Томаса [Ruby Object Model and Metaprogramming](http://pragprog.com/screencasts/v-dtrubyom/the-ruby-object-model-and-metaprogramming).

---

Оглавление конспекта:

- Episode 1: [Objects and Classes](/2014/05/26/ruby-metaprogramming-1.html)
- Episode 2: [Sharing Behavior](/2014/05/26/ruby-metaprogramming-2.html)
- Episode 3: [Dynamic Code](/2014/05/28/ruby-metaprogramming-3.html)
- Episode 4: [instance_eval and class_eval](/2014/05/28/ruby-metaprogramming-4.html)
- Episode 5: [Nine Examples](/2014/05/28/ruby-metaprogramming-5.html)
- **Episode 6: Some Hook Methods**
- Episode 7: [More Hook Methods](/2014/06/01/ruby-metaprogramming-7.html)

---

Пример того, как работает метод `Module::included`:

~~~ ruby
class Module
  def included(mod)
    puts "#{self} included to #{mod}"
  end
end

class SomeClass
  include Comparable # Outputs "Comparable included to SomeClass"

  def <=>(other)
    puts "Comparing..."
    0
  end
end

s = SomeClass.new
s < 123
~~~

### `inherited`

Срабатывает при наследовании класса:

~~~ ruby
class Parent
	def self.inherited(cls)
	puts "#{self} was inherited by #{cls}"
	end
end

class Child < Parent
end
~~~

Пример: подходит ли почтовый сервис для дрставки заданного товара.

![](http://sh.drafts.cc/6y.jpg)

~~~ ruby
class ShipOptions
  @children = []

  def self.inherited(child)
    @children << child
  end

  def self.for(weight, international)
    @children.select do |child|
      child.can_ship?(weight, international)
    end
  end
end

class MediaMail < ShipOptions
  def self.can_ship?(weight, international)
    !international
  end
end

class PriorityFlatRate < ShipOptions
  def self.can_ship?(weight, international)
    !international && weight < 20
  end
end

puts ShipOptions.for(30, false)
~~~

#### Exercise

Класс `Struct` при инстанциировании создаёт своих наследников (структуры) с заданным набором полей. Нужно написать код, который будет отслеживать создание новых структур.

Можно сделать так:

~~~ ruby
def Struct.inherited(cls)
  @structs ||= []
  @structs << cls
end

def Struct.children
  @structs
end
~~~

Или так:

~~~ ruby
class Struct
  @structs = []

  def self.inherited(cls)
    @structs << cls
  end

  def Struct.children
    @structs
  end
end

Dave = Struct.new(:field1, :field2)
Thomas = Struct.new(:field1, :field2)

p Struct.children # [Dave, Thomas]
~~~

### `const_missing`

Если определён метод `Module::const_missing`, он будет срабатывать при обращениик к любой неопределённой константе. Исключение `NameError` в такой ситуации происходить не будет.

~~~ ruby
class Module
  def const_missing(name)
    puts "Constant #{name} is missing"
  end
end

Hello # Constant Hello is missing
~~~

Метод `const_missing` может возвращать значение, соответствующее неопределённой константе:

~~~ ruby
class Module
  def const_missing(name)
    if name.to_s =~ /^U([a-z\d]{4})$/
      [$1.to_i(16)].pack("U*") # Формируем unicode character
    end
  end
end

puts U0123 # ģ
puts Fred  # nil
~~~

Just in case:

>	A **Ruby constant** is like a variable, except that its value is supposed to remain constant for the duration of the program. The Ruby interpreter does not actually enforce the constancy of constants, but it does issue a warning if a program changes the value of a constant (as shown in this trivial example).

>	Lexically, the names of constants look like the names of local variables, except that they begin with a capital letter. By convention, most constants are written in all uppercase with underscores to separate words, `LIKE_THIS`. Ruby class and module names are also constants, but they are conventionally written using initial capital letters and camel case, `LikeThis`.

>	— Ruby Constants, [rubylearning.com](http://rubylearning.com/satishtalim/ruby_constants.html)

Отлов не всех неопределённых констант, а только тех, котрые соответствют заданному условию:

~~~ ruby
class Module
  original_const_missing = instance_method(:const_missing)

  define_method(:const_missing) do |name|
    if name.to_s =~ /^U([a-z\d]{4})$/i
      [$1.to_i(16)].pack("U*") # Формируем unicode character
    else
      original_const_missing.bind(self).call(name)
    end
  end
end

puts U0123 # ģ
puts Fred  # NameError
~~~

Действие `const_missing` можно локализовать внутри отдельного класса:

~~~ ruby
class Dave
  def self.const_missing(name)
    puts "Constant #{name} is missing"
  end
end

Dave::Fred          # Constant Fred is missing
~~~

---

#### Exercise

Q: Почему в приведённом примере метод `const_missing` определён для `self`, а в случае с модулем, self не упоминался?

A: `const_missing` — метод, определённый в классе `Module`, класс `Class` наследует `Module`, а класс из примера — `Dave` — наследует `Class`:

	Dave << Class << Module << Object << BasicObject

В первых примерах переопределяется непосредственно `Module::const_missing`, поэтому его действие глобально.

![](http://sh.drafts.cc/6z.jpg)

В последнем примере `const_missing` переопределяется в качестве class method класса `Dave`, поэтому срабатывать он будет только локально, когда происходит обращение к неопределённым константам внутри этого класса.

![](http://sh.drafts.cc/70.jpg)

---

В этом примере искусственно вызванный метод `const_missing` говорит нам, что константа `Class` не существует, хотя это и не правда:

~~~ ruby
Module::const_missing("Class")
~~~

Ещё один пример с частичным отловом неопределённых констант и стандартной обработкой всех оставшихся:

~~~ ruby
class Dave
  def self.const_missing(name)
    if name.to_s =~ /^A.*$/
      # Обработка констант с именем, начинающимся на A
      puts "Constant #{name} is missing"
    else
      # Всё остальные имена констант обрабатываются стандартным образом
      super
    end
  end
end

Dave::Ada          # Constant Fred is missing
Dave::Fred         # NameError
~~~

Создание перечислений на лету с помощью метода `const_set` (первый аргумент — имя, второй — значение):

~~~ ruby
class Color
  def self.const_missing(name)
    const_set(name, new) # 'new' создаёт инстанс для current class
  end
end

puts Color::Red        # <Color:...>
puts Color::Orange     # <Color:...>

puts Color::Red == Color::Orange         # false
puts Color::Orange == Color::Orange      #true
~~~

Если нужно две группы констант, можно просто сделать ещё один идентичный класс, но получится повторение кода:

~~~ ruby
class Color
  def self.const_missing(name)
    const_set(name, new)
  end
end

class ThreatLevel
  def self.const_missing(name)
    const_set(name, new)
  end
end
~~~

Улучшенный вариант:

~~~ ruby
class Enum
  def self.new
    Class.new do
      def initialize(name)
        @name = name
      end

      def to_s
        "#{self.class.name}->#{@name}"
      end

      def self.const_missing(name)
        const_set(name, new(name))
      end
    end
  end
end

ThreatLevel = Enum.new
Color = Enum.new

puts ThreatLevel::Orange != Color::Orange        # true
puts ThreatLevel::Orange == ThreatLevel::Orange  # true
~~~

See also: [Ruby hook methods list]().
