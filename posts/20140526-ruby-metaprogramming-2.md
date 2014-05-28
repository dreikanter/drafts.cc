title: Ruby Object Model and Metaprogramming: Sharing Behavior
created: 2014/05/26 23:05:15
tags: ruby, конспекты

Продолжение [конспекта](/2014/05/26/ruby-metaprogramming-1.html) по курсу Дэйва Томаса.

---

Оглавление конспекта:

- Episode 1: [Objects and Classes](/2014/05/26/ruby-metaprogramming-1.html)
- **Episode 2: Sharing Behavior**
- Episode 3: [Dynamic Code](/2014/05/28/ruby-metaprogramming-3.html)
- Episode 4: [instance_eval and class_eval](/2014/05/28/ruby-metaprogramming-4.html)
- Episode 5: [Nine Examples](/2014/05/28/ruby-metaprogramming-5.html)
- Episode 6: Some Hook Methods
- Episode 7: More Hook Methods

---

### Prototype-based development

Пример добавления нового метода (`meow`) к инстансу класса `String`.

~~~ ruby
animal = 'cat'
def animal.speak
	puts 'meow!'
end
animal.speak
~~~

Метод `clone`:

~~~ ruby
other = animal.clone
other.speak
~~~

В этом состоит разница между `clone` и `dup`. `dup` не копирует singleton methods.

~~~ ruby
animal = Object.new

def animal.feet_num=(value)
	@feet_num = value
end

def animal.feet_num
	@feet_num
end

animal.feet_num = 4
p animal.feet_num # got 4

cat = animal.clone
cat.feet_num = 4
p cat.feet_num # got 4

felix = animal.clone
p felix.feet.num # also got 4
~~~

Пример prototype based кода, иллюстрирующий, как можно расширять объекты и клонировать их вместе с singleton methods и state.

~~~ ruby
Animal = Object.new

def Animal.with_feet(number)
	new_animal = clone # Clone thyself
	new_animal.feet_num = number
	new_animal
end

Cat = Animal.with_feet(4)
felix = Cat.clone
puts felix.feet_num
~~~

В «прототипном» коде нет жёсткого разделения между объектами и класами, что обеспечивает большую гибкость по сравнению с class based кодом. Этот подход может быть нежелательно применять для программирования чего-то большого, т.к. за гибкость придётся платить читаемостью кода, но стоит помнить, что есть такая техника.

### Inheritance

Наследование нужно использовать, когда наследуемый класс — действительно разновидность дазового класса, а не просто класс, в который нужно засунуть похожую функциональность.

~~~ ruby
require 'redcloth'

class Formatter
	def initialize(text)
		@text = text
	end

	def to_html # Kind'a interface
		fail 'neet to define to_html in subclasses'
	end
end

class MarkdownFormatter < Formatter
	def to_html
		RedCloth.new(@text).to_html
	end
end

t = MarkdownFormatter.new('Hello, **world!**')
~~~

Другой способ добавления метода в существующий объект (то же, что `def animal.speak`):

~~~ ruby
animal = 'cat'
p defined? animal

class << animal
	def speak
		p 'meow!'
	end
end

animal.speak
~~~

Вот так можно избежать написания `def self.` перед определением каждого class method:

~~~ ruby
class Dave
	class << self
		def say_hello # class method definition
			p 'Hello!'
		end
	end
end
~~~

Но это плохая практика, т.к. too implicit. Лучше так:

~~~ ruby
class Dave
	def self.say_hello
		p 'Hello!'
	end
end
~~~

Аксессоры для class variables (переменных, которые доступны только из class methods). Обычный нудный способ:

~~~ ruby
class Dave
	@count = 0

	def self.count
		@count
	end

	def self.count=(value)
		@count = value
	end
end
~~~

Более лаконичный способ (putting singleton class into the ghost class):

~~~ ruby
class Dave
	@count = 0

	class << self
		attr_accessor :count
	end

	def initialize
		Dave.count += 1
	end
end

p "There are #{Dave.count} Daves created" # "There are 0 Daves created"
d1 = Dave.new
d2 = Dave.new
p "There are #{Dave.count} Daves created" # "There are 2 Daves created"
~~~

### Modules

Использование модулей в качестве неймспейсов:

~~~ ruby
module Math
  ALMOST_PI = 22.0/7 # Module constant

  def self.is_even?(num) # Module method
    (num & 1) == 0
  end

  class Calculator # Module class

  end
end

p Math::ALMOST_PI
p Math::Calculator.new

p Math.is_even?(1)
p Math.is_even?(2)
~~~

Такой module method можно использовать только включив в класс:

~~~ ruby
module Logger
  def log(msg)
    STDERR.puts msg
  end
end

class Truck
  include Logger
end

a_truck = Truck.new
a_truck.log 'Hello!' # "Hello!"

Truck.log 'Hello!' # NoMethodError
~~~

Но если сделать так, метод из модуля `Logger` будет заменён на новый:

~~~ ruby
module Logger
  def log(msg)
    STDERR.puts msg
  end
end

class Truck
  include Logger
end

module Logger
  def log(msg)
    STDERR.puts "go away"
  end
end

a_truck = Truck.new
a_truck.log 'Hello!' # "go away"
~~~

Помимо метода `include`, есть ещё `extend`:

~~~ ruby
module Logger
  def log(msg)
    STDERR.puts msg
  end
end

animal = "cat"
animal.extend Logger
animal.log "Greetings from the cat!"
~~~
  
Это то же, что

~~~ ruby
class << animal
	include Logger
end
~~~

Метод `Logger` становится доступен внутри `animal`, как instance method.

Таким образом можно добавить в определение класса class method из модуля (для вызова этого метода достаточно указать имя класса, а инстанциировать сущность, как при использовании `include`, — не нужно):

~~~ ruby
module Logger
  def log(msg)
    STDERR.puts msg
  end
end

class Truck
  extend Logger
end

Truck.log 'Hello from the Truck!' # Prints a string
Truck.new.log 'Hello from the Truck!' # raises NoMethodError
~~~

Если часть методов модуля нужно включить в класс в качестве class methods, а часть — как instance methods, делать надо так (пример иллюстрирует, как можно добавить функциональность `ActiveRecord` в класс):

~~~ ruby
module Persistable
  # Этот метод юужет автоматически вызван после инклюда модуля в класс
  def self.included(cls)
    cls.extend ClassMethods
  end
  
  module ClassMethods
    # Возвращает новый ("найденный") инстанс класса
    def find
      puts 'In find'
      new
    end
  end

  def save
    p 'In save'
  end
end

class Person
  include Persistable

  # ...
end
~~~

Теперь в теле класса `Person` не нужно делать `extend Persistable::ClassMethods`, т.к. метод `Persistable.included` будет автоматически вызван в момент выполнения `include Persistable`, и всё сделает сам.
