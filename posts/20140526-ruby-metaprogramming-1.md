title: Ruby Object Model and Metaprogramming: Objects and Classes
created: 2014/05/26 22:38:21
tags: ruby, конспекты

Этот пост — первая часть конспекта по курсу Дэйва Томаса [The Ruby Object Model and Metaprogramming](http://pragprog.com/screencasts/v-dtrubyom/the-ruby-object-model-and-metaprogramming), который я сейчас слушаю. Конспект получается довольно большой, — в текстовом файле с заметками и примерами кода накопилось больше 800 строк, а это только половина материала. Поэтому буду выкладывать его фрагментами, по одному эпизоду на пост.

Дисклаймер:

1. На момент первой публикаци, текст довольно сырой (потому что см. название сайта). Если вы заметили опечатку или неверную формулировку, буду благодарен за [пуллреквест](https://github.com/dreikanter/drafts.cc/tree/master/posts) с исправлением. Ну или мне можно просто написать об этом в почту (alex.musayev на gmail).
2. Конспект не является текстовым представлением курса, и даже не претендует на полноту. Я записывал только то, что считал субъективно-важным. Кроме того, мои примеры кода местами отличаются от кода Дэйва.
3. Spoiler alert: в конспекте содержатся решения задач, которые иногда встречаются в курсе.

---

Оглавление конспекта:

- **Episode 1: Objects and Classes**
- Episode 2: [Sharing Behavior](/2014/05/26/ruby-metaprogramming-2.html)
- Episode 3: [Dynamic Code](/2014/05/28/ruby-metaprogramming-3.html)
- Episode 4: [instance_eval and class_eval](/2014/05/28/ruby-metaprogramming-4.html)
- Episode 5: [Nine Examples](/2014/05/28/ruby-metaprogramming-5.html)
- Episode 6: Some Hook Methods
- Episode 7: More Hook Methods

---

Object = State + Behavior

Базовый класс в Ruby — BasicClass (вплоть до версии 1.8 был Object).

~~~ ruby
p "String".class 			# String
p String.superclass 		# Object
p Object.superclass 		# BasicObject
p BasicObject.superclass 	# nil
~~~

Т.е. String << Object << BasicObject.

Так можно посмотреть список всех методов:

~~~ ruby
	puts String.methods.sort
~~~

@var — Instance variable (private).

`self` is default receiver for method calls inside the class.

Две ситуации, когд `self` меняется:

- Method call with an explicit receiver
- Class definition (class ... end scope)

Singleton method (of a ghost class aka metaclass) added to String class:

~~~ ruby
puts cat.class # String

def cat.meow # Anonymous ghost class method
  puts 'Meow!'
end

cat.meow
~~~

`defined?` — оператор, который возвращает название любой сущности. Для неопределеённых имён возвращает `nil`. Для классов — "constant" (это примерно то же, что name в Python). 

`self` работает так:

~~~ ruby
puts "Self: #{self}" # Self: main

class Person

  puts "Self: #{self}" # Self: Person

  def initialize(name)
    @name = name
    puts "Self: #{self}" # Self: #<Person:0x2affa68>
  end
end

person = Person.new("Bob")
~~~

В момент определения тело класса исполняется как обычная функция.

~~~ ruby
const = 1
p defined? const # "local-variable"

Const = 1
p defined? Const # "constant"

class SomeClass
end
p defined? SomeClass # "constant"

other_class = Class.new
p defined? other_class # "local-variable"

OtherClass = other_class
p defined? OtherClass # "constant"
~~~

Как происходит поиск метода при его вызове:

![](http://sh.drafts.cc/6w.jpg)

