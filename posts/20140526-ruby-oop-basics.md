title: Основные средства ООП в Ruby
created: 2014/05/26 13:53:47
tags: конспекты, ruby

Конспект четырёх первых лекций курса [Object-Oriented Design and Refactoring Patterns in Ruby](http://courses.tutsplus.com/courses/object-oriented-design-and-refactoring-patterns-in-ruby), которые я просмотрел с целью освежить в памяти соответствующие умения.

Вводные лекции этого курса содержат краткий пересказ про то, какие в Ruby есть средства для объектно-ориентированного программирования. Оригинальные примеры из лекций находятся [на гитхабе](https://github.com/tutsplus/ruby-refactoring). Примеры из конспекта от них отличаются.

### Наследование

Работает так:

	class Person
	  def initialize first_name, last_name
	    @first_name = first_name
	    @last_name = last_name
	  end

	  def say_hello
	    puts "Hello!"
	  end
	end

	class Builder < Person
	  def initialize first_name, last_name, skills
	    super first_name, last_name
	    @skills = skills
	  end

	  def say_hello
	    super
	    puts "I'm a builder."
	  end
	end

	b = Builder.new('Bob', 'Williams', ['construct', 'deconstruct'])
	b.say_hello

`super` — вызов метода базового класса из перегружающего его метода.

### Инкапсуляция

С помощью `attr_reader` и `attr_writer` можно создавать get и set аксессоры для instance variables. Каждый аксессор — это просто метод для доступа к одноимённой переменной.

	class Person
	  attr_reader :first_name, :last_name

	  # Эквивалентный код:

	  # def first_name
	  #   @first_name
	  # end
	  #
	  # def last_name
	  #   @last_name
	  # end

	  attr_writer :first_name

	  # Эквивалентный код:

	  # def first_name=(value)
	  #   @first_name = value
	  # end

	  def initialize first_name, last_name
	    @first_name = first_name
	    @last_name = last_name
	  end
	end

По-умолчанию все instance variables в Ruby определяются как private (в терминах C++/C#/Java — protected), а методы — как public. При необходимости методы можно явно определять и как private:

	class Person
	  def initialize first_name, last_name
	    @first_name = first_name
	    @last_name = last_name
	  end

	  def full_name
	    "#{first_name} #{last_name}"
	  end

	  private

	  def first_name
	    @first_name
	  end

	  def last_name
	    @last_name
	  end
	end

	class AnonymousAlcoholic < Person
	  def say_hi
	    p "Hello, my name is #{first_name}."
	  end
	end

	john = AnonymousAlcoholic.new "John", "Smith"
	john.say_hi        # "Hello, my name is John."
	p john.full_name   # "John Smith"
	p john.first_name  # NoMethodError

### Полиморфизм

Внутри метода `full_name` используются аксессоры, а не прямое обращение к instance variables. Это унифицирует доступ к данным объекта и улучшает контролируемость доступа на тот случай, если класс будет наследоваться, и в наследнике понадобится оверрайдить доступ к данным.

Например:

	class AnonymousAlcoholic < Person
	  def say_hi
	    p "Hello, my name is #{first_name}."
	  end

	  def first_name
	    "Rupert" # Джон хочет сохранить инкогнито
	  end
	end

	john = AnonymousAlcoholic.new "John", "Smith"
	john.say_hi        # "Hello, my name is Rupert."
	p john.full_name   # "Rupert Smith"
	p john.first_name  # "Rupert"

Этот пример заодно иллюстрирует ещё и то, что уровень доступа к методам можно оверрайдить. В данном случае `first_name` переопределён как public.

С помощью исключения `NotImplementedError` можно задавать обязательные для имплементирования методы. В следующем примере `Person` — базовая абстракция:

	class Person
		# ...

		def say_hello
		  puts "Hello, my name is #{full_name}"
		end

		def full_name
		  raise NotImplementedError, 'Must be implemented by subtypes.'
		end
	end

### Duck typing

Пример, демонстрирующий, что наличие конкретных методов у объекта превалирует над его классовой принадлежностью:

	class Person
	  def initialize first_name, last_name
	    @first_name = first_name
	    @last_name = last_name
	  end

	  def say_hello
	    puts "Hello, my name is #{@first_name}"
	  end
	end

	class Cat
	  def initialize hungry=true
	    @hungry = hungry
	  end

	  def say_hello
	    puts @hungry ? "MEOW!" : "Purr-purr-purr"
	  end
	end

	class Brick
	  def say_hello
	    puts ''
	  end
	end

	objects = [
	  Person.new("John", "Smith"),
	  Cat.new(false),
	  Brick.new
	]

	objects.each { |item| item.say_hello } # Работает!
